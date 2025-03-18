
IEex_DisableCodeProtection()

-- Invokes IEex_Async.lua and calls IEex_Extern_SetupAsyncState()
IEex_HookBeforeRestore(0x795066, 0, 6, 6, IEex_FlattenTable({
	{[[
		push edx ; Save for call after patch

		call #L(Hardcoded_newLuaState) ; eax = <new Lua state>

		push ]], IEex_WriteStringCache("IEex_Async"), [[ #ENDL
		push eax
		call #L(Hardcoded_doLuaFile)
	]]},
	IEex_GenLuaCall("IEex_Extern_SetupAsyncState"),
	{[[
		call_error:
		pop edx
	]]}
}))

IEex_EnableCodeProtection()
