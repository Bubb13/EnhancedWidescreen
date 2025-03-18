
-----------
-- .text --
-----------

IEex_DisableCodeProtection()

--/////////
--// GUI //
--/////////

	-----------------------------------------
	-- Adjust UI panel / control positions --
	-----------------------------------------

	IEex_HookBeforeCall(0x4DF4EF, IEex_FlattenTable({
		{[[
			push ecx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_GUI_Extern_OnCHUInitialized", {
			["args"] = {
				{"push dword ptr ss:[esp+0x10] #ENDL", "CUIManager"} -- Note: Fragile stack access
			},
		}),
		{[[
			call_error:
			pop ecx
		]]},
	}))

	------------------------------
	-- Render UI after viewport --
	------------------------------

	IEex_JITAt(0x66DD01, {"#REPEAT(5,nop #ENDL)"})

	IEex_HookBeforeCall(0x66DD4F, IEex_FlattenTable({
		{[[
			push ecx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_GUI_Extern_BeforeWorldRender", {
			["args"] = {
				{[[
					mov eax, dword ptr ss:[esp+0x14] ; Note: Fragile stack access
					add eax, 0x30
					push eax
				]], "CUIManager"}
			},
		}),
		{[[
			call_error:
			pop ecx
		]]},
	}))

	IEex_HookAfterRestore(0x66DD5E, 0, 6, 6, {[[
		mov ecx, dword ptr ss:[ebp-0x18]
		add ecx, 0x30
		call 0x4DFFB2 ; CUIManager::Render
	]]})

	-------------------------------------------------------------------
	-- Allow UI elements to block cursor from interacting with world --
	-------------------------------------------------------------------

	-- CGameArea::AIUpdate() - Properly update cursor shape when UI is between cursor and world
	IEex_HookNOPs(0x47BB30, 2, IEex_FlattenTable({
		{[[
			push eax
			push ecx
			push edx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_GUI_Extern_IsUIBlockingAreaViewport", {
			["args"] = {
				{"push dword ptr ss:[esp+0x54] #ENDL", "CGameArea"} -- Note: Fragile stack access
			},
			["returnType"] = IEex_LuaCallReturnType.Boolean,
		}),
		{[[
			xor eax, 1
			jmp no_error

			call_error:
			mov eax, 1

			no_error:
			mov dword ptr ss:[ebp-0x8], eax
			pop edx
			pop ecx
			pop eax
			jmp #L(return)
		]]},
	}))

	-- CGameArea::OnActionButtonDown() - Reject world coordinates (-1, -1) when handling left click
	IEex_HookJump(0x485DC8, 3, IEex_FlattenTable({
		{[[
			cmp dword ptr ds:[esp+0x40], -1 ; Note: Fragile stack access
			jne not_reject

			cmp dword ptr ds:[esp+0x44], -1 ; Note: Fragile stack access
			jne not_reject

			jmp #L(jmp_success)

			not_reject:
			cmp eax, dword ptr ds:[edx+0x4A8]
		]]},
	}))

	-- CGameArea::OnActionButtonDblClk() - Reject world coordinates (-1, -1) when handling double left click
	IEex_HookBeforeCall(0x4877F6, IEex_FlattenTable({
		{[[
			cmp dword ptr ss:[ebp-0x1C], -1
			jne not_reject

			cmp dword ptr ss:[ebp-0x18], -1
			jne not_reject

			jmp #L(return)

			not_reject:
		]]},
	}))

	-- CGameArea::OnFormationButtonDown() - Reject world coordinates (-1, -1) when handling right click
	IEex_HookJump(0x487858, 3, IEex_FlattenTable({
		{[[
			cmp dword ptr ss:[ebp-0x14], -1
			jne not_reject

			cmp dword ptr ss:[ebp-0x10], -1
			jne not_reject

			jmp #L(jmp_success)

			not_reject:
		]]},
	}))

	-- CGameArea::OnMouseMove() - Handle edge scrolling at new resolution / the ui blocking the cursor
	IEex_JITAt(0x487C4E, {[[
		jmp #L(EnhancedWidescreen_Override_CGameArea::OnMouseMove)
		nop
	]]})

	-- CInfinity::GetWorldCoordinates() - Return -1, -1 when UI is between cursor and world
	IEex_HookReplaceFunctionMaintainOriginal(0x5B52E7, 6, "Original_CInfinity::GetWorldCoordinates", {[[
		jmp #L(EnhancedWidescreen_Override_CInfinity::GetWorldCoordinates)
		nop
	]]})

	-- CGameArea::OnFormationButtonUp() - Restore original CInfinity::GetWorldCoordinates() call
	-- so that the UI doesn't interfere with rotating the group formation
	IEex_JITAt(0x487A2E, {"call #L(Original_CInfinity::GetWorldCoordinates) #ENDL"})

	-----------------------------------------------------------------------------------
	-- Viewport should be able to scroll out of bounds to expose world under the GUI --
	-----------------------------------------------------------------------------------

	-- CGameArea::AIUpdate() - Carefully replace the code that handles updating cursor
	-- scrolling when the viewport can't move in the current direction anymore
	IEex_JITAt(0x47BC53, {[[
		push eax
		push ecx
		push edx
		push dword ptr ss:[ebp-0x22C]
		call #L(EnhancedWidescreen_Patch_CGameArea::AIUpdate()_CheckCursorScroll)
		pop edx
		pop ecx
		pop eax
		jmp 0x47BFEC
		#REPEAT(899,nop #ENDL)
	]]})

	-- CInfinity::SetViewPosition() - Override to implement new bounds checking
	IEex_JITAt(0x5BB371, {"jmp #L(EnhancedWidescreen_Override_CInfinity::SetViewPosition) #ENDL"})

	-- CInfinity::Render() - Calculate left-most visible tile via floor division instead of truncation
	IEex_JITAt(0x5B85B8, {[[
		push 64
		push eax
		call #L(EnhancedWidescreen_DivFloor)
		#REPEAT(1,nop #ENDL)
	]]})

	-- CInfinity::Render() - Calculate left-most visible tile via floor division instead of truncation
	IEex_JITAt(0x5B85D9, {[[
		push 64
		push eax
		call #L(EnhancedWidescreen_DivFloor)
		#REPEAT(1,nop #ENDL)
	]]})

	-- CInfinity::Render() - Calculate surface x offset via negative-correcting modulo
	IEex_JITAt(0x5B85FA, {[[
		push 64
		push eax
		call #L(EnhancedWidescreen_Modulo)
		mov ecx, eax
		#REPEAT(9,nop #ENDL)
	]]})

	-- CInfinity::Render() - Calculate surface y offset via negative-correcting modulo
	IEex_JITAt(0x5B8625, {[[
		push 64
		push ecx
		call #L(EnhancedWidescreen_Modulo)
		mov edx, eax
		#REPEAT(10,nop #ENDL)
	]]})

	-- CInfinity::Render() - Disable tile request routine that uses the scroll state (it can't handle negative coords)
	IEex_ForceJump(0x5B87F0)

	-- CInfinity::Render() - Tiles rendered at negative coordinates, and
	-- coordinates that exceed the WED's data should be drawn as black
	IEex_HookBeforeAndAfterCall(0x5B8B5A,
		{[[
			cmp dword ptr ss:[esp+0x4], 0
			jl render_as_black

			cmp dword ptr ss:[esp+0x8], 0
			jl render_as_black

			jmp do_call

			render_as_black:
			add esp, 0xC
			jmp 0x5B8F93

			do_call:
		]]},
		{[[
			test eax, eax
			jz 0x5B8F93
		]]}
	)

	-- DEBUG: Render out-of-bounds in magenta
	--IEex_WriteU32(0x5B1469, 0xFF00FF)

	---------------------------------------------------------------------------------
	-- Blank the back buffer after switching engines (or on starting CCacheStatus) --
	-- so that left-over junk isn't rendered                                       --
	---------------------------------------------------------------------------------

	-- Blank back buffer after switching engines
	IEex_HookBeforeRestore(0x79334F, 0, 6, 6, {[[
		push ecx
		push edx
		push ecx ; parameter
		call #L(EnhancedWidescreen_BlankBackBuffer)
		pop edx
		pop ecx
	]]})

	-- Blank back buffer when a loading screen starts
	IEex_HookBeforeRestore(0x44F813, 0, 9, 9, {[[
		push eax
		push ecx
		push edx
		call #L(EnhancedWidescreen_BlankCCache1)
		pop edx
		pop ecx
		pop eax
	]]})

	-- Blank back buffer after first loading screen flip
	IEex_HookAfterRestore(0x4545B8, 0, 7, 9, {[[
		jz #L(return)
		push eax
		push ecx
		push edx
		call #L(EnhancedWidescreen_BlankCCache2)
		pop edx
		pop ecx
		pop eax
		jmp 0x4545D4
	]]})

	-- Blank back buffer after the engine renders the world for a save slot BMP
	IEex_HookAfterRestore(0x5920DC, 0, 6, 6, {[[
		call #L(EnhancedWidescreen_BlankCCache3)
	]]})

	---------------------------------------
	-- Center the loading screen mosaics --
	---------------------------------------

	local shimMosaicRender = function(address)
		IEex_HookNOPs(address, 0, {[[
			push ecx
			call #L(EnhancedWidescreen_CCacheStatusShimMosaicRender)
			jmp #L(return)
		]]})
	end

	shimMosaicRender(0x452A0F)
	shimMosaicRender(0x452C85)
	shimMosaicRender(0x45378C)
	shimMosaicRender(0x45392C)
	shimMosaicRender(0x453964)
	shimMosaicRender(0x453B1C)
	shimMosaicRender(0x453D15)
	shimMosaicRender(0x453FF7)
	shimMosaicRender(0x454145)
	shimMosaicRender(0x454173)
	shimMosaicRender(0x4541D3)
	shimMosaicRender(0x4542DB)

	------------------------------------
	-- Center the loading screen text --
	------------------------------------

	local shimFontRender = function(address)
		IEex_HookNOPs(address, 0, {[[
			push ecx
			call #L(EnhancedWidescreen_CCacheStatusShimFontRender)
			jmp #L(return)
		]]})
	end

	shimFontRender(0x452B2E)
	shimFontRender(0x452F22)
	shimFontRender(0x452F60)
	shimFontRender(0x4532A1)
	shimFontRender(0x453339)
	shimFontRender(0x4533B6)
	shimFontRender(0x453E9E)
	shimFontRender(0x4543DE)

	------------------------------------------------------
	-- Autoscroll in relation to the main viewport rect --
	------------------------------------------------------

	IEex_HookBeforeRestore(0x66B0B2, 0, 6, 6, IEex_FlattenTable({
		{[[
			push ecx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_GUI_Extern_AdjustAutoScrollDest", {
			["args"] = {
				{"push dword ptr ss:[ebp+0x0C] #ENDL"},                                      -- retPtr | Note: Fragile stack access
				{"lea eax, dword ptr ss:[ebp+0x10] #ENDL push eax #ENDL", "Primitive<int>"}, -- x      | Note: Fragile stack access
				{"lea eax, dword ptr ss:[ebp+0x14] #ENDL push eax #ENDL", "Primitive<int>"}, -- y      | Note: Fragile stack access
				{"lea eax, dword ptr ss:[ebp+0x18] #ENDL push eax #ENDL", "Primitive<int>"}, -- speed  | Note: Fragile stack access
			},
		}),
		{[[
			call_error:
			pop ecx
		]]},
	}))

	------------------------------------------------------------------
	-- Make the local map only consider the in-bounds viewport rect --
	------------------------------------------------------------------

	IEex_HookBeforeCall(0x622A68, IEex_FlattenTable({
		{[[
			push ecx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_GUI_Extern_AdjustLocalMapViewPosition", {
			["args"] = {
				{"push dword ptr ss:[ebp+0x20] #ENDL", "CUIControlButtonMap"}, -- Note: Fragile stack access
			},
		}),
		{[[
			call_error:
			pop ecx
		]]},
	}))

	IEex_HookBeforeCall(0x620532, IEex_FlattenTable({
		{[[
			push ecx
		]]},
		IEex_GenLuaCall("EnhancedWidescreen_GUI_Extern_AdjustLocalMapSetViewPosition", {
			["args"] = {
				{"lea eax, dword ptr ss:[ebp+0xC]  #ENDL push eax #ENDL", "Primitive<int>"}, -- x | Note: Fragile stack access
				{"lea eax, dword ptr ss:[ebp+0x10] #ENDL push eax #ENDL", "Primitive<int>"}, -- y | Note: Fragile stack access
			},
		}),
		{[[
			call_error:
			pop ecx
		]]},
	}))

	----------------------------------------------------------
	-- Allow loading out-of-bounds view positions from .GAM --
	----------------------------------------------------------

	-- Read view position coordinates as signed
	IEex_JITAt(0x6F49AD, {"movsx edx, word ptr ds:[ecx+0x26]"})
	IEex_JITAt(0x6F49B7, {"movsx ecx, word ptr ds:[eax+0x24]"})

	-- Ignore bounds when loading view position from .GAM
	IEex_JITAt(0x6F49C5, {"call #L(EnhancedWidescreen_CInfinity::SetViewPositionIgnoreBounds)"})

	---------------------------------------------------------
	-- Center the viewport based on the main viewport rect --
	---------------------------------------------------------

	local setViewPositionAdjustToCenter = function(address)
		IEex_JITAt(address, {"call #L(EnhancedWidescreen_CInfinity::SetViewPositionAdjustToCenter)"})
	end

	-- CGameArea::OnActionButtonDblClk()
	setViewPositionAdjustToCenter(0x4877F6)

	-- CInfGame::CenterOnCharacterInPortraitIndex()
	setViewPositionAdjustToCenter(0x597297)

	-- CInfGame::SetupCharacters()
	setViewPositionAdjustToCenter(0x5A3C09)

	-- CInfGame::LeaveAreaLuaMultiplayer()
	setViewPositionAdjustToCenter(0x5A9BD0)
	setViewPositionAdjustToCenter(0x5A9CC9)

	-- CInfGame::LeaveAreaNameMultiplayer()
	setViewPositionAdjustToCenter(0x5AB795)
	setViewPositionAdjustToCenter(0x5AB81F)

	-- CScreenWorldMap::EnterArea()
	setViewPositionAdjustToCenter(0x6874ED)
	setViewPositionAdjustToCenter(0x68756C)

	-- CGameSprite::LeaveAreaLUA()
	setViewPositionAdjustToCenter(0x73D565)
	setViewPositionAdjustToCenter(0x73D661)

	-- CGameSprite::LeaveAreaName()
	setViewPositionAdjustToCenter(0x74005F)
	setViewPositionAdjustToCenter(0x7400E9)

--////////////////
--// Resolution //
--////////////////

	-----------
	-- Width --
	-----------

	-- CBaldurProjector::EngineActivated()
	IEex_WriteU32(0x44E9DB, EnhancedWidescreen_GUI_ResolutionWidth)
	IEex_WriteU32(0x44E9E4, EnhancedWidescreen_GUI_ResolutionWidth)

	-- OptionsScreenSliderThing()
	IEex_WriteU32(0x4E2AD4, EnhancedWidescreen_GUI_ResolutionWidth)

	-- TextFieldThing()
	IEex_WriteU32(0x4E584B, EnhancedWidescreen_GUI_ResolutionWidth)
	IEex_WriteU32(0x4E5996, EnhancedWidescreen_GUI_ResolutionWidth)
	IEex_WriteU32(0x4E5AA0, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CInfinity::FXRenderClippingPolys() - Strangely, updating these constants breaks dithering
	--IEex_WriteU32(0x5B655C, EnhancedWidescreen_GUI_ResolutionWidth)
	--IEex_WriteU32(0x5B6573, EnhancedWidescreen_GUI_ResolutionWidth)
	--IEex_WriteU32(0x5B65EA, EnhancedWidescreen_GUI_ResolutionWidth)
	--IEex_WriteU32(0x5B6612, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CUnknownEngine2::TimerSynchronousUpdate()
	IEex_WriteU32(0x5BE54F, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode::GetResolution()
	IEex_WriteU32(0x79C54D, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode0::Select()
	IEex_WriteU32(0x79DA74, EnhancedWidescreen_GUI_ResolutionWidth)
	IEex_WriteU32(0x79DAED, EnhancedWidescreen_GUI_ResolutionWidth)
	IEex_WriteU32(0x79DBC3, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode0::SetupTexSurfaces()
	IEex_WriteU32(0x79DF6A, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode0::FlipBuffersWindowed()
	IEex_WriteU32(0x79F0BB, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode0::Screenshot()
	IEex_WriteU32(0x79FABD, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode0::RenderCursorToSurface()
	IEex_WriteU32(0x7A0C4D, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode2::Select()
	IEex_WriteU32(0x7A1764, EnhancedWidescreen_GUI_ResolutionWidth)

	-- CVidMode1::Select()
	IEex_WriteU32(0x7A1889, EnhancedWidescreen_GUI_ResolutionWidth)

	------------
	-- Height --
	------------

	-- CBaldurProjector::EngineActivated()
	IEex_WriteU32(0x44E98C, EnhancedWidescreen_GUI_ResolutionHeight)

	-- OptionsScreenSliderThing()
	IEex_WriteU32(0x4E2ADB, EnhancedWidescreen_GUI_ResolutionHeight)

	-- TextFieldThing()
	IEex_WriteU32(0x4E5855, EnhancedWidescreen_GUI_ResolutionHeight)
	IEex_WriteU32(0x4E59A0, EnhancedWidescreen_GUI_ResolutionHeight)
	IEex_WriteU32(0x4E5AAA, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CInfinity::FXRenderClippingPolys() - Strangely, updating these constants breaks dithering
	--IEex_WriteU32(0x5B6594, EnhancedWidescreen_GUI_ResolutionHeight)
	--IEex_WriteU32(0x5B65AB, EnhancedWidescreen_GUI_ResolutionHeight)
	--IEex_WriteU32(0x5B65FE, EnhancedWidescreen_GUI_ResolutionHeight)
	--IEex_WriteU32(0x5B6626, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CUnknownEngine2::TimerSynchronousUpdate()
	IEex_WriteU32(0x5BE556, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode::GetResolution()
	IEex_WriteU32(0x79C556, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode0::Select()
	IEex_WriteU32(0x79DA6F, EnhancedWidescreen_GUI_ResolutionHeight)
	IEex_WriteU32(0x79DAE8, EnhancedWidescreen_GUI_ResolutionHeight)
	IEex_WriteU32(0x79DBBE, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode0::SetupTexSurfaces()
	IEex_WriteU32(0x79DF71, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode0::FlipBuffersWindowed()
	IEex_WriteU32(0x79F0C2, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode0::Screenshot()
	IEex_WriteU32(0x79FAC7, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode0::RenderCursorToSurface()
	IEex_WriteU32(0x7A0C54, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode2::Select()
	IEex_WriteU32(0x7A175F, EnhancedWidescreen_GUI_ResolutionHeight)

	-- CVidMode1::Select()
	IEex_WriteU32(0x7A1884, EnhancedWidescreen_GUI_ResolutionHeight)

	-----------------------------------------------------------------------
	-- Fix arbitrary surface resolutions crashing the screenshot routine --
	-----------------------------------------------------------------------

	IEex_JITAt(0x79FC9D, {[[
		jmp #L(EnhancedWidescreen_Override_CVidMode0::ConvertSurfaceToBmp)
	]]})

--//////////////
--// Viewport //
--//////////////

	--------------------------
	-- CGameArea::Unmarshal --
	--------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x483110, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x48311A, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x483124, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x48312E, EnhancedWidescreen_GUI_ViewportBottom)

	----------------------------------
	-- CMessageEnterDialogMode::Run --
	----------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 198]
	IEex_WriteU32(0x504BA7, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x504BAE, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x504BB5, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x504BBC, EnhancedWidescreen_GUI_ViewportBottom)

	--------------------------------------------------------------
	-- DynamicInitializer_WorldScreenViewPortRectForSavePicture --
	--------------------------------------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x5B2449,  64 + EnhancedWidescreen_GUI_ViewportAdditionalWidth  / 2)
	IEex_WriteU32(0x5B2450,   6 + EnhancedWidescreen_GUI_ViewportAdditionalHeight / 2)
	IEex_WriteU32(0x5B2457, 576 + EnhancedWidescreen_GUI_ViewportAdditionalWidth  / 2)
	IEex_WriteU32(0x5B245E, 390 + EnhancedWidescreen_GUI_ViewportAdditionalHeight / 2)

	----------------------------------------------------
	-- CInfGame::LeaveAreaLuaMultiplayer [Check Only] --
	----------------------------------------------------

	--0x5A9B67

	-----------------------------------------------------
	-- CInfGame::LeaveAreaNameMultiplayer [Check Only] --
	-----------------------------------------------------

	--0x5AB727

	-----------------------------
	-- CScreenWorld::Construct --
	-----------------------------

	-- Default - [left: 0, top: 0, right: 1, bottom: 1]
	--0x662975

	----------------------------------
	-- CScreenWorld::EngineGameInit --
	----------------------------------

	-- Default - [left: 0, top: 0, right: 1, bottom: 1]
	--0x663445

	---------------------------------------------------
	-- CScreenWorld::AsynchronousUpdate [Check Only] --
	---------------------------------------------------

	--0x66C0BB
	--0x66C0F6

	-------------------------------
	-- CScreenWorld::StartDialog --
	-------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 198]
	IEex_WriteU32(0x66F8EC, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x66F8F3, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x66F8FA, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x66F901, EnhancedWidescreen_GUI_ViewportBottom)

	-----------------------------
	-- CScreenWorld::EndDialog --
	-----------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x6707FD, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x670807, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x670811, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x670818, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x67093B, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x670945, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x67094F, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x670959, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 198]
	IEex_WriteU32(0x670A61, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x670A6B, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x670A75, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x670A7F, EnhancedWidescreen_GUI_ViewportBottom)

	---------------------------------
	-- CScreenWorld::StopContainer --
	---------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x67217F, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x672186, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x67218D, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x672194, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x6722D8, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x6722DF, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x6722E6, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x6722ED, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 198]
	IEex_WriteU32(0x67241B, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x672422, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x672429, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x672430, EnhancedWidescreen_GUI_ViewportBottom)

	-------------------------------
	-- CScreenWorld::DisplayText --
	-------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x6764CF, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x6764D6, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x6764DD, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x6764E4, EnhancedWidescreen_GUI_ViewportBottom)

	-------------------------------
	-- CScreenWorld::DisplayText --
	-------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x676689, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x676690, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x676697, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x67669E, EnhancedWidescreen_GUI_ViewportBottom)

	----------------------------------
	-- CScreenWorld::StartPickParty --
	----------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 370]
	IEex_WriteU32(0x676CC2, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x676CC9, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x676CD0, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x676CD7, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 234]
	IEex_WriteU32(0x676D34, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x676D3B, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x676D42, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x676D49, EnhancedWidescreen_GUI_ViewportBottom)

	---------------------------------
	-- CScreenWorld::StopPickParty --
	---------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x6775F4, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x6775FB, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x677602, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x677609, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x677720, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x677727, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x67772E, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x677735, EnhancedWidescreen_GUI_ViewportBottom)

	-- Default - [left: 64, top: 6, right: 576, bottom: 198]
	IEex_WriteU32(0x677848, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x67784F, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x677856, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x67785D, EnhancedWidescreen_GUI_ViewportBottom)

	------------------------------
	-- CScreenWorld::StartDeath --
	------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 341]
	IEex_WriteU32(0x677AF0, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x677AF7, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x677AFE, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x677B05, EnhancedWidescreen_GUI_ViewportBottom)

	-----------------------------
	-- CScreenWorld::StartChat --
	-----------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x67A5BD, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x67A5C4, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x67A5CB, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x67A5D2, EnhancedWidescreen_GUI_ViewportBottom)

	---------------------------------------------
	-- CScreenWorldMap::EnterArea [Check Only] --
	---------------------------------------------

	--0x68747F

	--------------------------------------------
	-- CGameSprite::LeaveAreaLUA [Check Only] --
	--------------------------------------------

	--0x73D4FC

	---------------------------------------------
	-- CGameSprite::LeaveAreaName [Check Only] --
	---------------------------------------------

	--0x73FFF1

	-------------------------------
	-- CGameSprite::UseContainer --
	-------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x74A132, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x74A139, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x74A140, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x74A147, EnhancedWidescreen_GUI_ViewportBottom)

	----------------------------------------------
	-- CUIControlTextDisplayCombatLog::Unknown1 --
	----------------------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x772C1C, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x772C23, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x772C2A, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x772C31, EnhancedWidescreen_GUI_ViewportBottom)

	-----------------------------------------------------------------
	-- CUIControlButtonMediumCombatLogExpandButton::OnLButtonClick --
	-----------------------------------------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 198]
	IEex_WriteU32(0x772EDC, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x772EE3, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x772EEA, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x772EF1, EnhancedWidescreen_GUI_ViewportBottom)

	----------------------------------------------
	-- CUIControlTextDisplayCombatLog::Unknown2 --
	----------------------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 326]
	IEex_WriteU32(0x773171, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x773178, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x77317F, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x773186, EnhancedWidescreen_GUI_ViewportBottom)

	-----------------------------------------------------------------
	-- CUIControlButtonMediumCombatLogShrinkButton::OnLButtonClick --
	-----------------------------------------------------------------

	-- Default - [left: 64, top: 6, right: 576, bottom: 390]
	IEex_WriteU32(0x7733C0, EnhancedWidescreen_GUI_ViewportLeft)
	IEex_WriteU32(0x7733C7, EnhancedWidescreen_GUI_ViewportTop)
	IEex_WriteU32(0x7733CE, EnhancedWidescreen_GUI_ViewportRight)
	IEex_WriteU32(0x7733D5, EnhancedWidescreen_GUI_ViewportBottom)

IEex_EnableCodeProtection()

------------
-- .rdata --
------------

--////////////////
--// Resolution //
--////////////////

	IEex_SetSegmentProtection(".rdata", 0x4) -- PAGE_READWRITE

	-- Patch Width
	IEex_WriteU16(0x84288E, EnhancedWidescreen_GUI_ResolutionWidth)

	-- Patch Height
	IEex_WriteU16(0x842890, EnhancedWidescreen_GUI_ResolutionHeight)

	IEex_SetSegmentProtection(".rdata", 0x2) -- PAGE_READONLY
