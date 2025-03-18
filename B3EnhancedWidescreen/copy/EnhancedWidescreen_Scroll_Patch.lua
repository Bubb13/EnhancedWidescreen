
IEex_DisableCodeProtection()

-------------------------------------------------------------------------------------------------
-- Smooth Scrolling                                                                            --
-------------------------------------------------------------------------------------------------
--   Replace viewport scrolling with implementation that runs on sync thread, (at higher tps). --
-------------------------------------------------------------------------------------------------

IEex_HookBeforeAndAfterCall(0x5B8032,
	{"mov byte ptr ds:[esp], 0"},
	IEex_FlattenTable({
		IEex_GenLuaCall("EnhancedWidescreen_Scroll_Extern_CheckScroll"), [[
		call_error:
	]]})
)

IEex_EnableCodeProtection()
