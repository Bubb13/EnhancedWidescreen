
#include "InfinityLoader/infinity_loader_common_types.h"
#include "InfinityLoader/lua_provider_api_core.h"
#include "EnhancedWidescreenGUI/enhanced_widescreen_gui_api.h"
#include "raw_input.h"

int Lua_AskResolution(lua_State* L)
{
    DWORD w;
    DWORD h;
    AskResolution(&w, &h);
    lua_pushinteger(L, w);
    lua_pushinteger(L, h);
    return 2;
}

int Lua_GetAsyncKeyStateClient(lua_State* L)
{
    const int nClient = static_cast<int>(lua_tointeger(L, 1));
    const int nKey = static_cast<int>(lua_tointeger(L, 2));
    const SHORT result = Export_GetAsyncKeyStateClient(nClient, nKey);
    lua_pushinteger(L, result);
    return 1;
}

int Lua_GetPressedKeysStackNL(lua_State* L)
{
    const int nStackSize = static_cast<int>(pressedKeysStack.size());
    lua_createtable(L, nStackSize, 0);

    int i = 1;
    for (const UINT pressedKey : pressedKeysStack)
    {
        lua_pushinteger(L, pressedKey);
        lua_rawseti(L, -2, i++);
    }

    return 1;
}

int Lua_RunWithRawInputLock(lua_State* L)
{
    lua_getglobal(L, "debug");               // 2 [ func, debug ]
    lua_getfield(L, -1, "traceback");        // 3 [ func, debug, traceback ]
    lua_pushvalue(L, 1);                     // 4 [ func, debug, traceback, func ]

    int result;
    RunWithRawInputLock([&]()
    {
        result = lua_pcall(L, 0, 0, -2);
    });

    if (result != LUA_OK)
    {                                        // 4 [ func, debug, traceback, errorStr ]
        FPrint("%s\n", lua_tostring(L, -1));
        lua_pop(L, 4);                       // 0 [ ]
    }
    else
    {                                        // 3 [ func, debug, traceback ]
        lua_pop(L, 3);                       // 0 [ ]
    }

    return 0;
}
