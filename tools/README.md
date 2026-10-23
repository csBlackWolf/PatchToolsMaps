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
