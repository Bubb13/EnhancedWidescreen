
-----------------------
-- General Functions --
-----------------------

EnhancedWidescreen_Input_KeyPressedListeners = {}

function EnhancedWidescreen_Input_AddKeyPressedListener(func)
	table.insert(EnhancedWidescreen_Input_KeyPressedListeners, func)
end

EnhancedWidescreen_Input_KeyReleasedListeners = {}

function EnhancedWidescreen_Input_AddKeyReleasedListener(func)
	table.insert(EnhancedWidescreen_Input_KeyReleasedListeners, func)
end

EnhancedWidescreen_Input_RejectHardcodedWorldKeybindingListeners = {}

function EnhancedWidescreen_Input_AddRejectHardcodedWorldKeybindingListener(listener)
	table.insert(EnhancedWidescreen_Input_RejectHardcodedWorldKeybindingListeners, listener)
end

function EnhancedWidescreen_Input_Check()
	local clientId
	if IEex_InSyncState then
		clientId = 1
	elseif IEex_InAsyncState then
		clientId = 2
	else
		IEex_Error("EnhancedWidescreen_Input_Check() cannot be called from the current thread")
	end
	EnhancedWidescreen_Input_CheckClient(clientId)
end

EnhancedWidescreen_Input_IsDownT = {}
EnhancedWidescreen_Input_PressedKeysStack = {}

function EnhancedWidescreen_Input_CheckClient(clientId)

	-- Save key states and the pressed keys stack during the Raw Input lock to keep the critical section short
	local keyStates = {}

	-- Locks the Raw Input implementation. Key states / the pressed keys stack will not be updated during the critical section.
	EnhancedWidescreen_DLL_RunWithRawInputLock(function()
		for key = 0x1, 0xFE do
			-- EnhancedWidescreen_DLL_GetAsyncKeyStateClient() allows up to 15 ([0-14]) clients (0 = engine) to query key state while
			-- each having their own "pressed since last poll" state. The export "EnhancedWidescreen_GetAsyncKeyStateWrapper" is
			-- EnhancedWidescreen_DLL_GetAsyncKeyStateClient() with nClient = 0.
			keyStates[key] = EnhancedWidescreen_DLL_GetAsyncKeyStateClient(clientId, key)
		end
		EnhancedWidescreen_Input_PressedKeysStack = EnhancedWidescreen_DLL_GetPressedKeysStackNL()
	end)

	for key = 0x1, 0xFE do

		local keyState = keyStates[key]
		local isDownRightNow = bit.band(keyState, 0x8000) ~= 0x0
		local wasDown = bit.band(keyState, 0x1) ~= 0x0

		local oldIsDown = EnhancedWidescreen_Input_IsDownT[key]
		EnhancedWidescreen_Input_IsDownT[key] = isDownRightNow

		-- If the async thread is running really slow it might miss a keydown + keyup
		-- This corrects missing exactly 1 keydown + keyup sequence for a key
		local missedPress = not isDownRightNow and wasDown and not oldIsDown

		if (isDownRightNow and not oldIsDown) or missedPress then
			-- Run key pressed listeners
			for _, func in ipairs(EnhancedWidescreen_Input_KeyPressedListeners) do
				func(key)
			end
		end

		if (not isDownRightNow and oldIsDown) or missedPress then
			-- Run key released listeners
			for _, func in ipairs(EnhancedWidescreen_Input_KeyReleasedListeners) do
				func(key)
			end
		end
	end
end

function EnhancedWidescreen_Input_GetCursorPos()
	local x, y
	IEex_RunWithStack(CPoint.sizeof, function(esp)
		local toFill = IEex_PtrToUD(esp, "CPoint")
		EngineGlobals.GetCursorPos(toFill)
		x = toFill.x
		y = toFill.y
	end)
	return x, y
end

function EnhancedWidescreen_Input_GetPressedKeysStack()
	return EnhancedWidescreen_Input_PressedKeysStack
end

function EnhancedWidescreen_Input_IsDown(key)
	return EnhancedWidescreen_Input_IsDownT[key]
end

function EnhancedWidescreen_Input_IsWorldScreenAcceptingInput()

	local chitin = EngineGlobals.g_pBaldurChitin
	local inputMode = chitin.m_pObjectGame.m_inputMode
	local worldEngine = chitin.m_pEngineWorld
	local uiManager = worldEngine.m_uiManager

	return
		IEex_IsBitSet(inputMode, 0)               -- (m_pObjectGame->m_gameSave.m_inputMode & 1) != 0
		and
		(
			IEex_IsBitUnset(inputMode, 1)         -- (m_pObjectGame->m_gameSave.m_inputMode & 2) == 0
			or uiManager.m_controlCaptured == nil -- or m_controlCaptured == nullptr
			or uiManager.m_inputCaptured ~= 2     -- or m_inputCaptured ~= 2
		)
		and
		(
			worldEngine.m_bCheatKeysEnabled == 0  -- !m_bCheatKeysEnabled
			or worldEngine.m_bCtrlDown == 0       -- or !m_bCtrlDown
		)
end

-----------
-- Hooks --
-----------

--///////////////////
--// Thread: Async //
--///////////////////

	function EnhancedWidescreen_Input_Extern_CheckRejectHardcodedWorldKeybinding(key)
		for _, listener in ipairs(EnhancedWidescreen_Input_RejectHardcodedWorldKeybindingListeners) do
			if listener(key) then
				return true
			end
		end
		return false
	end
