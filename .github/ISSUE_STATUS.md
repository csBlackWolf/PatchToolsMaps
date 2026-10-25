# Issue status

Each open issue has one status label. Type labels such as `bug` or `enhancement`
remain separate. New issues receive `status: new` automatically. When a maintainer
adds another status, the workflow removes the previous status labels.

| Label | Meaning / Bedeutung |
| --- | --- |
| `status: new` | Waiting for review. / Noch nicht gesichtet. |
| `status: planned` | Accepted for future work; no release date yet. / Für später eingeplant, noch ohne Termin. |
| `status: in progress` | Work has started. / Wird bearbeitet. |
| `status: done` | Completed, or declined with `wontfix`. / Erledigt oder mit `wontfix` abgelehnt. |
| `status: deferred` | Accepted but postponed; not promised for the next release. / Angenommen, aber vorerst zurückgestellt. |

An issue's open/closed state is separate from these labels. Closing an issue does
not automatically mean its idea was implemented. A release milestone can be added
once a specific version is known.

Der Offen-/Geschlossen-Zustand ist unabhängig von diesen Labels. Geschlossen
bedeutet nicht automatisch umgesetzt. Sobald eine konkrete Version feststeht,
kann zusätzlich ein Release-Meilenstein zugewiesen werden.

Shared planning board: [PatchTools development](https://github.com/users/csBlackWolf/projects/9).

Planned means accepted without a release promise. In Progress means active work. Deferred means accepted but postponed. Reviewed and Next release have been removed.

The board is the source of truth. Native Projects workflows add new issues from both repositories. The `Project status, labels and assignees` workflow reads board #9 about every 15 minutes (GitHub may delay scheduled runs) and mirrors its Status into the corresponding issue label. Drag-and-drop changes are therefore not immediate. A maintainer can also use Run workflow in Actions. Labels such as bug and enhancement are preserved. Editing a status label does not move the board card; the next sync restores the board's status.

`Done` maps to `status: done`; `Deferred` maps to `status: deferred`. Archived cards, drafts, unrelated repositories and unknown statuses are skipped. Closing an issue does not by itself prove it shipped.

Authentication: `PROJECT_READ_TOKEN` is a read-only Projects token, stored as an Actions secret in each repository, expiring 2027-01-22. It is used only for reading the shared board. The built-in repository `GITHUB_TOKEN`, restricted to contents:read and issues:write, updates labels only in its own repository. Renew the read token and update both secrets before expiry. Never put its value in source files, logs or screenshots.


## Automatic ownership after reviewing a new issue

The existing board synchronization (about every 15 minutes) assigns an unassigned issue to the human who moves it from **New** to another recognized status on the shared board. Drag-and-drop and changes in the issue's Projects sidebar are supported through the same status-history event.

Existing assignees are preserved. Bot/automated changes, other boards, historical transitions before this automation was enabled and later manual assignment/unassignment are ignored. The person must be assignable in the repository. This is scheduled synchronization, not an instant webhook.

## Declining an issue

Moving an issue directly from **New** to **Done** adds `wontfix` alongside `status: done`.
Moving it back to New, Planned, In Progress or Deferred removes `wontfix` again.
A later completion from Planned or In Progress to Done is not a rejection.
The latest status transition on this board determines the result; missing history
is not treated as rejection. Other issue labels and existing assignees are preserved.
This follows the same scheduled synchronization, so changes can take about 15 minutes.

Direkt **New → Done** bedeutet abgelehnt (`wontfix`). Beim Zurückschieben wird
`wontfix` entfernt. **Planned** sagt nur zu, dass die Idee angenommen wurde;
es ist kein Versprechen für den nächsten Release. Done kann daher erledigte
und abgelehnte Einträge enthalten; das Label macht den Unterschied sichtbar.
