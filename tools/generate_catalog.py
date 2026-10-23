"""Build a map-art catalog from independently extracted Blizzard DB2 JSON.

No game images or third-party addon databases are inputs. Run with the folder
containing DBCD exports and --output pointing to this addon's root.
"""
import argparse
from collections import Counter, defaultdict
from hashlib import sha256
import json
from pathlib import Path

TABLES = ('WorldMapOverlay', 'WorldMapOverlayTile', 'UiMapArt',
          'UiMapArtStyleLayer', 'UiMapXMapArt')


def generate(tables):
    arts = {r['ID']: r for r in tables['UiMapArt']}
    styles, tiles = defaultdict(list), defaultdict(list)
    for r in tables['UiMapArtStyleLayer']:
        styles[r['UiMapArtStyleID']].append(r)
    for r in tables['WorldMapOverlayTile']:
        tiles[r['WorldMapOverlayID']].append(r)
    active = {r['UiMapArtID'] for r in tables['UiMapXMapArt']}
    catalog, skipped = defaultdict(lambda: defaultdict(list)), Counter()
    for overlay in sorted(tables['WorldMapOverlay'], key=lambda r: r['ID']):
        art = overlay['UiMapArtID']
        if art not in active:
            skipped['unused_art'] += 1
            continue
        # This build uses 0 and 4 for ordinary zone records. Do not infer
        # behaviour for any other flags or player-conditional overlays.
        if overlay['Flags'] not in (0, 4) or overlay['PlayerConditionID']:
            skipped['special_or_conditional'] += 1
            continue
        w, h, x, y = (overlay[k] for k in ('TextureWidth', 'TextureHeight', 'OffsetX', 'OffsetY'))
        if not (0 < w <= 16384 and 0 < h <= 16384 and 0 <= x <= 32768 and 0 <= y <= 32768):
            skipped['no_renderable_geometry'] += 1
            continue
        if art not in arts:
            raise ValueError(f'Missing map art {art}')
        by_layer = defaultdict(list)
        for tile in tiles[overlay['ID']]:
            by_layer[tile['LayerIndex']].append(tile)
        if not by_layer:
            skipped['missing_tiles'] += 1
            continue
        for layer_index, layer_tiles in by_layer.items():
            layers = [r for r in styles[arts[art]['UiMapArtStyleID']] if r['LayerIndex'] == layer_index]
            if len(layers) != 1:
                raise ValueError(f'Ambiguous or missing layer for overlay {overlay["ID"]}')
            layer = layers[0]
            tw, th = layer['TileWidth'], layer['TileHeight']
            if not (0 < tw <= 4096 and 0 < th <= 4096):
                raise ValueError('Invalid tile size')
            cols, rows = (w+tw-1)//tw, (h+th-1)//th
            cells = {(t['RowIndex'], t['ColIndex']): t['FileDataID'] for t in layer_tiles}
            expected = {(row, col) for row in range(rows) for col in range(cols)}
            if len(cells) != len(layer_tiles) or set(cells) != expected or len(cells) > 256:
                raise ValueError(f'Invalid tile grid for overlay {overlay["ID"]}')
            ids = [cells[(row, col)] for row in range(rows) for col in range(cols)]
            if not all(0 < i <= 2147483647 for i in ids):
                raise ValueError('Invalid FileDataID')
            # DB2 layer indices start at zero, the Lua API indexes from one.
            key = ':'.join(str(v) for v in (layer_index+1, layer['LayerWidth'], layer['LayerHeight'], tw, th))
            catalog[art][key].append({'textureWidth': w, 'textureHeight': h,
                                    'offsetX': x, 'offsetY': y, 'fileDataIDs': ids})
    return dict(catalog), dict(skipped)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--build', type=int, required=True)
    parser.add_argument('--skip-invalid-texture-geometry', action='store_true',
                        help='Exclude overlays whose client images cannot cover their declared geometry')
    args = parser.parse_args()
    metadata = json.loads((args.input/'extraction-meta.json').read_text(encoding='utf-8'))
    if int(metadata['version'].split('.')[-1]) != args.build or not metadata['localOnly']:
        raise ValueError('Client provenance does not match the requested local build')
    tables = {n: json.loads((args.input/f'{n}.json').read_text(encoding='utf-8')) for n in TABLES}
    catalog, skipped = generate(tables)
    headers_path = args.input/'texture-headers.json'
    headers = {r['id']: r for r in json.loads(headers_path.read_text(encoding='utf-8'))}
    verified_ids, sizes = set(), {}
    for layers in catalog.values():
        for layer_key, overlays in layers.items():
            _, _, _, tw, th = map(int, layer_key.split(':'))
            for overlay in list(overlays):
                cols = (overlay['textureWidth']+tw-1)//tw
                overlay_ids, overlay_sizes = set(), {}
                valid = True
                for index, fdid in enumerate(overlay['fileDataIDs']):
                    w = min(tw, overlay['textureWidth']-(index%cols)*tw)
                    h = min(th, overlay['textureHeight']-(index//cols)*th)
                    pw, ph = max(16, 1 << (w-1).bit_length()), max(16, 1 << (h-1).bit_length())
                    actual = headers.get(fdid)
                    if not actual:
                        raise ValueError(f'Missing texture header for {fdid}')
                    if any(v < needed or v > 4096 or v & (v-1)
                           for v,needed in ((actual['width'],w),(actual['height'],h))):
                        if not args.skip_invalid_texture_geometry:
                            raise ValueError(f'Invalid texture dimensions for {fdid}: {actual}')
                        valid = False
                        break
                    if (actual['width'],actual['height']) != (pw,ph):
                        overlay_sizes[fdid] = (actual['width'],actual['height'])
                    overlay_ids.add(fdid)
                if valid:
                    sizes.update(overlay_sizes)
                    verified_ids.update(overlay_ids)
                else:
                    overlays.remove(overlay)
                    skipped['invalid_texture_geometry'] = skipped.get('invalid_texture_geometry', 0) + 1
    lines = ['local _, Maps = ...', '-- Generated from Blizzard client tables. Do not edit by hand.',
             'Maps.catalog = Maps.catalog or {}', f'Maps.catalog[{args.build}] = {{']
    count = 0
    for art, layers in sorted(catalog.items()):
        lines.append(f'    [{art}] = {{')
        for layer, overlays in sorted(layers.items()):
            lines.append(f'        ["{layer}"] = {{')
            for o in overlays:
                count += 1
                lines.append('            {textureWidth=%d,textureHeight=%d,offsetX=%d,offsetY=%d,fileDataIDs={%s}},' %
                             (o['textureWidth'],o['textureHeight'],o['offsetX'],o['offsetY'],','.join(map(str,o['fileDataIDs']))))
            lines.append('        },')
        lines.append('    },')
    lines.append('}')
    lines.extend(['Maps.catalogTextureSizes = Maps.catalogTextureSizes or {}',
                  f'Maps.catalogTextureSizes[{args.build}] = {{'])
    for fdid, (w,h) in sorted(sizes.items()):
        lines.append(f'    [{fdid}] = {{{w},{h}}},')
    lines.append('}')
    content = '\n'.join(lines)+'\n'
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output/'GeneratedCatalog.lua').write_text(content, encoding='utf-8', newline='\n')
    manifest = {'build': args.build, 'client': metadata,
                'source': 'Installed Blizzard client DB2 tables; DBCD JSON exports',
                'map_art_count': len(catalog), 'overlay_count': count, 'skipped': skipped,
                'flags_policy': 'Accept 0 and 4 observed in this build; reject other flags and player conditions. In-game verification pending.',
                'verified_texture_count': len(verified_ids),
                'texture_size_overrides': len(sizes),
                'texture_headers_sha256': sha256(headers_path.read_bytes()).hexdigest(),
                'sha256': {}, 'catalog_sha256': sha256(content.encode()).hexdigest()}
    for name in TABLES:
        for ext in ('db2', 'json'):
            path = args.input/f'{name}.{ext}'
            manifest['sha256'][path.name] = sha256(path.read_bytes()).hexdigest()
        path = args.input/'definitions'/f'{name}.dbd'
        manifest['sha256'][f'definitions/{path.name}'] = sha256(path.read_bytes()).hexdigest()
    (args.output/'CATALOG-MANIFEST.json').write_text(json.dumps(manifest, indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:manifest[k] for k in ('build','map_art_count','overlay_count','skipped')}))


if __name__ == '__main__':
    main()
