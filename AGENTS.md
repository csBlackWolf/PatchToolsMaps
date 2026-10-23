# Build and release planning

Before every build push or release/tag push:

1. Read the current open GitHub issues for this repository and the shared planning board: https://github.com/users/csBlackWolf/projects/9 . Check both repositories when preparing a joint build. Read live data; do not rely on an old snapshot.
2. Identify accepted/planned ideas: Planned, In Progress and Next release. Reviewed only means read, not accepted. List Deferred items separately. Compare board and labels; flag discrepancies instead of silently assuming they are synchronized.
3. Report the number, titles and links of these ideas to the user, with Next release separately highlighted. State which are included in the proposed build and which are not. If access fails, say so; do not report zero.
4. Wait for explicit confirmation before pushing that build, tag or release, so the user can choose whether to include another idea first. Do not automatically implement ideas just because they are planned. If there are no accepted/planned ideas, explicitly report zero and still obtain confirmation for the build push.
5. A Deferred idea remains accepted but postponed; it is not a promise for the next release. Revisit it when planning, without silently moving it back.

This gate applies to build/publication pushes. Routine documentation and planning automation updates do not require a release or a new build tag. Never create a test release merely to exercise the planning workflow.
