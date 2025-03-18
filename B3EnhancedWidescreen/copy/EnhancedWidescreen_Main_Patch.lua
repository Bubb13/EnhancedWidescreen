
IEex_DisableCodeProtection()

-- Sync Thread Entry
IEex_HookBeforeRestore(0x7F0F58, 0, 5, 5, {[[
	call #L(EnhancedWidescreen_OnSyncThreadEntry)
]]})

-- Search Thread Entry
IEex_HookBeforeRestore(0x559832, 0, 5, 5, {[[
	call #L(EnhancedWidescreen_OnSearchThreadEntry)
]]})

-- Resource Manager Thread Entry
IEex_HookBeforeRestore(0x79503D, 0, 7, 7, {[[
	call #L(EnhancedWidescreen_OnResourceManagerThreadEntry)
]]})

-- Network Thread Entry
IEex_HookBeforeRestore(0x795023, 0, 7, 7, {[[
	call #L(EnhancedWidescreen_OnNetworkThreadEntry)
]]})

-- Async Thread Entry
IEex_HookBeforeRestore(0x795057, 0, 7, 7, {[[
	call #L(EnhancedWidescreen_OnAsyncThreadEntry)
]]})

IEex_EnableCodeProtection()

IEex_DoFile("EnhancedWidescreen_Debug_Patch")
IEex_DoFile("EnhancedWidescreen_Fix_Patch")
IEex_DoFile("EnhancedWidescreen_GameState_Patch")
IEex_DoFile("EnhancedWidescreen_GUI_Patch")
IEex_DoFile("EnhancedWidescreen_Input_Patch")
IEex_DoFile("EnhancedWidescreen_Scroll_Patch")
IEex_DoFile("EnhancedWidescreen_UncapFPS_Patch")
