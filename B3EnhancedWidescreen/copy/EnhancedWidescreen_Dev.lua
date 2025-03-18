

function EnhancedWidescreen_Dev_DumpControlVFTables()

	local assertTripped = IEex_Malloc(0x1)
	IEex_WriteU8(assertTripped, 0)

	IEex_DisableCodeProtection()
	IEex_JITAt(0x78E3C0, {[[
		mov byte ptr ds:[#$(1)], 1 ]], {assertTripped}, [[ #ENDL
		ret
	]]})
	IEex_EnableCodeProtection()

	local uiManager = IEex_NewUD("CUIManager")
	uiManager:Construct()

	local causesCrash = {
		["WORLD"]  = {["malformed"] = true},
	}

	local willCauseCrash = function(resref, panelId, controlId)
		local resrefTable = causesCrash[resref]
		if not resrefTable then return false end
		if resrefTable.malformed then return true end
		local panelTable = resrefTable[panelId]
		if not panelTable then return false end
		local controlVal = panelTable[controlId]
		if controlVal == nil then return false end
		return controlVal
	end

	for i, resref in ipairs(EnhancedWidescreen_Resource_ResRefsOfExtension("CHU")) do

		if not willCauseCrash(resref, nil, nil) then

			uiManager.m_id:set(resref)
			local resWrapper = EnhancedWidescreen_Resource_Demand(resref, "CHU")

			if resWrapper ~= nil then

				local resUI = resWrapper:getRes()

				for panelIndex = 0, resUI:GetPanelNo() - 1 do

					local panelInfo = resUI:GetPanel(panelIndex)
					local panelId = panelInfo.id
					local panel = IEex_NewUD("CUIPanel")
					panel:Construct(uiManager, panelInfo)

					for controlIndex = 0, resUI:GetControlNo(panelIndex) - 1 do

						local controlInfo = resUI:GetControl(panelIndex, controlIndex)
						local controlId = controlInfo.id
						local controlIdStr = controlId < 0xFFFFFFF and tostring(controlId) or string.format("0x%X", controlId)

						if not willCauseCrash(resref, panelId, controlId) then

							local control = CUIControlBase.CreateControl(panel, controlInfo)

							if IEex_ReadU8(assertTripped) == 1 then
								IEex_WriteU8(assertTripped, 0)
								print(string.format("%s->%d->%s - Assert tripped", resref, panelId, controlIdStr))
							elseif control == 0x0 then
								print(string.format("%s->%d->%s - Undefined", resref, panelId, controlIdStr))
							else
								print(string.format("%s->%d->%s - %s", resref, panelId, controlIdStr, IEex_ToHex(IEex_ReadU32(IEex_UDToPtr(control)))))
							end
						else
							print(string.format("%s->%d->%s - Crash", resref, panelId, controlIdStr))
						end
					end
				end

				resWrapper:free()
			end
		else
			print(resref.." - Malformed")
		end
	end

	uiManager:Destruct()
	IEex_FreeUD(uiManager)

	IEex_DisableCodeProtection()
	IEex_JITAt(0x78E3C0, {[[
		push ebp
		mov ebp, esp
		mov ecx, dword ptr ds:[0x8ACE00]
	]]})
	IEex_EnableCodeProtection()

	IEex_Free(assertTripped)
end
