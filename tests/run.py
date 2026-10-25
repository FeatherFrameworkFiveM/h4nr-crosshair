"""Run the offline Lua 5.4 suite using an installed Lua shared library."""
import ctypes
import ctypes.util
import os
from pathlib import Path

os.chdir(Path(__file__).resolve().parent.parent)
library = ctypes.util.find_library('lua5.4')
if not library:
    raise SystemExit('Lua 5.4 shared library is required (liblua5.4).')
lua = ctypes.CDLL(library)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
try:
    lua.luaL_openlibs(state)
    status = lua.luaL_loadfilex(state, b'tests/crosshair_spec.lua', None)
    if not status:
        status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
    if status:
        raise SystemExit(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)
