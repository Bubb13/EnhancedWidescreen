
-----------------------
-- General Functions --
-----------------------

function EnhancedWidescreen_Scroll_AdjustViewPosition(deltaX, deltaY)
	local infinity = EnhancedWidescreen_Area_GetVisible().m_cInfinity
	local ptCurrentPosExact = infinity.m_ptCurrentPosExact
	local newPtCurrentPosExactX = ptCurrentPosExact.x + deltaX * 10000
	local newPtCurrentPosExactY = ptCurrentPosExact.y + deltaY * 10000
	ptCurrentPosExact.x = newPtCurrentPosExactX
	ptCurrentPosExact.y = newPtCurrentPosExactY
	infinity:SetViewPosition(math.floor(newPtCurrentPosExactX / 10000), math.floor(newPtCurrentPosExactY / 10000), false)
end

function EnhancedWidescreen_Scroll_AdjustViewPositionFromScrollState(scrollState, delta)
	if scrollState == 6 or scrollState == 7 or scrollState == 8 then
		EnhancedWidescreen_Scroll_AdjustViewPosition(-delta, 0)
	end
	if scrollState == 2 or scrollState == 3 or scrollState == 4 then
		EnhancedWidescreen_Scroll_AdjustViewPosition(delta, 0)
	end
	if scrollState == 1 or scrollState == 2 or scrollState == 8 then
		EnhancedWidescreen_Scroll_AdjustViewPosition(0, -delta)
	end
	if scrollState == 4 or scrollState == 5 or scrollState == 6 then
		EnhancedWidescreen_Scroll_AdjustViewPosition(0, delta)
	end
end

function EnhancedWidescreen_Scroll_CalculateDeltaFactor()
	local toReturn = 7500
	local curTick = EngineGlobals.GetTickCount()
	local lastTick = IEex_TryLabel("lastTick")
	if lastTick ~= nil then
		local diff = curTick - lastTick
		toReturn = diff / 50
	end
	IEex_DefineAssemblyLabel("lastTick", curTick)
	return toReturn
end

function EnhancedWidescreen_Scroll_IsAutoScrolling()
	local chitin = EngineGlobals.g_pBaldurChitin
	if not IEex_UDEqual(chitin.m_pActiveEngine, chitin.m_pEngineWorld) then return false end
	local visibleArea = EnhancedWidescreen_Area_GetVisible()
	if visibleArea == nil then return false end
	local ptScrollDest = visibleArea.m_cInfinity.m_ptScrollDest
	return ptScrollDest.x ~= -1 or ptScrollDest.y ~= -1
end

function EnhancedWidescreen_Scroll_ResolveScrollState()
	local state = 0
	for _, key in ipairs(EnhancedWidescreen_Input_GetPressedKeysStack()) do
		local customMapIndex = EnhancedWidescreen_Hotkeys_GetBoundCustomMapIndex(key)
		if EnhancedWidescreen_Hotkeys_IsScrollUp(customMapIndex) then
			if state == 3 or state == 4 then     -- RIGHT / BOTTOM-RIGHT
				state = 2                        -- => TOP-RIGHT
			elseif state == 6 or state == 7 then -- BOTTOM-LEFT / LEFT
				state = 8                        -- => TOP-LEFT
			else
				state = 1                        -- => UP
			end
		elseif EnhancedWidescreen_Hotkeys_IsScrollTopRight(customMapIndex) then
			state = 2                            -- => TOP-RIGHT
		elseif EnhancedWidescreen_Hotkeys_IsScrollRight(customMapIndex) then
			if state == 1 or state == 8 then     -- UP / TOP-LEFT
				state = 2                        -- => TOP-RIGHT
			elseif state == 5 or state == 6 then -- DOWN / BOTTOM-LEFT
				state = 4                        -- => BOTTOM-RIGHT
			else
				state = 3                        -- => RIGHT
			end
		elseif EnhancedWidescreen_Hotkeys_IsScrollBottomRight(customMapIndex) then
			state = 4                            -- => BOTTOM-RIGHT
		elseif EnhancedWidescreen_Hotkeys_IsScrollDown(customMapIndex) then
			if state == 2 or state == 3 then     -- TOP-RIGHT / RIGHT
				state = 4                        -- => BOTTOM-RIGHT
			elseif state == 7 or state == 8 then -- LEFT / TOP-LEFT
				state = 6                        -- => BOTTOM-LEFT
			else
				state = 5                        -- => DOWN
			end
		elseif EnhancedWidescreen_Hotkeys_IsScrollBottomLeft(customMapIndex) then
			state = 6                            -- => BOTTOM-LEFT
		elseif EnhancedWidescreen_Hotkeys_IsScrollLeft(customMapIndex) then
			if state == 1 or state == 2 then     -- UP / TOP-RIGHT
				state = 8                        -- => TOP-LEFT
			elseif state == 4 or state == 5 then -- BOTTOM-RIGHT / DOWN
				state = 6                        -- => BOTTOM-LEFT
			else
				state = 7                        -- => LEFT
			end
		elseif EnhancedWidescreen_Hotkeys_IsScrollTopLeft(customMapIndex) then
			state = 8                            -- => TOP-LEFT
		end
	end
	return state
