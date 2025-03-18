
EnhancedWidescreen_UncapFPS_Enabled = true

(function()

	if not EnhancedWidescreen_UncapFPS_Enabled then
		return
	end

	IEex_DisableCodeProtection()

	-----------------------------------------------------------------------------------
	-- Unlock FPS                                                                    --
	-----------------------------------------------------------------------------------
	--   Replace the sync and async thread procedures to make the typical game loop: --
	--     1) Handle messages                                                        --
	--     2) Tick the async thread                                                  --
	--     3) Tick the sync thread                                                   --
	--     4) Sleep for a small time                                                 --
	--                                                                               --
	--   This allows the sync thread to run at a high tps while staying aligned      --
	--   with how the engine expects the sync and async threads to interweave.       --
	-----------------------------------------------------------------------------------

	IEex_JITAt(0x42DFE1, {"jmp #L(EnhancedWidescreen_CBaldurChitin_AsyncThread)"})
	IEex_JITAt(0x794E4E, {"jmp #L(EnhancedWidescreen_CChitin_Update)"})

	-- The engine sometimes intertwines a sync tick with an async tick - for example,
	-- to display the loading screen. It does this by signaling the sync thread
	-- with m_bDisplayStale = 1. The following hooks every instance where the
	-- engine does this to also signal the sync thread's condition variable.

	local signalSyncThread = IEex_JITNear({[[
		push eax
		push ecx
		push edx
		push dword ptr ss:[esp+0xC]
		call #L(EnhancedWidescreen_SignalSyncThread)
		pop edx
		pop ecx
		pop eax
		ret
	]]})

	IEex_HookAfterRestore(0x42E142, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x4338ED, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x435E55, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x4398BD, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x439A6D, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x43B6F3, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x43EB1F, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x4422E1, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x4856FB, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x588441, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x58BC44, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x58BCFA, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x58D73E, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x58DE19, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x58E862, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x590F0E, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x59169C, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5934B6, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5937E5, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5A92FD, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5A9382, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5A9F23, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AA3A7, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AA4EE, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AA579, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AABE2, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AAC67, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5ABBB7, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5ACB38, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5ACFE7, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AD23B, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5AD2C9, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5C1149, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5E4276, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5E44CD, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5E4572, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5E7FEB, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x5E81E3, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x6262D4, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x62645A, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x6299A3, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x629A22, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x629ABE, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x629E5E, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x62A100, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x62A31A, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x62A4BF, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x62F613, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x62FA2A, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x6466BF, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x68632F, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x6863B4, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x68790A, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x6888A5, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x688D54, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x688FC5, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x689052, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x73D8C2, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x7403FB, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x77F493, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})
	IEex_HookAfterRestore(0x78CE17, 0, 10, 10, {"call #$(1) #ENDL", {signalSyncThread}})

	----------------------------------------------------------------------------
	-- Smooth Cursor Drawing                                                  --
	----------------------------------------------------------------------------
	--   Render cursor at true position; cursor logic still updates at 30fps. --
	----------------------------------------------------------------------------

	IEex_HookNOPs(0x7A09D7, 0, {[[
		push dword ptr ss:[esp]
		call dword ptr ds:[0x83446C] ; GetCursorPos
		jmp #L(return)
	]]})

	IEex_HookNOPs(0x7A0C2C, 0, {[[
		push dword ptr ss:[esp]
		call dword ptr ds:[0x83446C] ; GetCursorPos
		jmp #L(return)
	]]})

	IEex_EnableCodeProtection()

end)()
