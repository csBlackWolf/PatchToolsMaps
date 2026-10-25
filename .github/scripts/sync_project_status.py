"""Mirror the shared Projects board into this repository's issue status labels.

PROJECT_READ_TOKEN only reads Projects. GITHUB_TOKEN only writes local issues.
The board is authoritative; neither issue bodies nor labels are executed as code.
"""
import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request


AUTO_ASSIGN_SINCE = "2026-10-25T03:01:27Z"  # Do not claim historical transitions on rollout.

STATUSES = {
    "New": "status: new",
    "Planned": "status: planned",
    "In Progress": "status: in progress",
    "Deferred": "status: deferred",
    "Done": "status: done",
}
REJECTION_LABEL = "status: wontfix"
LEGACY_LABELS = {"status: reviewed", "status: next release", "wontfix"}
COLORS = {"New": "d4c5f9", "Planned": "fbca04", "In Progress": "1d76db",
          "Deferred": "eeeeee", "Done": "0e8a16"}
QUERY = """query($after: String) {
  user(login: "csBlackWolf") {
    projectV2(number: 9) {
      items(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isArchived
          fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            __typename
            ... on Issue {
              number repository { nameWithOwner }
              timelineItems(last: 100, itemTypes: [PROJECT_V2_ITEM_STATUS_CHANGED_EVENT, ASSIGNED_EVENT, UNASSIGNED_EVENT]) {
                nodes {
                  __typename
                  ... on ProjectV2ItemStatusChangedEvent {
                    createdAt previousStatus status wasAutomated
                    actor { __typename login }
                    project { number owner { ... on User { login } } }
                  }
                  ... on AssignedEvent { createdAt }
                  ... on UnassignedEvent { createdAt }
                }
              }
            }
          }
        }
      }
    }
  }
}"""


def request(path, token, method="GET", data=None):
    url = "https://api.github.com" + path
    req = urllib.request.Request(url, method=method,
        data=json.dumps(data).encode() if data is not None else None,
        headers={"Authorization": "Bearer " + token,
                 "Accept": "application/vnd.github+json",
                 "Content-Type": "application/json",
                 "User-Agent": "PatchTools-project-status"})
    with urllib.request.urlopen(req, timeout=30) as response:
        body = response.read()
        return json.loads(body) if body else None


def read_board(token):
    after = None
    items = []
    while True:
        result = request("/graphql", token, "POST", {"query": QUERY, "variables": {"after": after}})
        if result.get("errors"):
            raise RuntimeError("Cannot read the planning board. Check the Projects read permission.")
        user = (result.get("data") or {}).get("user") or {}
        project = user.get("projectV2")
        if not project:
            raise RuntimeError("Planning board unavailable; no issue labels were changed.")
        page = project["items"]
        items.extend(page["nodes"])
        if not page["pageInfo"]["hasNextPage"]:
            return items
        after = page["pageInfo"]["endCursor"]
        if not after:
            raise RuntimeError("Incomplete board pagination; no issue labels were changed.")


def desired_items(items, repository):
    for item in items:
        content = item.get("content") or {}
        if item.get("isArchived") or content.get("__typename") != "Issue":
            continue
        if content["repository"]["nameWithOwner"] != repository:
            continue
        state = (item.get("fieldValueByName") or {}).get("name")
        if state not in STATUSES:
            print("Skipped issue #" + str(content["number"]) + ": unrecognized or missing board status.")
            continue
        yield content["number"], state


def sync_issue(repository, number, state, token, rejected=False):
    base = "/repos/" + repository
    issue_path = base + "/issues/" + str(number) + "/labels"
    current = set()
    page = 1
    while True:
        labels = request(issue_path + "?per_page=100&page=" + str(page), token)
        current.update(label["name"] for label in labels)
        if len(labels) < 100:
            break
        page += 1
    desired = {REJECTION_LABEL if state == "Done" and rejected else STATUSES[state]}
    for label in sorted(desired - current):
        try:
            request(base + "/labels/" + urllib.parse.quote(label, safe=""), token)
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
            request(base + "/labels", token, "POST",
                    {"name": label, "color": "ffffff" if label == REJECTION_LABEL else COLORS[state],
                     "description": "Declined during triage" if label == REJECTION_LABEL else
                                    "Status from the shared PatchTools planning board"})
        request(issue_path, token, "POST", {"labels": [label]})
    managed = set(STATUSES.values()) | LEGACY_LABELS | {REJECTION_LABEL}
    for previous in sorted(current.intersection(managed) - desired):
        try:
            request(issue_path + "/" + urllib.parse.quote(previous, safe=""), token, "DELETE")
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
    print("Issue #" + str(number) + ": " + ", ".join(sorted(desired)))


