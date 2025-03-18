
function IEex_Extern_SetupAsyncState()
	IEex_DoFile("IEex_Assembly")
	IEex_DoFile("IEex_Utility")
	IEex_InAsyncState = true
	IEex_DoFile("EnhancedWidescreen_Main")
	EnhancedWidescreen_Resource_IndexResources()
end
