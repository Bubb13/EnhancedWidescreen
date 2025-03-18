
EnhancedWidescreen_Resource_FileExtensionToTypeT = {
	["2DA"] = 0x3F4, -- CResText     (0x85DB90)
	["ARE"] = 0x3F2, -- CResArea     (0x847688)
	["BAM"] = 0x3E8, -- CResCell     (0x85DB00)
	["BCS"] = 0x3EF, -- CResText     (0x85DB90)
	["BMP"] = 0x001, -- CResBitmap   (0x85DAB8)
	[ "BS"] = 0x3F9, -- CResText     (0x85DB90)
	["CHR"] = 0x3FA, -- CResCHR      (0x847664)
	["CHU"] = 0x3EA, -- CResUI       (0x8475D4)
	["CRE"] = 0x3F1, -- CResCRE      (0x847640)
	["DLG"] = 0x3F3, -- CResDLG      (0x8476F4)
	["EFF"] = 0x3F8, -- CResEffect   (0x84773C)
	["GAM"] = 0x3F5, -- CResGame     (0x8476AC)
	["IDS"] = 0x3F0, -- CResText     (0x85DB90)
	["ITM"] = 0x3ED, -- CResItem     (0x8475F8)
	["MOS"] = 0x3EC, -- CResMosaic   (0x85DB48)
	["MVE"] = 0x002, -- CRes         (0x85DA70)
	["SPL"] = 0x3EE, -- CResSpell    (0x84761C)
	["STO"] = 0x3F6, -- CResStore    (0x8476D0)
	["TIS"] = 0x3EB, -- CResTileSet  (0x85DB6C)
	["WAV"] = 0x004, -- CResWave     (0x85DA94)
	["WED"] = 0x3E9, -- CResWED      (0x8475B0)
	["WMP"] = 0x3F7, -- CResWorldMap (0x847718)
}

function EnhancedWidescreen_Resource_FileExtensionToType(extension)
	return EnhancedWidescreen_Resource_FileExtensionToTypeT[extension:upper()]
end

EnhancedWidescreen_Resource_FileTypeToExtensionT = {
	[0x3F4] = "2DA", -- CResText     (0x85DB90)
	[0x3F2] = "ARE", -- CResArea     (0x847688)
	[0x3E8] = "BAM", -- CResCell     (0x85DB00)
	[0x3EF] = "BCS", -- CResText     (0x85DB90)
	[0x001] = "BMP", -- CResBitmap   (0x85DAB8)
	[0x3F9] =  "BS", -- CResText     (0x85DB90)
	[0x3FA] = "CHR", -- CResCHR      (0x847664)
	[0x3EA] = "CHU", -- CResUI       (0x8475D4)
	[0x3F1] = "CRE", -- CResCRE      (0x847640)
	[0x3F3] = "DLG", -- CResDLG      (0x8476F4)
	[0x3F8] = "EFF", -- CResEffect   (0x84773C)
	[0x3F5] = "GAM", -- CResGame     (0x8476AC)
	[0x3F0] = "IDS", -- CResText     (0x85DB90)
	[0x3ED] = "ITM", -- CResItem     (0x8475F8)
	[0x3EC] = "MOS", -- CResMosaic   (0x85DB48)
	[0x002] = "MVE", -- CRes         (0x85DA70)
	[0x3EE] = "SPL", -- CResSpell    (0x84761C)
	[0x3F6] = "STO", -- CResStore    (0x8476D0)
	[0x3EB] = "TIS", -- CResTileSet  (0x85DB6C)
	[0x004] = "WAV", -- CResWave     (0x85DA94)
	[0x3E9] = "WED", -- CResWED      (0x8475B0)
	[0x3F7] = "WMP", -- CResWorldMap (0x847718)
}

function EnhancedWidescreen_Resource_FileTypeToExtension(fileType)
	return EnhancedWidescreen_Resource_FileTypeToExtensionT[fileType]
