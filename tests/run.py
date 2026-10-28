"""Offline Lua 5.4 suite: syntax of every .lua file, language key parity, then the specs."""
import ctypes
import ctypes.util
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
os.chdir(ROOT)
library = ctypes.util.find_library('lua5.4')
if not library:
    raise SystemExit('Lua 5.4 shared library is required (liblua5.4).')
lua = ctypes.CDLL(library)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]

KEY_PARITY = b"""
dofile('languages/ro.lua')
dofile('languages/en_us.lua')
for name, other in pairs({ ro = 'en_us', en_us = 'ro' }) do
    for key in pairs(Locales[name]) do
        assert(Locales[other][key] ~= nil, ('languages/%s.lua lacks %s'):format(other, key))
    end
end
"""


def run(load, execute=True):
    state = lua.luaL_newstate()
    try:
        lua.luaL_openlibs(state)
        status = load(state)
        if not status and execute:
            status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if status:
            raise SystemExit(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)


files = sorted(ROOT.rglob('*.lua'))
for path in files:
    run(lambda state: lua.luaL_loadfilex(state, os.fsencode(path), None), execute=False)
print(f'Syntax: {len(files)} Lua files passed')
run(lambda state: lua.luaL_loadstring(state, KEY_PARITY))
print('Languages: ro and en_us have the same keys')
run(lambda state: lua.luaL_loadfilex(state, b'tests/crosshair_spec.lua', None))
