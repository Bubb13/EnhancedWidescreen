
#include "InfinityLoader/lua_bindings_core_api.h"

#include "EnhancedWidescreenGUI/enhanced_widescreen_gui_api.h"

#include "engine_structs_bg1.h"
#include "EnhancedWidescreen.h"
#include "EnhancedWidescreen_lua.h"
#include "lua_bindings.h"
#include "raw_input.h"
#include "thread_watcher.h"
#include "window_proc.h"

static void exposeToLua(lua_State *const L, const char *const exposedName, const lua_CFunction func)
{
	lua_pushcclosure(L, func, 0);
	lua_setglobal(L, exposedName);
}

static void exportPattern(const String& name, void *const value)
{
	PatternValueHandle handle;
	if (sharedState().GetOrCreatePatternValue(name, PatternValueType::SINGLE, handle)) {
		FPrintT(TEXT("[!][EnhancedWidescreen.dll] exportPattern() - [%s].Type must be SINGLE\n"), name.c_str());
		return;
	}

	sharedState().SetSinglePatternValue(handle, value);
}

// Ugly hack to get a member-function pointer
template<typename T>
static constexpr void* getMemberPtr(T func)
{
	return reinterpret_cast<void*&>(func);
}

static void exportPatterns()
{
	///////////
	// Debug //
	///////////

	exportPattern(TEXT("EnhancedWidescreen_OnBeforeLockObject"), Export_OnBeforeLockObject);
	exportPattern(TEXT("EnhancedWidescreen_OnAfterLockObject"), Export_OnAfterLockObject);
	exportPattern(TEXT("EnhancedWidescreen_OnUnlockingObject"), Export_OnUnlockingObject);

	/////////
	// GUI //
	/////////

	exportPattern(TEXT("EnhancedWidescreen_Override_CGameArea::OnMouseMove"), getMemberPtr(&CGameArea::Export_Override_OnMouseMove));
	exportPattern(TEXT("EnhancedWidescreen_Override_CInfinity::GetWorldCoordinates"), getMemberPtr(&CInfinity::Export_Override_GetWorldCoordinates));
	exportPattern(TEXT("EnhancedWidescreen_Override_CInfinity::SetViewPosition"), getMemberPtr(&CInfinity::Export_Override_SetViewPosition));
	exportPattern(TEXT("EnhancedWidescreen_CInfinity::SetViewPositionAdjustToCenter"), getMemberPtr(&CInfinity::Export_SetViewPositionAdjustToCenter));
	exportPattern(TEXT("EnhancedWidescreen_CInfinity::SetViewPositionIgnoreBounds"), getMemberPtr(&CInfinity::Export_SetViewPositionIgnoreBounds));

	exportPattern(TEXT("EnhancedWidescreen_Patch_CGameArea::AIUpdate()_CheckCursorScroll"), Export_Patch_CGameArea_AIUpdate_CheckCursorScroll);

	exportPattern(TEXT("EnhancedWidescreen_BlankBackBuffer"), Export_BlankBackBuffer);
	exportPattern(TEXT("EnhancedWidescreen_BlankCCache1"), Export_BlankCCache1);
	exportPattern(TEXT("EnhancedWidescreen_BlankCCache2"), Export_BlankCCache2);
	exportPattern(TEXT("EnhancedWidescreen_BlankCCache3"), Export_BlankCCache3);
	exportPattern(TEXT("EnhancedWidescreen_CCacheStatusShimMosaicRender"), Export_CCacheStatusShimMosaicRender);
	exportPattern(TEXT("EnhancedWidescreen_CCacheStatusShimFontRender"), Export_CCacheStatusShimFontRender);

	//////////
	// Misc //
	//////////

	exportPattern(TEXT("EnhancedWidescreen_DivFloor"), Export_DivFloor);
	exportPattern(TEXT("EnhancedWidescreen_Modulo"), Export_Modulo);

	///////////////
	// Raw Input //
	///////////////

	exportPattern(TEXT("EnhancedWidescreen_GetAsyncKeyStateWrapper"), Export_GetAsyncKeyStateWrapper);
	exportPattern(TEXT("EnhancedWidescreen_RegisterRawInput"), Export_RegisterRawInput);

	////////////////
	// Resolution //
	////////////////

	exportPattern(TEXT("EnhancedWidescreen_Override_CVidMode0::ConvertSurfaceToBmp"), getMemberPtr(&CVidMode0::Export_Override_ConvertSurfaceToBmp));

	/////////////////////////
	// Thread Entry Points //
	/////////////////////////

	exportPattern(TEXT("EnhancedWidescreen_OnSyncThreadEntry"), Export_OnSyncThreadEntry);
	exportPattern(TEXT("EnhancedWidescreen_OnSearchThreadEntry"), Export_OnSearchThreadEntry);
	exportPattern(TEXT("EnhancedWidescreen_OnResourceManagerThreadEntry"), Export_OnResourceManagerThreadEntry);
	exportPattern(TEXT("EnhancedWidescreen_OnNetworkThreadEntry"), Export_OnNetworkThreadEntry);
	exportPattern(TEXT("EnhancedWidescreen_OnAsyncThreadEntry"), Export_OnAsyncThreadEntry);

	/////////////
	// Threads //
	/////////////

	exportPattern(TEXT("EnhancedWidescreen_CBaldurChitin_AsyncThread"), getMemberPtr(&CBaldurChitin::Export_AsyncThread));
	exportPattern(TEXT("EnhancedWidescreen_CChitin_Update"), getMemberPtr(&CChitin::Export_Update));
	exportPattern(TEXT("EnhancedWidescreen_SignalSyncThread"), Export_SignalSyncThread);

	/////////////////
	// Window Proc //
	/////////////////

	exportPattern(TEXT("EnhancedWidescreen_WindowProcHook"), Export_WindowProcHook);
}

void __stdcall InitBindings(SharedState argSharedState)
{
	sharedState() = argSharedState;
	InitEnhancedWidescreenGUI(sharedState());
	InitBindingsInternal();

	//InitThreadWatcherMappedMemory();
	//LaunchThreadWatcher();

	InitEnhancedWidescreen();
	exportPatterns();
}

void __stdcall OpenBindings()
{
	InitLuaBindingsCommon(sharedState());

	lua_State *const L = luaState();

	// Export lua bindings
	OpenBindingsInternal(L);

	exposeToLua(L, "EnhancedWidescreen_DLL_AskResolution", Lua_AskResolution);
	exposeToLua(L, "EnhancedWidescreen_DLL_RunWithRawInputLock", Lua_RunWithRawInputLock);
	exposeToLua(L, "EnhancedWidescreen_DLL_GetAsyncKeyStateClient", Lua_GetAsyncKeyStateClient);
	exposeToLua(L, "EnhancedWidescreen_DLL_GetPressedKeysStackNL", Lua_GetPressedKeysStackNL);
}
