
(function()

	local mainStatus, mainError = xpcall(function()

		IEex_DoFile("IEex_Assembly")
		IEex_DoFile("IEex_Assembly_Patch")

		IEex_DoFile("IEex_Async_Patch")

		IEex_DoFile("IEex_Utility")

		IEex_InSyncState = true

		IEex_DoFile("EnhancedWidescreen_Main")
		IEex_DoFile("EnhancedWidescreen_Main_Patch")

		print("IEex startup completed successfully!")
		print("")

	end, debug.traceback)

	if not mainStatus then
		print("ERROR: "..mainError)
		IEex_MessageBox("ERROR: "..mainError)
	end

end)()
