
EnhancedWidescreen_Debug_Locks = false

(function()

	if EnhancedWidescreen_Debug_Locks then

		IEex_DisableCodeProtection()

		-- CSingleLock::Lock()
		IEex_HookBeforeAndAfterRestore(0x7EE5C4, 0, 6, 6,
			{[[
				push eax
				push ecx
				push dword ptr ds:[esi]
				push dword ptr ss:[esp+0x14]
				call #L(EnhancedWidescreen_OnBeforeLockObject)
				pop ecx
				pop eax
			]]},
			{[[
				push eax
				push dword ptr ds:[esi]
				call #L(EnhancedWidescreen_OnAfterLockObject)
				pop eax
			]]}
		)

		-- CSingleLock::Unlock()
		IEex_HookBeforeRestore(0x7EE5CE, 0, 7, 7, {[[
			push ecx
			push dword ptr ds:[ecx]
			push dword ptr ss:[esp+0x8]
			call #L(EnhancedWidescreen_OnUnlockingObject)
			pop ecx
		]]})

		IEex_EnableCodeProtection()

		--------------------
		-- /START/ .rdata --
		--------------------

		IEex_SetSegmentProtection(".rdata", 0x4) -- PAGE_READWRITE

		-- EnterCriticalSection()
		local EnterCriticalSection = IEex_ReadU32(0x8342C8)
		local enterCriticalSectionHook = IEex_JITNear({[[

			push dword ptr ss:[esp+0x4] ; EnterCriticalSection() arg

			push dword ptr ss:[esp]
			push dword ptr ss:[esp+0x8]
			call #L(EnhancedWidescreen_OnBeforeLockObject)

			call ]], EnterCriticalSection, [[ #ENDL

			push dword ptr ss:[esp+0x4]
			call #L(EnhancedWidescreen_OnAfterLockObject)
			ret 0x4
		]]})
		IEex_WriteU32(0x8342C8, enterCriticalSectionHook)

		-- LeaveCriticalSection()
		local LeaveCriticalSection = IEex_ReadU32(0x8342B8)
		local leaveCriticalSectionHook = IEex_JITNear({[[
			push dword ptr ss:[esp+0x4]
			push dword ptr ss:[esp+0x4]
			call #L(EnhancedWidescreen_OnUnlockingObject)
			jmp ]], LeaveCriticalSection, [[
		]]})
		IEex_WriteU32(0x8342B8, leaveCriticalSectionHook)

		IEex_SetSegmentProtection(".rdata", 0x2) -- PAGE_READONLY

		------------------
		-- /END/ .rdata --
		------------------
	end
end)()
