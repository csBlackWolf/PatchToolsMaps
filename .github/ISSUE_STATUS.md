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

The board currently uses native GitHub Projects workflows for automatic issue intake. Its Status field and issue labels are not automatically synchronized. When changing status, update the label too; build planning must always check the board directly. No additional access token has been created.
