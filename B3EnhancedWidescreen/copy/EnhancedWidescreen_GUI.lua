
---------------
-- Constants --
---------------

EnhancedWidescreen_GUI_SidebarWidth = 64

if IEex_InSyncState then

	local w, h = EnhancedWidescreen_DLL_AskResolution()

	EnhancedWidescreen_GUI_ResolutionWidth = w
	EnhancedWidescreen_GUI_ResolutionHeight = h

	IEex_DefineAssemblyLabel("EnhancedWidescreen_GUI_ResolutionWidth", EnhancedWidescreen_GUI_ResolutionWidth)
	IEex_DefineAssemblyLabel("EnhancedWidescreen_GUI_ResolutionHeight", EnhancedWidescreen_GUI_ResolutionHeight)

	EnhancedWidescreen.allowedOutOfBoundsLeft = EnhancedWidescreen_GUI_SidebarWidth
	EnhancedWidescreen.allowedOutOfBoundsTop = 0
	EnhancedWidescreen.allowedOutOfBoundsRight = EnhancedWidescreen_GUI_SidebarWidth
	EnhancedWidescreen.allowedOutOfBoundsBottom = 0
else
	EnhancedWidescreen_GUI_ResolutionWidth = IEex_Label("EnhancedWidescreen_GUI_ResolutionWidth")
	EnhancedWidescreen_GUI_ResolutionHeight = IEex_Label("EnhancedWidescreen_GUI_ResolutionHeight")
end

EnhancedWidescreen_GUI_ViewportAdditionalWidth = EnhancedWidescreen_GUI_ResolutionWidth - 640
EnhancedWidescreen_GUI_ViewportAdditionalHeight = EnhancedWidescreen_GUI_ResolutionHeight - 480

EnhancedWidescreen_GUI_ViewportLeft = 0
EnhancedWidescreen_GUI_ViewportTop = 0
EnhancedWidescreen_GUI_ViewportRight = EnhancedWidescreen_GUI_ResolutionWidth
EnhancedWidescreen_GUI_ViewportBottom = EnhancedWidescreen_GUI_ResolutionHeight

-----------------------
-- Control Functions --
-----------------------

function EnhancedWidescreen_GUI_GetControlScreenArea(control)
	local panel = control.m_pPanel
	return panel.m_nX + control.m_nX, panel.m_nY + control.m_nY, control.m_nWidth, control.m_nHeight
end

function EnhancedWidescreen_GUI_IsControlRenderActive(control)
	return control.m_bActive ~= 0 or control.m_bInactiveRender ~= 0
end

function EnhancedWidescreen_GUI_IsPointOverControl(control, x, y)
	local controlX, controlY, controlW, controlH = EnhancedWidescreen_GUI_GetControlScreenArea(control)
	return x >= controlX and x <= (controlX + controlW) and y >= controlY and y <= (controlY + controlH)
end

--------------------------
-- CVidMosaic Functions --
--------------------------

function EnhancedWidescreen_GUI_GetMosaicSize(mosaic)
	local res = mosaic.m_pRes
	res:Demand()
	local mosaicHeader = res.m_pData
	local width = mosaicHeader.nWidth
	local height = mosaicHeader.nHeight
	res:DecrementDemands()
	return width, height
end

---------------------
-- Panel Functions --
---------------------

function EnhancedWidescreen_GUI_IsPanelBlockingViewport(panel, cursorX, cursorY)

	if not EnhancedWidescreen_GUI_IsPanelRenderActive(panel) then
		return false
	end

	if EnhancedWidescreen_GUI_PanelHasBackground(panel) then
		return EnhancedWidescreen_GUI_IsPointOverPanel(panel, cursorX, cursorY)
	else
		local result = false
		IEex_Utility_IterateCPtrList(panel.m_controlList, function(control)
			result = (
				EnhancedWidescreen_GUI_IsControlRenderActive(control)
				and EnhancedWidescreen_GUI_IsPointOverControl(control, cursorX, cursorY)
			)
			return result -- break on true
		end)
		return result
	end
end

function EnhancedWidescreen_GUI_IsPanelRenderActive(panel)
	return panel.m_bActive ~= 0 or panel.m_bInactiveRender ~= 0
