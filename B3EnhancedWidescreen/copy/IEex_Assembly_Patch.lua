
if IEex_Architecture == "x86" then
	IEex_DoFile("IEex_Assembly_x86_Patch")
elseif IEex_Architecture == "x86-64" then
	IEex_DoFile("IEex_Assembly_x86-64_Patch")
else
	IEex_Error(string.format("Unhandled IEex_Architecture: \"%s\"", IEex_Architecture))
end
