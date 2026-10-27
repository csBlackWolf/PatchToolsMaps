# Developing PatchToolsMaps

PatchToolsMaps owns its map settings and registers them with PatchTools extension API 1, available since PatchTools 0.7.0. Check the API before registering; an incompatible base should receive an explanatory message without attaching map hooks. See the [user guide](GUIDE.md) for installation and controls.

## Runtime responsibilities

`Window.lua` handles map geometry, movement and resizing. Keep Blizzard's native coordinate system aligned with the visible canvas; resizing must not separate hit testing from the displayed art. Preserve zoom and center when the window changes. Clamp at minimum zoom without repeatedly applying tiny corrections, which can make the map shake.

Extended zoom spans the native minimum through four times its maximum outside combat. Observe XML-bound scripts with `HookScript`, enable wheel input on the canvas, and use the supported secure call path for instant pan/zoom. Do not edit Blizzard's zoom-level table or add reveal textures to its shared mask list. Defer protected changes in combat; ordinary native zoom remains available.

Settings defaults apply only to missing or invalid values. Preserve an explicit saved `false`. Reset restores geometry and zoom and closes an open map so it can rebuild cleanly. Do not query the current layer before Blizzard has initialized its zoom levels.

## Modern frame and integrations

The modern frame is an Era alpha feature; Forever retains its native layout. `Frame.lua` owns chrome and explicitly registered fixed widgets, while `Window.lua` retains map coordinates. Classic and fullscreen views restore adopted widgets to their previous parents and anchors. Reject protected widgets and defer layout during combat.

Prefer small toolbar icons for addon toggles, with state in tooltips. Keep geographical pins on the canvas and fixed controls/timers in the header or footer. [INTEGRATION.md](INTEGRATION.md) documents the action/widget APIs, load order, ownership, overflow and examples. [ALPHA-FRAME.md](ALPHA-FRAME.md) records the adapters and focused test cases. Those guides describe alpha APIs; check for their presence before using them with stable versions.

`Opacity.lua` shares the native `worldMapOpacity` CVar and `WorldMapFrame_SetOpacity` curve where available, with a fallback for other clients. Settings-window transparency remains separate. Only position tooltips owned by PatchToolsMaps; leave third-party tooltip handlers alone.

## Map data

Catalogs are generated from client data and selected by client build, map art, layer and geometry. The Forever beta catalog originated from build 70532; Era builds 70003 and 70576 have separate catalogs and manifests. The 70576 data was re-extracted from the installed client and its referenced texture headers were checked; runtime selection still requires the exact build, art and layer geometry. Reference game textures rather than distributing their image files. The exploration cache uses the same isolation and does not record player names, routes or chat.

Skip records with missing texture tiles, undrawable or inconsistent geometry, unsupported conditions or runtime hover-only/top-layer data. Preserve the native display when no matching data exists. Cosmetic reveal must never change exploration state, XP or achievements. Ordinary flags 0 and 4 occur in the sampled Forever data; flag 4 still requires visual checking rather than assuming its meaning.

See [tools/README.md](tools/README.md) for extraction and deterministic generation, the catalog manifests for provenance/hashes, and [RESEARCH.md](RESEARCH.md) for the original investigation. Historical research is context, not a statement of current support.

## Tests

From this repository run `python tests/run_tests.py` with Python and `lupa` (Lua 5.4). The runner expects a sibling `PatchTools-next/PatchTools`; set `PATCHTOOLS_BASE_PATH` when using another checkout. `python tests/test_catalog.py` checks tile ordering, layer indices, incomplete grids and exclusions.

Fixtures cover loading, defaults, reveal, cache isolation, zoom limits, reset and combat behavior; alpha fixtures add docking, coordinates, adapters, restoration and opacity. In-game checks must still cover world/continent/zone maps, resize hit testing, minimum-zoom scrolling, fullscreen changes, reload, combat and third-party addons. Test different exploration states and confirm exploration progress remains unchanged.

## Publication and documentation

CurseForge project 1761299 requires PatchTools project 1758728. Keep stable work on `main` and the modern frame on `alpha/custom-map-frame` until it is ready to merge. Check the actual target client's interface number and keep TOC/localized version declarations consistent.

Push a branch commit first and wait for its webhook delivery before pushing a separate version tag. Never push branch and tag together with `--follow-tags`: simultaneous events previously produced duplicate packages. Tags select Release/Alpha/Beta; an ordinary documentation commit does not create a new addon release. Check the resulting build/file and distinguish moderation from availability in the client. Do not overwrite existing tags.

Keep the README short and player-focused, usage in [GUIDE.md](GUIDE.md), and implementation details here or in the integration/data guides. Review GitHub issues or the planning board only when requested; they are not a mandatory publication checkpoint.

MIT; see [LICENSE.txt](LICENSE.txt). Keep the original notices when sharing code.

Window position and scale use `PatchToolsMapsCharacterDB` (`SavedVariablesPerCharacter`). Import legacy account geometry once for each character; keep the legacy values as a migration seed without updating them. Resets affect only the current character. Other preferences, including opacity handling, retain their existing account storage.

The modern close button uses `SecureActionButtonTemplate` with `type="click"` and `clickbutton` pointing to Blizzard's native map close button. Configure it outside combat and keep the inherited OnClick handler intact. Set `useOnKeyDown=false` to match the registered LeftButtonUp click regardless of action-bar preferences. A normal addon closure calling the native handler makes `HideUIPanel` fail its combat security check. Do not replace this path with a direct Lua call or defer closing until combat ends. Geometry and extra zoom retain separate combat guards.

Reference: [Blizzard's panel security check](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua) and [secure click delegation](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).

Combat layout repair reuses snapshots captured after the normal layout pass. Restore anchors/scale only for existing unprotected widgets that still have the same parent, plus the unprotected canvas viewport. Never move the protected map, adopt new widgets, or switch frame modes during combat. Library SetPoints hooks and the visible frame update repair those cached anchors; a widget that becomes protected or changes parent is left untouched until a normal layout is allowed.

The named modern close button also inherits `SecureHandlerShowHideTemplate`. Its secure `_onshow` snippet binds Escape to the secure click action; `_onhide` clears only its own temporary bindings. Visibility inherited from the map drives these handlers even during combat. Do not replace them with addon OnShow bindings or persistent user-binding changes. Tests execute the show/hide snippets in a small fixture and exercise Escape close/reopen, binding cleanup, combat library resets, viewport repair and newly protected/reparented widgets. The real client remains the final check.
