# Issue status

Each open issue has one status label. Type labels such as `bug` or `enhancement`
remain separate. New issues receive `status: new` automatically. When a maintainer
adds another status, the workflow removes the previous status labels.

| Label | Meaning / Bedeutung |
| --- | --- |
| `status: new` | Waiting for review. / Noch nicht gesichtet. |
| `status: reviewed` | Read, without a scheduling promise. / Gelesen, noch nicht eingeplant. |
| `status: planned` | Accepted for future work; no release date yet. / Für später eingeplant, noch ohne Termin. |
| `status: in progress` | Work has started. / Wird bearbeitet. |
| `status: deferred` | Accepted but postponed; not promised for the next release. / Angenommen, aber vorerst zurückgestellt. |
| `status: next release` | Intended for the next release; testing may still change this. / Für den nächsten Release vorgesehen, vorbehaltlich der Tests. |

An issue's open/closed state is separate from these labels. Closing an issue does
not automatically mean its idea was implemented. A release milestone can be added
once a specific version is known.

Der Offen-/Geschlossen-Zustand ist unabhängig von diesen Labels. Geschlossen
bedeutet nicht automatisch umgesetzt. Sobald eine konkrete Version feststeht,
kann zusätzlich ein Release-Meilenstein zugewiesen werden.

Shared planning board: [PatchTools development](https://github.com/users/csBlackWolf/projects/9).

Reviewed means read, not accepted. Planned, in progress and next release are accepted work; deferred work is listed separately.

The board is the source of truth. Native Projects workflows add new issues from both repositories. The `Project status to issue labels` workflow reads board #9 about every 15 minutes (GitHub may delay scheduled runs) and mirrors its Status into the corresponding issue label. Drag-and-drop changes are therefore not immediate. A maintainer can also use Run workflow in Actions. Labels such as bug and enhancement are preserved. Editing a status label does not move the board card; the next sync restores the board's status.

`Done` maps to `status: done`; `Deferred` maps to `status: deferred`. Archived cards, drafts, unrelated repositories and unknown statuses are skipped. Closing an issue does not by itself prove it shipped.

Authentication: `PROJECT_READ_TOKEN` is a read-only Projects token, stored as an Actions secret in each repository, expiring 2027-01-22. It is used only for reading the shared board. The built-in repository `GITHUB_TOKEN`, restricted to contents:read and issues:write, updates labels only in its own repository. Renew the read token and update both secrets before expiry. Never put its value in source files, logs or screenshots.