end

function EnhancedWidescreen_GUI_IsPointOverPanel(panel, x, y)
	local panelX = panel.m_nX
	local panelY = panel.m_nY
	return x >= panelX and x <= (panelX + panel.m_nWidth) and y >= panelY and y <= (panelY + panel.m_nHeight)
end

function EnhancedWidescreen_GUI_PanelHasBackground(panel)
	return panel.m_mosaic.m_pRes ~= nil
end

-----------------------
-- General Functions --
-----------------------

EnhancedWidescreen_GUI_WorldBottomPanels = {
	3, 4, 7, 8, 9, 12, 6, 13, 14, 16, 17, 18, 19, 21, 22, 24, 25, 26
}

function EnhancedWidescreen_GUI_GetMinBottomPanelY(uiManager)

	local minBottomPanelY = EnhancedWidescreen_GUI_ResolutionHeight
	local minBottomPanelId

	for _, bottomPanelId in ipairs(EnhancedWidescreen_GUI_WorldBottomPanels) do
		local bottomPanel = EnhancedWidescreen_GUI_GetPanelById(uiManager, bottomPanelId)
		if EnhancedWidescreen_GUI_IsPanelRenderActive(bottomPanel) then
			local bottomPanelY = bottomPanel.m_nY
			if bottomPanelY < minBottomPanelY then
				minBottomPanelId = bottomPanelId
				minBottomPanelY = bottomPanelY
			end
		end
	end

	return minBottomPanelY, minBottomPanelId
end

function EnhancedWidescreen_GUI_IsUIBlockingViewport(cursorX, cursorY)
	local uiManager = EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_uiManager
	local result = false
	IEex_Utility_IterateCPtrList(uiManager.m_panelList, function(panel)
		result = EnhancedWidescreen_GUI_IsPanelBlockingViewport(panel, cursorX, cursorY)
		return result -- break on true
	end)
	return result
end

--------------------------
-- UI Manager Functions --
--------------------------

function EnhancedWidescreen_GUI_GetPanelById(uiManager, panelId)
	local toReturn = nil
	IEex_Utility_IterateCPtrList(uiManager.m_panelList, function(panel)
		if panel.m_nId == panelId then
			toReturn = panel
			return true -- break
		end
	end)
	return toReturn
end

-----------
-- Hooks --
-----------

function EnhancedWidescreen_GUI_Extern_BeforeWorldRender(uiManager)

	--------------------------------------------------------------------------
	-- Invalidate all worldscreen panels to make them render above viewport --
	--------------------------------------------------------------------------

	uiManager:Invalidate()

	---------------------------------------------------------------------
	-- Check the allowed out-of-bounds viewport scrolling restrictions --
	---------------------------------------------------------------------

	local minBottomPanelY = EnhancedWidescreen_GUI_GetMinBottomPanelY(uiManager)
	EnhancedWidescreen.allowedOutOfBoundsBottom = EnhancedWidescreen_GUI_ResolutionHeight - minBottomPanelY

	-- Force viewport into bounds if the restrictions changed
	local infinity = EnhancedWidescreen_Area_GetVisible().m_cInfinity
	infinity:SetViewPosition(infinity.m_nNewX, infinity.m_nNewY, true)
end

function EnhancedWidescreen_GUI_Extern_IsUIBlockingAreaViewport(area)
	local cursorPos = area.m_cursorPos
	return EnhancedWidescreen_GUI_IsUIBlockingViewport(cursorPos.x, cursorPos.y)
end

EnhancedWidescreen_GUI_CHUHasSidebars = {
	["GUIBASE"]  = true,
	["GUIINV"]   = true,
	["GUIJRNL"]  = true,
	["GUIMAP"]   = true,
	["GUIMG"]    = true,
	["GUIOPT"]   = true,
	["GUIPR"]    = true,
	["GUIREC"]   = true,
	["GUISTORE"] = true,
	["GUITEST"]  = true,
	["GUIW"]     = true,
}

