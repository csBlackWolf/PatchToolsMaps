# PatchToolsMaps

Optional map settings for **PatchTools**, with built-in English and German. Made by Patch & Zen.

**Local development preview 0.1.0-local.7. Not published. Basic window controls passed an initial user test; the latest corner styling needs another in-game test.**

Requires the prepared **PatchTools 0.7.0-local.1** (extension API 1). Published PatchTools 0.6.0 does not yet provide this interface. Without it, the addon prints an explanatory message and does not attach to the world map.

## Prepared features

- A Map section in PatchTools settings, present only when PatchToolsMaps is loaded.
- Drag the window using its top strip.
- Resize uniformly using the small square handle at the bottom-right corner, from 60% to 150% of the original scale. The handle overlaps the frame and uses a dark face, gold edge and diagonal resize marks.
- Save window position and scale. The reset button restores position, size and native zoom/centre, disables extended zoom, and closes an open map. Reopen the map normally to rebuild its display. Closing waits until combat ends when necessary. The full-screen map stays under Blizzard's control.
- Optional extended zoom: one extra close zoom step, with no added image detail. Off by default.
- Three visual modes for unexplored areas: Classic, Semi-transparent fog (default), Fully revealed. Unexplored overlays use 50% opacity in fog mode; explored areas retain their native display.
- Window changes and zoom updates are deferred during combat.
- Opening/minimizing the map waits for Blizzard's zoom levels before querying the current layer. Overlays refresh when those levels become available.

## Map data

The preview includes an independently generated catalog from the installed **Forever beta 1.60.1.70532** client: **572 drawable overlays across 45 map-art variants**. It references 972 client textures; image files are not bundled. Data is used only for matching client build, map art, layer and dimensions. No Leatrix source code or database was copied.

Unexplored areas with catalog data can be displayed immediately, without first exploring them on another character. A local cache of already explored images supplements the catalog. The cache is separated by client build, map art, layer and geometry; it does not record player names, routes or chat.

One client overlay has no assigned texture tiles and seven have no drawable geometry; they are omitted. Unused map-art variants are not bundled. The catalog accepts the ordinary zone flags 0 and 4 found in this build, excluding other flags and player conditions. The full meaning of flag 4 has not been independently established; visual checks against the client remain necessary. Runtime hover-only/top-layer records are excluded from the exploration cache.

Where matching data is unavailable, the native map is retained. This is a build-specific preview, not a claim that every map or later client build is supported. Render order, map labels and the 19 narrow texture edges with explicit file-size corrections need in-game checking.

All modes are visual only. They do not grant exploration, XP or achievements and do not alter the game's explored-area data.

## Local installation, when ready to test

Back up your current PatchTools folder first. Put the prepared `PatchTools` and `PatchToolsMaps` folders alongside one another in the same client's `Interface/AddOns` folder. Enable both and use `/patchtools`, then Map/Karte. Do not install the addon inside the PatchTools folder.

Local test installation is separate from publishing; the public release remains unchanged.

## Tests

Run `python PatchToolsMaps/tests/run_tests.py` from the shared workspace with Python and `lupa` (Lua 5.4). The default base source location is the sibling `PatchTools-next/PatchTools` directory; set `PATCHTOOLS_BASE_PATH` for another location.

Mocks cover the optional/late load, settings page registration, defaults, visual modes, tile boundaries, texture caching, map-art isolation, zoom steps, reset and combat deferral. They do not establish that the UI looks or behaves correctly in the real client.

`python PatchToolsMaps/tests/test_catalog.py` checks independent tile ordering, layer indices, incomplete grids and special-record exclusions. `tools/README.md` documents data extraction and deterministic catalog generation; `CATALOG-MANIFEST.json` records provenance and file hashes.

## Before publishing

- Validate the interface number against the then-current Forever client.
- Test dragging, scaling, map switching, zoom, full-screen transitions, combat and reloading with Questie/GatherMate2 enabled.
- Test two characters with different exploration and confirm normal exploration progress is unchanged.
- Verify generated coverage and special flags in the client; retain explicit exclusions for missing data.
- Publish the compatible PatchTools update first; create a separate CurseForge project with a required PatchTools relationship.
- Replace local versions with package-version placeholders and configure the new project's real ID only after it exists. Do not reuse PatchTools project ID 1758728 for this addon.

## License

MIT. See LICENSE.txt. The bundled code is original; Blizzard textures are referenced from the game, not redistributed.
