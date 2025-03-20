
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

EnhancedWidescreen_Hotkeys_CustomBindings = {
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_UP]               = { ["iniKey"] = "Scroll Up",                 ["default"] = "Up"       },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_UP_ALT]           = { ["iniKey"] = "Scroll Up (Alt)",           ["default"] = "Keypad 8" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_LEFT]             = { ["iniKey"] = "Scroll Left",               ["default"] = "Left"     },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_LEFT_ALT]         = { ["iniKey"] = "Scroll Left (Alt)",         ["default"] = "Keypad 4" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_DOWN]             = { ["iniKey"] = "Scroll Down",               ["default"] = "Down"     },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_DOWN_ALT]         = { ["iniKey"] = "Scroll Down (Alt)",         ["default"] = "Keypad 2" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_RIGHT]            = { ["iniKey"] = "Scroll Right",              ["default"] = "Right"    },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_RIGHT_ALT]        = { ["iniKey"] = "Scroll Right (Alt)",        ["default"] = "Keypad 6" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_LEFT]         = { ["iniKey"] = "Scroll Top Left",           ["default"] = nil        },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_LEFT_ALT]     = { ["iniKey"] = "Scroll Top Left (Alt)",     ["default"] = "Keypad 7" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_LEFT]      = { ["iniKey"] = "Scroll Bottom Left",        ["default"] = nil        },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_LEFT_ALT]  = { ["iniKey"] = "Scroll Bottom Left (Alt)",  ["default"] = "Keypad 1" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_RIGHT]     = { ["iniKey"] = "Scroll Bottom Right",       ["default"] = nil        },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_BOTTOM_RIGHT_ALT] = { ["iniKey"] = "Scroll Bottom Right (Alt)", ["default"] = "Keypad 3" },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_RIGHT]        = { ["iniKey"] = "Scroll Top Right",          ["default"] = nil        },
	[EnhancedWidescreen_Hotkeys_CustomBinding.SCROLL_TOP_RIGHT_ALT]    = { ["iniKey"] = "Scroll Top Right (Alt)",    ["default"] = "Keypad 9" },
}

EnhancedWidescreen_Hotkeys_KeyToCustomMapIndex = {}

for customBinding, entry in pairs(EnhancedWidescreen_Hotkeys_CustomBindings) do

	local keyStrRepresentation = EnhancedWidescreen.GetINIString("Keymap.ini", "Keymap", entry.iniKey, entry.default or "")
	local virtualKey = EnhancedWidescreen.StringToVirtualKey(keyStrRepresentation)

	if virtualKey ~= 0 then
		EnhancedWidescreen_Hotkeys_KeyToCustomMapIndex[virtualKey] = customBinding
	end
end

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
