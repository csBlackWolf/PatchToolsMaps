import unittest
from unittest.mock import patch

import sync_project_status as sync


def item(state="Planned", repo="csBlackWolf/PatchTools", archived=False, kind="Issue"):
    return {"isArchived": archived, "fieldValueByName": {"name": state},
            "content": {"__typename": kind, "number": 1,
                        "repository": {"nameWithOwner": repo}}}


def page(nodes, next_page=False):
    return {"data": {"user": {"projectV2": {"items": {"nodes": nodes,
            "pageInfo": {"hasNextPage": next_page, "endCursor": "cursor" if next_page else None}}}}}}


class ProjectStatusTests(unittest.TestCase):
    def test_skip_other_repositories_archived_items_and_drafts(self):
        items = [item(), item(repo="other/repo"), item(archived=True), item(kind="DraftIssue")]
        self.assertEqual(list(sync.desired_items(items, "csBlackWolf/PatchTools")), [(1, "Planned")])

    def test_every_status_preserves_type_labels_and_avoids_noop_writes(self):
        for state, desired in sync.STATUSES.items():
            with self.subTest(state=state):
                calls = []

                def request(path, token, method="GET", data=None):
                    calls.append((path, token, method, data))
                    if "/issues/1/labels?" in path:
                        return [{"name": "enhancement"}, {"name": "status: reviewed"}]
                    return []

                with patch.object(sync, "request", request):
                    sync.sync_issue("csBlackWolf/PatchTools", 1, state, "issue-token")
                self.assertTrue(all(call[1] == "issue-token" for call in calls))
                self.assertFalse(any(call[2] == "DELETE" and "enhancement" in call[0] for call in calls))
                if desired == "status: reviewed":
                    self.assertEqual(len(calls), 1)
                else:
                    self.assertIn(("/repos/csBlackWolf/PatchTools/issues/1/labels", "issue-token", "POST",
                                   {"labels": [desired]}), calls)
                    self.assertTrue(calls[-1][0].endswith("status%3A%20reviewed"))

    def test_paginate_board_before_any_writes(self):
        with patch.object(sync, "request", side_effect=[page([item()], True), page([item("Deferred")])]) as api:
            self.assertEqual(len(sync.read_board("read-token")), 2)
            self.assertTrue(all(call.args[1] == "read-token" for call in api.call_args_list))

    def test_board_access_failure_is_not_an_empty_board(self):
        for result in ({"errors": [{"type": "INSUFFICIENT_SCOPES"}]}, {"data": {"user": None}}):
            with self.subTest(result=result), patch.object(sync, "request", return_value=result):
                with self.assertRaises(RuntimeError):
                    sync.read_board("read-token")


class ClaimTests(unittest.TestCase):
    def board_item(self, **changes):
        event={"__typename":"ProjectV2ItemStatusChangedEvent","createdAt":"2099-01-01T00:00:00Z",
               "previousStatus":"New","status":"Reviewed","wasAutomated":False,
               "actor":{"__typename":"User","login":"reviewer"},
               "project":{"number":9,"owner":{"login":"csBlackWolf"}}}
        event.update(changes)
        result=item("Reviewed")
        result["content"]["timelineItems"]={"nodes":[event]}
        return result

    def test_recent_human_transition_claims_actor(self):
        self.assertEqual(sync.claim_actor(self.board_item()),"reviewer")

    def test_automated_wrong_board_old_and_non_new_transitions_are_ignored(self):
        for changes in ({"wasAutomated":True},{"previousStatus":"Planned"},
                        {"createdAt":"2000-01-01T00:00:00Z"},
                        {"project":{"number":6,"owner":{"login":"csBlackWolf"}}},
                        {"actor":{"__typename":"Bot","login":"github-actions"}}):
            with self.subTest(changes=changes):
                self.assertIsNone(sync.claim_actor(self.board_item(**changes)))
        reset=self.board_item();reset["fieldValueByName"]["name"]="New"
        self.assertIsNone(sync.claim_actor(reset))

    def test_manual_assignment_and_unassignment_after_review_are_respected(self):
        for kind in ("AssignedEvent","UnassignedEvent"):
            data=self.board_item()
            data["content"]["timelineItems"]["nodes"].append({"__typename":kind,"createdAt":"2099-01-02T00:00:00Z"})
            self.assertIsNone(sync.claim_actor(data))

    def test_existing_assignees_are_never_replaced(self):
        with patch.object(sync,"request",return_value={"assignees":[{"login":"owner"}]}) as api:
            sync.sync_assignment("csBlackWolf/PatchTools",1,"reviewer","token")
            self.assertEqual(api.call_count,1)

    def test_assignable_actor_is_added(self):
        with patch.object(sync,"request",side_effect=[{"assignees":[]},None,{"assignees":[{"login":"reviewer"}]}]) as api:
            sync.sync_assignment("csBlackWolf/PatchTools",1,"reviewer","token")
            self.assertEqual(api.call_args.args[2:],("POST",{"assignees":["reviewer"]}))


if __name__ == "__main__":
    unittest.main()
