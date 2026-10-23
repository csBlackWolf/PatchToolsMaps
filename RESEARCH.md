# Map reveal research: Leatrix Maps and client data

Checked locally on 2026-10-22 against the installed Forever addon:

- `D:/World of Warcraft/_forever_/Interface/AddOns/Leatrix_Maps/Leatrix_Maps.toc`: Leatrix Maps 1.60.25, Interface 16001.
- `Leatrix_Maps_Reveal.lua`: bundled Forever-specific lookup table, indexed by map art ID; each overlay supplies width, height, X/Y offset and texture file IDs.
- `Leatrix_Maps.lua`, MapExplorationPin_RefreshOverlays around line 1699: read map ID and map art ID; compare native explored overlay geometry with the bundled lookup; draw only missing overlays using client texture file IDs. Optional vertex colour/alpha distinguishes unexplored regions.

The texture images are not bundled in that reveal table. They are loaded from the game by file ID. Therefore full reveal does not require learning the whole map through character exploration: the missing piece is the complete mapping from map art to texture IDs and placement.

No Leatrix source or lookup records were copied into PatchToolsMaps. The current CurseForge project lists All Rights Reserved; reading the implementation is distinct from incorporating it.

## Independent data generation

The client table definitions identify a suitable extraction route:

- `WorldMapOverlay`: links overlay records to `UiMapArtID`, texture dimensions, offsets, flags and conditions.
- `WorldMapOverlayTile`: links each overlay to texture `FileDataID`, row, column and layer.
- Additional map art/layer metadata supplies tile sizes and layer dimensions; the native map API provides the current map art at runtime.

Extract the matching client-build tables offline, join overlay/tile rows, preserve explicit row/column/layer placement, and validate conditions/flags. Generate our own lookup from those tables; do not guess geometry or reuse another addon's full database.

A usable map-art catalog should match the live art ID and layer geometry. Build compatibility and per-map validation still matter. The current prototype's exact-build/context catalog keys can be adapted when importing a verified dataset, without changing the user's real exploration state.

## Sources

- Leatrix project and Forever release: https://www.curseforge.com/wow/addons/leatrix-maps
- Client schema definitions: https://github.com/wowdev/WoWDBDefs/blob/master/definitions/WorldMapOverlay.dbd
- Tile schema definitions: https://github.com/wowdev/WoWDBDefs/blob/master/definitions/WorldMapOverlayTile.dbd
- Native Forever rendering: https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_SharedMapDataProviders/MapExplorationDataProvider.lua

## Extraction completed on 2026-10-22

The local CASC store for product `wow_classic_beta`, build **1.60.1.70532**, was read with TACTSharp and parsed with DBCD/WoWDBDefs. Network fallback was disabled and the game installation was not modified.

- 1,081 WorldMapOverlay rows and 1,739 WorldMapOverlayTile rows were decoded.
- Joining current UiMapXMapArt links, UiMapArt and UiMapArtStyleLayer produced **572 drawable overlays on 45 map-art variants**, referencing **972 distinct texture files**.
- 501 unused-art records were omitted. Seven current records had zero dimensions. Overlay 5252 (art 2160) had dimensions but no tile assignments and was omitted rather than guessed.
- All 1,714 distinct texture references in the source table were read locally and their BLP2 headers checked; no image files were exported. Nineteen used narrow-edge files have different dimensions from the usual minimum-16 power-of-two calculation. Their actual dimensions are included for UV calculation.
- Current data has flags 0 and 4 and no player conditions. The generator accepts those observed flags and excludes any other flags/conditions. Flag 4's complete semantics remain unverified; visual testing is still required.
- The generated catalog is keyed by exact build, map art, layer and geometry. It does not require prior character exploration. Existing explored images remain under the native map's control.

The input tables, matching definition hashes, texture-header hash and generated-file hash are recorded in `CATALOG-MANIFEST.json`. Tool versions and reproduction steps are in `tools/README.md`. No hotfix cache was applied. This establishes source-data consistency, not successful in-game rendering.
