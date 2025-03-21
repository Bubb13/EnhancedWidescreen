
IEex_DisableCodeProtection()

-----------------------------------------------------------------------------------------------------------
-- Add a sleep call to CGameObjectArray::GetShare() when it fails due to the async thread holding a lock --
-- on the object. There are many instances where the engine looks for this failure condition, and enters --
-- a tight infinite loop trying to acquire the object. This loop can deadlock the game by starving the   --
-- async thread.                                                                                         --
-----------------------------------------------------------------------------------------------------------

IEex_HookAfterCall(0x582E6E, {[[
	push 1
	call dword ptr ds:[0x834300] ; Sleep
]]})

-------------------------------------------------------------------------------
-- Fix buffer overflow in audioOpen() when path is longer than 80 characters --
-------------------------------------------------------------------------------

IEex_JITAt(0x7D7CA0, {"jmp #L(EnhancedWidescreen_Override_audioOpen)"})

IEex_EnableCodeProtection()
