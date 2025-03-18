
-----------------------
-- General Functions --
-----------------------

EnhancedWidescreen_Hotkeys_CustomBinding = {
	SCROLL_UP               =  1,
	SCROLL_UP_ALT           =  2,
	SCROLL_LEFT             =  3,
	SCROLL_LEFT_ALT         =  4,
	SCROLL_DOWN             =  5,
	SCROLL_DOWN_ALT         =  6,
	SCROLL_RIGHT            =  7,
	SCROLL_RIGHT_ALT        =  8,
	SCROLL_TOP_LEFT         =  9,
	SCROLL_TOP_LEFT_ALT     = 10,
	SCROLL_BOTTOM_LEFT      = 11,
	SCROLL_BOTTOM_LEFT_ALT  = 12,
	SCROLL_BOTTOM_RIGHT     = 13,
	SCROLL_BOTTOM_RIGHT_ALT = 14,
	SCROLL_TOP_RIGHT        = 15,
	SCROLL_TOP_RIGHT_ALT    = 16,
}

EnhancedWidescreen_Hotkeys_KeyToCustomMapIndex = {
	[0x25] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_LEFT,             -- VK_LEFT
	[0x26] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_UP,               -- VK_UP
	[0x27] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_RIGHT,            -- VK_RIGHT
	[0x28] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_DOWN,             -- VK_DOWN
	[0x61] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_LEFT_ALT,  -- VK_NUMPAD1
	[0x62] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_DOWN_ALT,         -- VK_NUMPAD2
	[0x63] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_RIGHT_ALT, -- VK_NUMPAD3
	[0x64] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_LEFT_ALT,         -- VK_NUMPAD4
	[0x66] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_RIGHT_ALT,        -- VK_NUMPAD6
	[0x67] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_LEFT_ALT,     -- VK_NUMPAD7
	[0x68] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_UP_ALT,           -- VK_NUMPAD8
	[0x69] = EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_RIGHT_ALT,    -- VK_NUMPAD9
}

function EnhancedWidescreen_Hotkeys_GetBoundCustomMapIndex(key)
	-- CTRL
	if EnhancedWidescreen_Input_IsDown(0x11) then
		key = bit.bor(key, 0x100)
	end
	return EnhancedWidescreen_Hotkeys_KeyToCustomMapIndex[key]
end

EnhancedWidescreen_Hotkeys_ScrollUpCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_UP, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_UP_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollUp(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollUpCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollLeftCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_LEFT, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_LEFT_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollLeft(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollLeftCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollDownCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_DOWN, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_DOWN_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollDown(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollDownCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollRightCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_RIGHT, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_RIGHT_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollRight(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollRightCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollTopLeftCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_LEFT, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_LEFT_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollTopLeft(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollTopLeftCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollBottomLeftCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_LEFT, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_LEFT_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollBottomLeft(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollBottomLeftCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollBottomRightCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_RIGHT, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_RIGHT_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollBottomRight(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollBottomRightCustomMapIndices, customMapIndex) ~= nil
end

EnhancedWidescreen_Hotkeys_ScrollTopRightCustomMapIndices = {
	EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_RIGHT, EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_RIGHT_ALT,
}

function EnhancedWidescreen_Hotkeys_IsScrollTopRight(customMapIndex)
	return customMapIndex ~= nil and IEex_FindInTable(EnhancedWidescreen_Hotkeys_ScrollTopRightCustomMapIndices, customMapIndex) ~= nil
end
