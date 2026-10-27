# Developing PatchToolsMaps

PatchToolsMaps owns its map settings and registers them with PatchTools extension API 1, available since PatchTools 0.7.0. Check the API before registering; an incompatible base should receive an explanatory message without attaching map hooks. See the [user guide](GUIDE.md) for installation and controls.

## Runtime responsibilities

`Window.lua` handles map geometry, movement and resizing. Keep Blizzard's native coordinate system aligned with the visible canvas; resizing must not separate hit testing from the displayed art. Preserve zoom and center when the window changes. Clamp at minimum zoom without repeatedly applying tiny corrections, which can make the map shake.

Extended zoom spans the native minimum through four times its maximum. Classic Era also allows zoom and window gestures in combat when the map, scroll container and canvas are unprotected. Observe XML-bound scripts with `HookScript` and enable wheel input on the canvas. `CallMapFunction` keeps ordinary combat map operations separate from the out-of-combat secure call path; it does not grant access to protected frames. Do not edit Blizzard's zoom-level table or add reveal textures to its shared mask list. Defer protected changes in combat; ordinary native zoom remains available.

Settings defaults apply only to missing or invalid values. Preserve an explicit saved `false`. Reset restores geometry and zoom and closes an open map so it can rebuild cleanly. Do not query the current layer before Blizzard has initialized its zoom levels.

## Modern frame and integrations

The modern frame is an Era feature since 0.3.0; Forever retains its native layout. `Frame.lua` owns chrome and explicitly registered fixed widgets, while `Window.lua` retains map coordinates. Classic and fullscreen views restore adopted widgets to their previous parents and anchors. Reject protected widgets. In combat, permit layout only for unprotected Era maps; defer frame-style changes and Forever layout.

Prefer small toolbar icons for addon toggles, with state in tooltips. Keep geographical pins on the canvas and fixed controls/timers in the header or footer. [INTEGRATION.md](INTEGRATION.md) documents the action/widget APIs, load order, ownership, overflow and examples. [ALPHA-FRAME.md](ALPHA-FRAME.md) records the adapters and focused test cases. These APIs are included in 0.3.0; check for their presence with older module versions.

`Opacity.lua` shares the native `worldMapOpacity` CVar and `WorldMapFrame_SetOpacity` curve where available, with a fallback for other clients. Settings-window transparency remains separate. Only position tooltips owned by PatchToolsMaps; leave third-party tooltip handlers alone.

## Map data

Catalogs are generated from client data and selected by client build, map art, layer and geometry. The Forever beta catalog originated from build 70532; Era builds 70003 and 70576 have separate catalogs and manifests. The 70576 data was re-extracted from the installed client and its referenced texture headers were checked; runtime selection still requires the exact build, art and layer geometry. Reference game textures rather than distributing their image files. The exploration cache uses the same isolation and does not record player names, routes or chat.

Skip records with missing texture tiles, undrawable or inconsistent geometry, unsupported conditions or runtime hover-only/top-layer data. Preserve the native display when no matching data exists. Cosmetic reveal must never change exploration state, XP or achievements. Ordinary flags 0 and 4 occur in the sampled Forever data; flag 4 still requires visual checking rather than assuming its meaning.

See [tools/README.md](tools/README.md) for extraction and deterministic generation, the catalog manifests for provenance/hashes, and [RESEARCH.md](RESEARCH.md) for the original investigation. Historical research is context, not a statement of current support.

## Tests

From this repository run `python tests/run_tests.py` with Python and `lupa` (Lua 5.4). The runner expects a sibling `PatchTools-next/PatchTools`; set `PATCHTOOLS_BASE_PATH` when using another checkout. `python tests/test_catalog.py` checks tile ordering, layer indices, incomplete grids and exclusions.

Fixtures cover loading, defaults, reveal, cache isolation, zoom limits, reset and combat behavior; alpha fixtures add docking, coordinates, adapters, restoration and opacity. In-game checks must still cover world/continent/zone maps, resize hit testing, minimum-zoom scrolling, fullscreen changes, reload, combat and third-party addons. Test different exploration states and confirm exploration progress remains unchanged.

## Publication and documentation

CurseForge project 1761299 requires PatchTools project 1758728. Stable releases, including the modern frame, use `main`; keep alpha branches for development history. Check the actual target client's interface number and keep TOC/localized version declarations consistent.

Push a branch commit first and wait for its webhook delivery before pushing a separate version tag. Never push branch and tag together with `--follow-tags`: simultaneous events previously produced duplicate packages. Tags select Release/Alpha/Beta; an ordinary documentation commit does not create a new addon release. Check the resulting build/file and distinguish moderation from availability in the client. Do not overwrite existing tags.

Keep the README short and player-focused, usage in [GUIDE.md](GUIDE.md), and implementation details here or in the integration/data guides. Review GitHub issues or the planning board only when requested; they are not a mandatory publication checkpoint.

MIT; see [LICENSE.txt](LICENSE.txt). Keep the original notices when sharing code.

Window position and scale use `PatchToolsMapsCharacterDB` (`SavedVariablesPerCharacter`). Import legacy account geometry once for each character; keep the legacy values as a migration seed without updating them. Resets affect only the current character. Other preferences, including opacity handling, retain their existing account storage.

The modern close button inherits Blizzard's ordinary `UIPanelCloseButton` template and is parented directly to the map. Keep its XML click handler unchanged. A protected action-button child would implicitly protect the entire map, blocking combat sizing and movement. Escape uses the normal `UISpecialFrames` list; no custom override binding is needed.

Combat layout checks actual protection before touching map geometry. If another addon introduces protected children, stop active gestures and wait until combat ends. Preserve the saved window dimensions/position when native opening resets them. Cache and restore only known unprotected widget anchors; discover new integrations outside combat. Frame-style changes, reset commands and Forever window changes still wait until combat ends.

Tests cover combat wheel zoom, moving and resizing, zoom preservation, native open-time geometry resets and protection appearing mid-gesture. Automated fixtures cannot confirm live-client taint behavior: in-game validation remains necessary.
