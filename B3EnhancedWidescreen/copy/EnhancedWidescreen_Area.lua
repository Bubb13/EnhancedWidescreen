
-----------------------
-- General Functions --
-----------------------

function EnhancedWidescreen_Area_GetVisible()
	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	return game.m_gameAreas:get(game.m_visibleArea)
end
