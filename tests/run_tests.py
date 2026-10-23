from pathlib import Path
import os
from lupa.lua54 import LuaRuntime

workspace = Path(__file__).resolve().parents[2]
maps = workspace / 'PatchToolsMaps'
base = Path(os.environ.get('PATCHTOOLS_BASE_PATH', workspace / 'PatchTools-next' / 'PatchTools'))
for root in (maps, base):
    for path in root.glob('*'):
        if path.suffix in ('.lua', '.toc', '.md', '.txt'):
            path.read_bytes().decode('utf-8', errors='strict')
for locale in ('enUS', 'deDE', 'frFR'):
    os.environ['PATCHTOOLS_TEST_LOCALE'] = locale
    lua = LuaRuntime()
    lua.globals().MAPS_PATH = maps.as_posix() + '/'
    lua.globals().BASE_PATH = base.as_posix() + '/'
    for path in maps.glob('*.lua'):
        lua.execute('assert(loadfile(...))', path.as_posix())
    lua.execute('dofile(...)', (maps / 'tests' / 'maps.lua').as_posix())
    print('Maps integration / UTF-8 / syntax:', locale)