function EnhancedWidescreen_GUI_Extern_OnCHUInitialized(uiManager)

	local chuResref = uiManager.m_id:get()

	if EnhancedWidescreen_GUI_CHUHasSidebars[chuResref] then

		local panel0 = EnhancedWidescreen_GUI_GetPanelById(uiManager, 0)
		panel0.m_nY = panel0.m_nY + EnhancedWidescreen_GUI_ViewportAdditionalHeight / 2

		local panel1 = EnhancedWidescreen_GUI_GetPanelById(uiManager, 1)
		panel1.m_nX = panel1.m_nX + EnhancedWidescreen_GUI_ViewportAdditionalWidth
		panel1.m_nY = panel1.m_nY + EnhancedWidescreen_GUI_ViewportAdditionalHeight / 2
	end

	if chuResref == "GUIW" then

		IEex_Utility_IterateCPtrList(uiManager.m_panelList, function(panel)

			local panelId = panel.m_nId

			if panelId == 0 or panelId == 1 then
				return -- continue
			end

			if panelId == 2 then
				panel.m_bActive = false
				return -- continue
			end

			panel.m_nX = panel.m_nX + EnhancedWidescreen_GUI_ViewportAdditionalWidth / 2
			panel.m_nY = panel.m_nY + EnhancedWidescreen_GUI_ViewportAdditionalHeight
		end)
	else
		IEex_Utility_IterateCPtrList(uiManager.m_panelList, function(panel)

			local panelId = panel.m_nId
			if EnhancedWidescreen_GUI_CHUHasSidebars[chuResref] and (panelId == 0 or panelId == 1) then
				return -- continue
			end

			panel.m_nX = panel.m_nX + EnhancedWidescreen_GUI_ViewportAdditionalWidth / 2
			panel.m_nY = panel.m_nY + EnhancedWidescreen_GUI_ViewportAdditionalHeight / 2
		end)
	end
end

function EnhancedWidescreen_GUI_Extern_RejectGetWorldCoordinates(screenX, screenY)
	return EnhancedWidescreen_GUI_IsUIBlockingViewport(screenX, screenY)
end

EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc = {
	["CGameDialogEntry_Handle_Instant"] = 1,
	["CGameDialogEntry_Handle"] = 2,
	["CMessageAutoScroll_Run"] = 3,
	["CScreenWorld_AsynchronousUpdate"] = 4,
	["CScreenWorld_EndDialog_Instant"] = 5,
	["CScreenWorld_EndDialog"] = 6,
}

EnhancedWidescreen_GUI_SetAutoScrollDest_RetPtrToCallSrc = {
	[0x49630D] = EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CGameDialogEntry_Handle_Instant,
	[0x496344] = EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CGameDialogEntry_Handle,
	[0x5191B8] = EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CMessageAutoScroll_Run,
	[0x66C700] = EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_AsynchronousUpdate,
	[0x6711CC] = EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_EndDialog_Instant,
	[0x6711EF] = EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_EndDialog,
}

EnhancedWidescreen_GUI_InstantScrollRangeX = EnhancedWidescreen_GUI_ResolutionWidth * 2 / 3 * math.sqrt(2)
EnhancedWidescreen_GUI_InstantScrollRangeY = EnhancedWidescreen_GUI_ResolutionHeight * 2 / 3 * math.sqrt(2)
EnhancedWidescreen_GUI_InstantScrollRangeXSquared = EnhancedWidescreen_GUI_InstantScrollRangeX * EnhancedWidescreen_GUI_InstantScrollRangeX
EnhancedWidescreen_GUI_InstantScrollRangeYSquared = EnhancedWidescreen_GUI_InstantScrollRangeY * EnhancedWidescreen_GUI_InstantScrollRangeY