end

EnhancedWidescreen_Resource_TypeBuckets = {}

function EnhancedWidescreen_Resource_IndexResources()

	EnhancedWidescreen_Resource_TypeBuckets = {}

	local hashTable = EngineGlobals.g_pBaldurChitin.m_resourceManager.m_hashTable
	local hashEntries = hashTable.m_pHashEntries

	for i = 0, hashTable.m_nHashTableSize - 1 do

		local hashEntry = hashEntries:getReference(i)
		local resref = hashEntry.m_resref:get()

		if resref ~= "" then

			local fileType = hashEntry.m_nFileType
			local bucket = EnhancedWidescreen_Resource_TypeBuckets[fileType]

			if bucket == nil then
				bucket = {}
				EnhancedWidescreen_Resource_TypeBuckets[fileType] = bucket
			end

			table.insert(bucket, resref)
		end
	end

	for _, bucket in pairs(EnhancedWidescreen_Resource_TypeBuckets) do
		table.sort(bucket)
	end
end

function EnhancedWidescreen_Resource_ResRefsOfType(fileType)
	return EnhancedWidescreen_Resource_TypeBuckets[fileType] or {}
end

function EnhancedWidescreen_Resource_ResRefsOfExtension(extension)
	local fileType = EnhancedWidescreen_Resource_FileExtensionToType(extension)
	return EnhancedWidescreen_Resource_ResRefsOfType(fileType)
end

----------------------------------------------------
-- /START/ EnhancedWidescreen_Resource_ResWrapper --
----------------------------------------------------

EnhancedWidescreen_Resource_ResWrapper = {}
EnhancedWidescreen_Resource_ResWrapper.__index = EnhancedWidescreen_Resource_ResWrapper

function EnhancedWidescreen_Resource_ResWrapper:free()
	local res = self._res
	if res == nil then return end
	self._res = nil
	self._data = nil
	res:DecrementDemands()
	res:DecrementRequests()
	EngineGlobals.g_pBaldurChitin.m_resourceManager:DumpResObject(res)
end

function EnhancedWidescreen_Resource_ResWrapper:getData()
	return self._data
end

function EnhancedWidescreen_Resource_ResWrapper:getRawData()
	return IEex_UDToPtr(self._res.m_pViewBase)
end

function EnhancedWidescreen_Resource_ResWrapper:getRes()
	return self._res
end

function EnhancedWidescreen_Resource_ResWrapper:new(res, dataUD)
	local o = { ["_res"] = res, ["_data"] = dataUD }
	setmetatable(o, self)
	return o
end

--------------------------------------------------
-- /END/ EnhancedWidescreen_Resource_ResWrapper --
--------------------------------------------------

EnhancedWidescreen_Resource_FileTypeToUserType = {
	[0x3EA] = "CResUI", -- CHU
	[0x3EC] = "CResMosaic", -- MOS
}

function EnhancedWidescreen_Resource_Demand(resref, extension)

	local res
	local resourceManager = EngineGlobals.g_pBaldurChitin.m_resourceManager
	local fileType = EnhancedWidescreen_Resource_FileExtensionToType(extension)

	IEex_RunWithStack(CResRef.sizeof, function(esp)
		local resrefUD = IEex_PtrToUD(esp, "CResRef")
		resrefUD:set(resref)
		res = resourceManager:GetResObject(resrefUD, fileType)
	end)

	if res == nil then
		return nil
	end

	local castUserType = EnhancedWidescreen_Resource_FileTypeToUserType[fileType]
	if castUserType ~= nil then
		res = IEex_CastUD(res, castUserType)
	end

	res:Request()
	local data = res:Demand()

	if data == nil then
		res:DecrementDemands()
		res:DecrementRequests()
		resourceManager:DumpResObject(res)
		return nil
	end

	return EnhancedWidescreen_Resource_ResWrapper:new(res, data)
end