end

---------------
-- Listeners --
---------------

--///////////////////
--// Thread: Async //
--///////////////////

	------------------------------------------
	-- Suppress default scroll key handling --
	------------------------------------------

	EnhancedWidescreen_Scroll_DefaultKeys = {
		0x61, -- VK_NUMPAD1
		0x62, -- VK_NUMPAD2
		0x63, -- VK_NUMPAD3
		0x64, -- VK_NUMPAD4
		0x66, -- VK_NUMPAD6
		0x67, -- VK_NUMPAD7
		0x68, -- VK_NUMPAD8
		0x69, -- VK_NUMPAD9
	}

	function EnhancedWidescreen_Scroll_RejectHardcodedWorldKeybindingListener(key)
		return IEex_FindInTable(EnhancedWidescreen_Scroll_DefaultKeys, key)
	end

	if IEex_InAsyncState then
		EnhancedWidescreen_Input_AddRejectHardcodedWorldKeybindingListener(EnhancedWidescreen_Scroll_RejectHardcodedWorldKeybindingListener)
	end

--//////////////////
--// Thread: Both //
--//////////////////

	function EnhancedWidescreen_Scroll_OnKeyPressedListener(key)
		if key ~= 4 then return end -- VK_MBUTTON
		local cursorX, cursorY = EnhancedWidescreen_Input_GetCursorPos()
		IEex_DefineAssemblyLabel("oldX", cursorX)
		IEex_DefineAssemblyLabel("oldY", cursorY)
	end
	EnhancedWidescreen_Input_AddKeyPressedListener(EnhancedWidescreen_Scroll_OnKeyPressedListener)

-----------
-- Hooks --
-----------

--//////////////////
--// Thread: Both //
--//////////////////

	function EnhancedWidescreen_Scroll_Extern_CheckScroll()

		EnhancedWidescreen_Input_Check()

		local isMiddleMouseDown = EnhancedWidescreen_Input_IsDown(4) -- VK_MBUTTON

		if isMiddleMouseDown then

			local cursorX, cursorY = EnhancedWidescreen_Input_GetCursorPos()

			local deltaX = IEex_LabelDefault("oldX", 0) - cursorX
			local deltaY = IEex_LabelDefault("oldY", 0) - cursorY

			if EnhancedWidescreen_Input_IsWorldScreenAcceptingInput() and not EnhancedWidescreen_Scroll_IsAutoScrolling() then
				EnhancedWidescreen_Scroll_AdjustViewPosition(deltaX, deltaY)
			end

			IEex_DefineAssemblyLabel("oldX", cursorX)
			IEex_DefineAssemblyLabel("oldY", cursorY)
		end

		local visibleArea = EnhancedWidescreen_Area_GetVisible()
		if visibleArea == nil then
			return
		end

		local deltaFactor = EnhancedWidescreen_Scroll_CalculateDeltaFactor()

		if not isMiddleMouseDown then

			local m_nScrollState = visibleArea.m_nScrollState
			local m_nKeyScrollState = EnhancedWidescreen_Scroll_ResolveScrollState()

			local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
			local scrollSpeed = game.m_nScrollSpeed
			local keyboardScrollSpeed = game.m_nKeyScrollSpeed * EngineGlobals.MaximumFrameRate / 24

			EnhancedWidescreen_Scroll_AdjustViewPositionFromScrollState(m_nScrollState, scrollSpeed * deltaFactor)
			EnhancedWidescreen_Scroll_AdjustViewPositionFromScrollState(m_nKeyScrollState, keyboardScrollSpeed * deltaFactor)
		end
	end
