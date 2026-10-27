# Build and release planning

Check GitHub issues and the shared planning board only when the user explicitly requests it. The user reviews planned ideas themselves; issue review and a separate confirmation after that review are not prerequisites for a build push or release.

When the user requests a planning review, read live data. Treat the board as authoritative: Planned, In Progress and Next release are accepted work; Reviewed only means read. Report Deferred items separately. Do not implement or reschedule ideas without user authorization.

Publish builds and releases within the scope authorized by the user. Never create a test release merely to exercise planning or publishing automation.

## CurseForge publication

Push the release commit to the default branch separately from the release tag. Verify the branch push delivery has completed before creating and pushing the tag. Do not push branch and tag together with --atomic or --follow-tags: CurseForge scans for new tags on each push event, and simultaneous events produced duplicate 0.2.1 packages. Verify the resulting CurseForge file count after publication.
