
#pragma once

#include "InfinityLoader/lua_provider_api_core.h"

int Lua_AskResolution(lua_State* L);
int Lua_GetAsyncKeyStateClient(lua_State* L);
int Lua_GetPressedKeysStackNL(lua_State* L);
int Lua_RunWithRawInputLock(lua_State* L);
