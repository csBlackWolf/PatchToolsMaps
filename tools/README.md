# Independent client-data pipeline

This developer tooling reads Blizzard client data. It never reads a third-party addon's lookup table and does not write to the game installation. Tools, DB2 files and image files are not part of the runtime ZIP.

## Dependencies used for build 70532

- TACTSharp: https://github.com/wowdev/TACTSharp, commit `d89204e07fa062ccc8f2738ebd0209782912da48` (MIT).
- DBCD: https://github.com/wowdev/DBCD, commit `e732093f8864240fc5884bd1bba6b02f3dfc0d56` (MIT).
- WoWDBDefs: https://github.com/wowdev/WoWDBDefs. Matching DB2 layout hashes select the definitions. Each definition's SHA-256 is in the manifest.
- FileDataID names: wowdev/wow-listfile release `202610202236`. Used only to locate Blizzard tables.

The local `tools-reference` directory is a sibling of this addon repository. ReferenceRoot can be overridden when building the exporter. The two TACTSharp project files were retargeted from net10.0 to net9.0 for the installed .NET 9 SDK; no extraction logic was modified.

## Inputs

Create an input directory containing `definitions/<table>.dbd` for each of these tables and an `extract.txt` with these FileDataIDs:

```text
1134579;WorldMapOverlay.db2
1957202;UiMapArt.db2
1957206;UiMap.db2
1957208;UiMapArtStyleLayer.db2
1957212;WorldMapOverlayTile.db2
1957217;UiMapXMapArt.db2
```

Build `tools/client-export/MapExtract.csproj` in Release with `-p:TargetFrameworks=net9.0 -p:IsAotCompatible=false`. Execute the resulting DLL with arguments:

```text
<input directory> extract <game installation root> wow_classic_beta
<input directory> verify-textures <game installation root> wow_classic_beta
```

The game root contains `.build.info` and `Data/`; it is not the AddOns folder. The exporter selects the named installed product and its actual build/CDN configuration. CDN fallback is disabled. Extraction writes six DB2 files, JSON exports and build provenance into the input directory. The second command reads each referenced BLP2 texture into memory and records only ID/width/height; no image is written or distributed. No hotfix cache is applied in this version of the pipeline.

## Generate

From the shared workspace:

```text
python PatchToolsMaps/tools/generate_catalog.py <input directory> --output PatchToolsMaps --build 70532
```

This writes `GeneratedCatalog.lua` and `CATALOG-MANIFEST.json`. Generation checks the source build, joins active map art to style/layer geometry, orders tiles explicitly by row and column, rejects incomplete/duplicate grids, and verifies referenced texture dimensions against client file headers. Zero-sized records and records with no tiles are reported and omitted. Unexpected flags and player conditions are excluded. Layer indices are converted from DB2 zero-based values to Lua one-based values. Output is deterministic for identical inputs.

The 19 header-size overrides in this build preserve the actual texture UV scale for narrow edges. They are derived from Blizzard image headers, not another addon's calculations.

Do not label this as in-game verified until the map modes, exploration updates and interactions with other map addons have been checked in the live client.


## Classic Era 70003

The Era input uses the five tables needed for catalog geometry (UiMap is not used). Set MAPEXTRACT_LOCALE=deDE for the installed German content; the default enUS locale can select files that are not installed. Extraction remains local-only. An optional required-textures.json array limits header verification to accepted catalog IDs.

Generate into a separate output directory with --build 70003 --skip-invalid-texture-geometry, then keep its Lua as GeneratedCatalogEra.lua and manifest as CATALOG-MANIFEST-ERA.json alongside the existing Forever files. The explicit skip flag quarantines one Era overlay (art 1264) whose declared bottom row is 33 pixels but whose two images are only 32 pixels high. Missing headers still fail generation. Catalog result: 525 overlays, 41 map arts, 808 verified textures, 42 size overrides. No third-party addon data or game images are included.

## Forever 70790

The installed product is now `wowf` (version 1.60.1.70790), rather than the former `wow_classic_beta`. Export with `MAPEXTRACT_LOCALE=deDE`, the current `.build.info` configuration and the existing six-table extract list. If TACTSharp has loaded the root but the optional executable install manifest is missing locally, the exporter continues; every required table and texture must still be readable locally.

Generate into a separate output directory with `--build 70790`. Keep the resulting files as `GeneratedCatalogForever70790.lua` and `CATALOG-MANIFEST-FOREVER-70790.json`, preserving older verified builds. The catalog contains 572 overlays across 45 map arts, with 972 used textures and 19 dimension overrides. Duskwood (UiMap 1431) maps to art 2152. A new build should be checked against its own exported catalog. Until that check is available, the runtime keeps the newest bundled catalog for the same product as a best-effort preview.

## Verified compatible build 70862

The same local extraction and texture-header verification was repeated for `wowf` 1.60.1.70862. All six source DB2 files, decoded tables, definitions, texture headers and generated catalog (after normalizing only the build key) are identical to 70790. `CatalogCompatibility.lua` explicitly maps 70862 to that existing dataset, including its texture-size overrides. Provenance is recorded in `CATALOG-MANIFEST-FOREVER-70862.json`. Unlisted builds remain gated and the options page shows a specific missing-data message. Do not infer compatibility from a nearby build number alone.

Build 70938 was checked against the installed Forever client. All six exported tables and their decoded JSON, texture headers and the normalized generated catalog match the verified prior dataset. `CATALOG-MANIFEST-FOREVER-70938.json` records the comparison; the runtime uses an explicit alias to build 70790. Unknown builds use the same-product fallback described below until verification is available.

## Preview continuity across client patches

The preview stays available on an unknown build using the newest bundled catalog for its own product. Forever and Classic Era catalogs are never mixed. Art ID, layer index, map dimensions and tile dimensions must still match the current client. An absent art or changed geometry keeps only that map on its native display. Existing texture-size overrides follow the selected catalog too.

The options and diagnostic report distinguish a verified build from this fallback. Matching geometry does not prove the contents are current: a client patch can change textures without changing dimensions. Temporary outdated preview data is an accepted tradeoff for keeping the feature usable while development and release testing continue. Do not add a whole-build shutdown again. Continue to check client exports and update changed maps as part of normal maintenance.
