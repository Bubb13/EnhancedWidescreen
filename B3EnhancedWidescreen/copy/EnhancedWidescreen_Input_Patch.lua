
(function()

	-------------------
	-- Write Patches --
	-------------------

	IEex_DisableCodeProtection()

	------------------------------
	-- Track window focus state --
	------------------------------

	IEex_HookBeforeRestore(0x78F490, 0, 9, 9, {[[
		pop ebx ; save return pointer
		call #L(EnhancedWidescreen_WindowProcHook)
		push ebx ; restore return pointer
	]]})

	--------------------------------------------------------------------------------------
	-- Replace all GetAsyncKeyState() calls with a Raw Input implementation that fakes  --
	-- GetAsyncKeyState()'s behavior. GetAsyncKeyState() sets the low bit of its return --
	-- value when a key has been pressed since the last poll. This allows a process to  --
	-- detect whether it missed a keydown event. However, this behavior is unreliable,  --
	-- as the "since last poll" mechanism is OS-wide, which allows another process on   --
	-- the system to consume a keypress before the engine can read it.                  --
	--------------------------------------------------------------------------------------

		---------------------------------------------------------------------------------
		-- Create a hidden window on a separate thread that accepts Raw Input messages --
		---------------------------------------------------------------------------------

		IEex_HookAfterRestore(0x793811, 0, 6, 6, {[[
			push dword ptr ss:[ebp-0x8] ; hWnd
			call #L(EnhancedWidescreen_RegisterRawInput)
		]]})

		-------------------------------------------
		-- Redirect all GetAsyncKeyState() calls --
		-------------------------------------------

		IEex_JITAt(0x6466CB, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x7910B3, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x791111, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x791154, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x79126C, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x791512, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x7917C2, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x791AFB, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x792792, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x7927AB, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x7927BF, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x792854, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x792D33, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x792D4C, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x792D60, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})
		IEex_JITAt(0x792DCD, {"call #L(EnhancedWidescreen_GetAsyncKeyStateWrapper) #ENDL nop"})

	--------------------------------------------------------------
	-- Allow hardcoded worldscreen keybindings to be suppressed --
	--------------------------------------------------------------

	IEex_HookBeforeRestore(0x667EC8, 0, 7, 7, IEex_FlattenTable({
		{[[
			push eax
			push ecx
			push edx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_Input_Extern_CheckRejectHardcodedWorldKeybinding", {
			["args"] = {
				{[[
					mov eax, dword ptr ss:[esp+0x40] ; Note: Fragile stack access
					add eax, 9
					push eax
				]]}
			},
			["returnType"] = IEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor eax, eax

			no_error:
			test eax, eax
			pop edx
			pop ecx
			pop eax
			jnz 0x668B89
		]]}
	}))

	IEex_EnableCodeProtection()

end)()