function EnhancedWidescreen_GUI_Extern_AdjustAutoScrollDest(retPtr, xRef, yRef, speedRef)

	local destX = xRef.value
	local destY = yRef.value
	local speed = speedRef.value

	local callSrc = EnhancedWidescreen_GUI_SetAutoScrollDest_RetPtrToCallSrc[retPtr]

	if     callSrc == EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CGameDialogEntry_Handle_Instant
		or callSrc == EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CGameDialogEntry_Handle
	then
		local uiManager = EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_uiManager

		local spriteX = destX + 256
		local spriteY = destY + 96

		destX = spriteX - EnhancedWidescreen_GUI_ResolutionWidth / 2
		destY = spriteY - EnhancedWidescreen_GUI_GetMinBottomPanelY(uiManager) / 2

	elseif  callSrc ~= EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_EndDialog_Instant
		and callSrc ~= EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_EndDialog
	then
		local uiManager = EngineGlobals.g_pBaldurChitin.m_pEngineWorld.m_uiManager
		local yToCenterOn = destY + EnhancedWidescreen_GUI_ResolutionHeight / 2
		destY = yToCenterOn - EnhancedWidescreen_GUI_GetMinBottomPanelY(uiManager) / 2
	end

	if     callSrc == EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CGameDialogEntry_Handle_Instant
		or callSrc == EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CGameDialogEntry_Handle
		or callSrc == EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_EndDialog_Instant
		or callSrc == EnhancedWidescreen_GUI_SetAutoScrollDest_CallSrc.CScreenWorld_EndDialog
	then
		local infinity = EnhancedWidescreen_Area_GetVisible().m_cInfinity

		local distX = destX - infinity.m_nNewX
		local distY = destY - infinity.m_nNewY
		local distXSquared = distX * distX
		local distYSquared = distY * distY

		local distance = math.sqrt(distXSquared + distYSquared)

		local distXSquaredEllipse = distXSquared / EnhancedWidescreen_GUI_InstantScrollRangeXSquared
		local distYSquaredEllipse = distYSquared / EnhancedWidescreen_GUI_InstantScrollRangeYSquared
		local distSquaredEllipse = distXSquaredEllipse + distYSquaredEllipse

		local scaledSpeed = math.max(16, distance / 16)
		speed = distSquaredEllipse <= 1 and scaledSpeed or 0
	end

	xRef.value = destX
	yRef.value = destY
	speedRef.value = speed
end

function EnhancedWidescreen_GUI_Extern_AdjustLocalMapViewPosition(mapButton)

	local area = mapButton.m_pArea
	local infinity = area.m_cInfinity

	local allowedOutOfBoundsLeft = EnhancedWidescreen.allowedOutOfBoundsLeft
	local allowedOutOfBoundsRight = EnhancedWidescreen.allowedOutOfBoundsRight
	local allowedOutOfBoundsTop = EnhancedWidescreen.allowedOutOfBoundsTop
	local allowedOutOfBoundsBottom = EnhancedWidescreen.allowedOutOfBoundsBottom

	local rViewPort = infinity.m_rViewPort
	local nViewportWidth = rViewPort.right - rViewPort.left;
	local nViewportHeight = rViewPort.bottom - rViewPort.top;

	local nEffectiveViewportWidth = nViewportWidth - allowedOutOfBoundsLeft - allowedOutOfBoundsRight
	local nEffectiveViewportHeight = nViewportHeight - allowedOutOfBoundsTop - allowedOutOfBoundsBottom

	local nAreaWidth = infinity.m_nAreaWidth
	local nAreaHeight = infinity.m_nAreaHeight

	local rViewPosition = mapButton.m_rViewPosition

	if nEffectiveViewportWidth <= nAreaWidth then
		rViewPosition.left = rViewPosition.left + allowedOutOfBoundsLeft
		rViewPosition.right = rViewPosition.right - allowedOutOfBoundsRight - 1
	else
		rViewPosition.left = 0
		rViewPosition.right = nAreaWidth - 1
	end

	if nEffectiveViewportHeight <= nAreaHeight then
		rViewPosition.top = rViewPosition.top + allowedOutOfBoundsTop
		rViewPosition.bottom = rViewPosition.bottom - allowedOutOfBoundsBottom - 1
	else
		rViewPosition.top = 0
		rViewPosition.bottom = nAreaHeight - 1
	end
end

function EnhancedWidescreen_GUI_Extern_AdjustLocalMapSetViewPosition(xRef, yRef)
	xRef.value = xRef.value - EnhancedWidescreen.allowedOutOfBoundsLeft
	yRef.value = yRef.value - EnhancedWidescreen.allowedOutOfBoundsTop
end