def is_rejected(item):
    """Only a direct New -> Done transition on this board means declined.

    Use the latest board transition so reopening/replanning and later completion
    cannot retain a rejection from an earlier triage cycle.
    """
    if (item.get("fieldValueByName") or {}).get("name") != "Done":
        return False
    events = ((item.get("content") or {}).get("timelineItems") or {}).get("nodes") or []
    transitions = []
    for event in events:
        if not event or event.get("__typename") != "ProjectV2ItemStatusChangedEvent":
            continue
        project = event.get("project") or {}
        if project.get("number") == 9 and (project.get("owner") or {}).get("login") == "csBlackWolf":
            transitions.append(event)
    if not transitions:
        return False
    latest = max(transitions, key=lambda event: event.get("createdAt", ""))
    return latest.get("previousStatus") == "New" and latest.get("status") == "Done"


def claim_actor(item, since=AUTO_ASSIGN_SINCE):
    """Claim only recent human New -> non-New transitions on our board.

    Assignment/unassignment after that transition takes precedence, so a
    manual unassignment is not undone by the next scheduled synchronization.
    """
    if (item.get("fieldValueByName") or {}).get("name") not in set(STATUSES) - {"New"}:
        return None
    events = ((item.get("content") or {}).get("timelineItems") or {}).get("nodes") or []
    candidates = []
    for event in events:
        if not event or event.get("__typename") != "ProjectV2ItemStatusChangedEvent":
            continue
        project = event.get("project") or {}
        actor = event.get("actor") or {}
        if (event.get("previousStatus") == "New" and event.get("status") in set(STATUSES) - {"New"}
                and event.get("createdAt", "") >= since and event.get("wasAutomated") is False
                and project.get("number") == 9 and (project.get("owner") or {}).get("login") == "csBlackWolf"
                and actor.get("__typename") == "User"
                and re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}", actor.get("login", ""))):
            candidates.append(event)
    if not candidates:
        return None
    transition = max(candidates, key=lambda event: event["createdAt"])
    if any(event and event.get("__typename") in {"AssignedEvent", "UnassignedEvent"}
           and event.get("createdAt", "") >= transition["createdAt"] for event in events):
        return None
    return transition["actor"]["login"]


def sync_assignment(repository, number, actor, token):
    base = "/repos/" + repository
    path = base + "/issues/" + str(number)
    issue = request(path, token)
    if issue.get("assignees"):
        return
    try:
        request(base + "/assignees/" + urllib.parse.quote(actor, safe=""), token)
    except urllib.error.HTTPError as error:
        if error.code in {403, 404}:
            print("Issue #" + str(number) + ": board actor cannot be assigned; left unchanged.")
            return
        raise
    updated = request(path + "/assignees", token, "POST", {"assignees": [actor]})
    if actor in {user["login"] for user in updated.get("assignees", [])}:
        print("Issue #" + str(number) + ": assigned to " + actor)


def main():
    project_token = os.environ.get("PROJECT_READ_TOKEN")
    issue_token = os.environ.get("GITHUB_TOKEN")
    repository = os.environ.get("GITHUB_REPOSITORY")
    if not project_token or not issue_token:
        raise RuntimeError("Project synchronization requires PROJECT_READ_TOKEN and GITHUB_TOKEN.")
    if repository not in {"csBlackWolf/PatchTools", "csBlackWolf/PatchToolsMaps"}:
        raise RuntimeError("Refusing to change an unexpected repository.")
    items = read_board(project_token)
    claims = {}
    rejections = {}
    for item in items:
        if list(desired_items([item], repository)):
            claims[item["content"]["number"]] = claim_actor(item)
            rejections[item["content"]["number"]] = is_rejected(item)
    for number, state in desired_items(items, repository):
        sync_issue(repository, number, state, issue_token, rejected=rejections[number])
        if claims.get(number):
            sync_assignment(repository, number, claims[number], issue_token)


if __name__ == "__main__":
    main()
