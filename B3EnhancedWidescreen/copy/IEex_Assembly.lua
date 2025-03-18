
-- This file needs to be called by both IEex_EarlyMain.lua and
-- IEex_Main.lua. This guard prevents the file from being
-- needlessly processed twice.
if IEex_Assembly_AlreadyLoaded then
	return
end
IEex_Assembly_AlreadyLoaded = true

-- LuaJIT compatibility
if not table.pack then
	table.pack = function(...)
		local t = {...}
		t.n = #t
		return t
	end
	table.unpack = unpack
end

------------------
-- Bits Utility --
------------------

function IEex_AreBitsSet(original, bitsString)
	return IEex_IsMaskSet(original, tonumber(bitsString, 2))
end

function IEex_AreBitsUnset(original, bitsString)
	return IEex_IsMaskUnset(original, tonumber(bitsString, 2))
end

function IEex_Flags(flags)
	local result = 0x0
	for _, flag in ipairs(flags) do
		result = IEex_BOr(result, flag)
	end
	return result
end

function IEex_IsBitSet(original, isSetIndex)
	return IEex_BAnd(original, IEex_LShift(0x1, isSetIndex)) ~= 0x0
end

function IEex_IsBitUnset(original, isUnsetIndex)
	return IEex_BAnd(original, IEex_LShift(0x1, isUnsetIndex)) == 0x0
end

function IEex_IsMaskSet(original, isSetMask)
	return IEex_BAnd(original, isSetMask) == isSetMask
end

function IEex_IsMaskUnset(original, isUnsetMask)
	return IEex_BAnd(original, isUnsetMask) == 0x0
end

function IEex_SetBit(original, toSetIndex)
	return IEex_BOr(original, IEex_LShift(0x1, toSetIndex))
end

function IEex_SetBits(original, bitsString)
	return IEex_SetMask(original, tonumber(bitsString, 2))
end

function IEex_SetMask(original, toSetMask)
	return IEex_BOr(original, toSetMask)
end

-- Warning: Don't use this with negative numbers in anything critical!
-- Lua's precision breaks down when RShifting near-max 64bit values.
-- If you need to convert a 64bit integer to a string, use
-- IEex_ToDecStr(), which is written in C++.
function IEex_ToHex(number, minLength, suppressPrefix)

	if type(number) ~= "number" then
		-- This is usually a critical error somewhere else in the code, so throw a fully fledged error.
		IEex_Error("Passed a NaN value: '"..tostring(number).."'!")
	end

	-- string.format() can't handle "negative" numbers, and bit32 can't handle 64bits, (obviously).
	local hexString = ""
	while number ~= 0x0 do
		hexString = string.format("%x", IEex_Extract(number, 0, 4)):upper()..hexString
		number = IEex_RShift(number, 4)
	end

	local wantedLength = (minLength or 1) - #hexString
	for i = 1, wantedLength, 1 do
		hexString = "0"..hexString
	end

	return suppressPrefix and hexString or "0x"..hexString
end

function IEex_UnsetBit(original, toUnsetIndex)
	return IEex_BAnd(original, IEex_BNot(IEex_LShift(0x1, toUnsetIndex)))
end

function IEex_UnsetBits(original, bitsString)
	return IEex_UnsetMask(original, tonumber(bitsString, 2))
end

function IEex_UnsetMask(original, toUnsetmask)
	return IEex_BAnd(original, IEex_BNot(toUnsetmask))
end

-------------------
-- Debug Utility --
-------------------

-- Throws a Lua error, appending the current stacktrace to the end of the message.
function IEex_Error(message)
	error(debug.traceback("[!] "..message))
end

-- Logs a message to the console window, prepending the message with the calling function's name.
function IEex_FunctionLog(message)
	local name = debug.getinfo(2, "n").name
	if name == nil then name = "(Unknown)" end
	print("[IEex] "..name..": "..message)
end

-- Displays a message box to the user. Note: Suspends game until closed, which can be useful for debugging.
function IEex_MessageBox(message, iconOverride)
	IEex_MessageBoxInternal(message, iconOverride and iconOverride or 0x40)
end

function IEex_TracebackMessage(message, levelMod)
	local message = debug.traceback(message, 2 + (levelMod or 0))
	print(message)
	IEex_MessageBox(message)
end

function IEex_TracebackPrint(message, levelMod)
	print(debug.traceback(message, 2 + (levelMod or 0)))
end

---------------------
-- General Utility --
---------------------

function IEex_DistanceToMultiple(numToRound, multiple)
	if multiple == 0 then return 0 end
	local remainder = numToRound % multiple
	if remainder == 0 then return 0 end
	return multiple - remainder
end

IEex_OnceTable = {}

function IEex_Once(key, func)
	if not IEex_OnceTable[key] then
		IEex_OnceTable[key] = true
		func()
	end
end

-- Rounds the given number upwards to the nearest multiple.
function IEex_RoundUp(numToRound, multiple)
	if multiple == 0 then return numToRound end
	local remainder = numToRound % multiple
	if remainder == 0 then return numToRound end
	return numToRound + multiple - remainder
end

---------
-- JIT --
---------

IEex_CodePageAllocations = {}

function IEex_AllocCodePage()
	local address, size = IEex_AllocCodePageInternal()
	local initialEntry = {}
	initialEntry.address = address
	initialEntry.size = size
	initialEntry.reserved = false
	local codePageEntry = {initialEntry}
	table.insert(IEex_CodePageAllocations, codePageEntry)
	return codePageEntry
end

function IEex_JITAt(dst, assemblyT)
	local assemblyStr = IEex_PreprocessAssembly(assemblyT)
	local checkJIT = function(writeSize) return 0 end
	IEex_JITAtInternal(dst, checkJIT, assemblyStr)
end

function IEex_JITNear(assemblyT)

	local stackMod = IEex_TryLabel("stack_mod")
	if stackMod then
		assemblyT = IEex_FlattenTable({
			{"#STACK_MOD(#$(1)) #ENDL", {stackMod}},
			assemblyT,
		})
	end

	local assemblyStr = IEex_PreprocessAssembly(assemblyT)

	local finalWriteSize
	local currentCodePageI = 0
	local currentAllocEntryI = 1
	local alreadyAllocatedCodePage = false

	local getOrCreateAllocEntryIterate = function(func)
		local curCodePage
		repeat
			curCodePage = IEex_CodePageAllocations[currentCodePageI]
			if curCodePage and currentAllocEntryI < #curCodePage then
				currentAllocEntryI = currentAllocEntryI + 1
			else
				currentCodePageI = currentCodePageI + 1
				curCodePage = IEex_CodePageAllocations[currentCodePageI]
				if not curCodePage then
					if alreadyAllocatedCodePage then return true end
					alreadyAllocatedCodePage = true
					curCodePage = IEex_AllocCodePage()
				end
				currentAllocEntryI = 1
			end
		until func(curCodePage[currentAllocEntryI])
	end

	local checkJIT = function(writeSize)
		local checkEntry = IEex_CodePageAllocations[currentCodePageI][currentAllocEntryI]
		if writeSize > checkEntry.size then
			local newDst
			failed = getOrCreateAllocEntryIterate(function(allocEntry)
				if allocEntry.reserved then return end
				newDst = allocEntry.address
				return true
			end)
			return failed and -1 or newDst
		end
		finalWriteSize = writeSize
		return 0
	end

	local finalAllocEntry
	getOrCreateAllocEntryIterate(function(firstAllocEntry)

		if firstAllocEntry.reserved then return end
		IEex_JITAtInternal(firstAllocEntry.address, checkJIT, assemblyStr)
		if not finalWriteSize then
			IEex_Error("Failed to allocate memory for IEex_JITNear().")
		end

		local finalCodePage = IEex_CodePageAllocations[currentCodePageI]
		finalAllocEntry = finalCodePage[currentAllocEntryI]

		local memLeftOver = finalAllocEntry.size - finalWriteSize
		if memLeftOver > 0 then
			local newAddress = finalAllocEntry.address + finalWriteSize
			local nextEntry = finalCodePage[currentAllocEntryI + 1]
			if nextEntry then
				if not nextEntry.reserved then
					local addressDifference = nextEntry.address - newAddress
					nextEntry.address = newAddress
					nextEntry.size = finalAllocEntry.size + addressDifference
				else
					local newEntry = {}
					newEntry.address = newAddress
					newEntry.size = memLeftOver
					newEntry.reserved = false
					table.insert(finalCodePage, newEntry, currentAllocEntryI + 1)
				end
			else
				local newEntry = {}
				newEntry.address = newAddress
				newEntry.size = memLeftOver
				newEntry.reserved = false
				table.insert(finalCodePage, newEntry)
			end
		end
		finalAllocEntry.size = finalWriteSize
		finalAllocEntry.reserved = true
		return true
	end)

	return finalAllocEntry.address
end

function IEex_JITNearAsLuaFunction(luaFunctionName, assemblyT)
	local address = IEex_JITNear(assemblyT)
	IEex_ExposeToLua(address, luaFunctionName)
	return address
end

function IEex_JITNearAsLabel(label, assemblyT)
	IEex_DefineAssemblyLabel(label, IEex_JITNear(assemblyT))
end

IEex_DebugPreprocessAssembly = false

function IEex_PreprocessAssembly(assemblyT, state)

	local builtStr = {}
	local insertI = 1

	local len = #assemblyT
	local i = 1
	while i <= len do
		local v = assemblyT[i]
		local vtype = type(v)
		local advanceCount = 1
		if vtype == "string" then
			builtStr[insertI], advanceCount = IEex_PreprocessAssemblyStr(assemblyT, i, v)
			insertI = insertI + 1
		elseif vtype == "number" then
			builtStr[insertI] = IEex_ToDecStr(v)
			insertI = insertI + 1
		else
			IEex_Error(string.format("Unexpected type encountered during JIT at index %d: %s", i, vtype))
		end
		i = i + advanceCount
	end

	builtStr[insertI] = "\n" -- Always end with a newline
	local toReturn = table.concat(builtStr)

	--[[
		I would never abuse regex, I swear!
		(Please forgive the following code)
		#STACK_MOD((-\d+)[1])
		(#MAKE_SHADOW_SPACE((\d+)[3?]))[2]
		(#DESTROY_SHADOW_SPACE(KEEP_ENTRY)[5?])[4]
		(#ALIGN_END)[6]
		(#ALIGN((\d+)[8?]))[7]
		(#SHADOW_SPACE_BOTTOM((\d+)[10?]))[9]
		(#LAST_FRAME_TOP((\d+)[12?]))[11]
		(#RESUME_SHADOW_ENTRY)[13]
		(#MANUAL_HOOK_EXIT(\d+)[15])[14]
	--]]

	if not state then
		state = {
			["shadowSpaceStack"] = {},
			["shadowSpaceStackTop"] = 0,
			["alignModStack"] = {},
			["alignModStackTop"] = 0,
			["hintAccumulator"] = 0,
			["debug"] = false,
		}
	end

	toReturn = IEex_ReplaceRegex(toReturn, "(?:#STACK_MOD\\s*\\((-{0,1}\\d+)\\))|(#MAKE_SHADOW_SPACE(?:\\s*\\((\\d+)\\)){0,1})|(#DESTROY_SHADOW_SPACE(?:(?!\\(.*?\\))|(?:\\((KEEP_ENTRY)\\))))|(#ALIGN_END)|(#ALIGN(?:\\s*\\((\\d+)\\)){0,1})|(#SHADOW_SPACE_BOTTOM\\s*\\((-{0,1}.+?)\\))|(#LAST_FRAME_TOP\\s*\\((-{0,1}.+?)\\))|(#RESUME_SHADOW_ENTRY)|(#MANUAL_HOOK_EXIT\\s*\\((\\d+)\\))|(#DEBUG_ON)|(#DEBUG_OFF)", function(pos, endPos, str, groups)
		if groups[1] then
			--print("#STACK_MOD("..tonumber(groups[1])..")")
			state.hintAccumulator = state.hintAccumulator + tonumber(groups[1])
		elseif groups[2] then
			--print("#MAKE_SHADOW_SPACE")
			local neededShadow = 32 + (groups[3] and tonumber(groups[3]) or 0)
			if state.shadowSpaceStackTop > 0 and state.shadowSpaceStack[state.shadowSpaceStackTop].top == state.hintAccumulator then
				local shadowEntry = state.shadowSpaceStack[state.shadowSpaceStackTop]
				if shadowEntry.sizeNoRounding < neededShadow then
					print(debug.traceback("[!] #MAKE_SHADOW_SPACE redefined where original failed to provide enough space! Correct this by expanding "..(shadowEntry.sizeNoRounding - 32).." to "..(neededShadow - 32).."; continuing with suboptimal configuration."))
					local sizeDiff = IEex_RoundUp(neededShadow, 16) - shadowEntry.size
					state.hintAccumulator = state.hintAccumulator + sizeDiff
					shadowEntry.top = shadowEntry.top + sizeDiff
					shadowEntry.size = shadowEntry.size + sizeDiff
					shadowEntry.active = true
					-- Ideally this would be merged with the previous shadow space instruction, but abusing
					-- regex like this doesn't help make that happen, (would require an additional pass)
					return string.format("lea rsp, qword ptr ss:[rsp-%d] #ENDL", sizeDiff)
				end
			else
				local neededStack = IEex_DistanceToMultiple(state.hintAccumulator + neededShadow, 16) + neededShadow

				if state.debug then
					print(string.format(
						"[?] #MAKE_SHADOW_SPACE() with hintAccumulator = %d, need %d bytes for shadow space, allocating %d to maintain alignment",
						state.hintAccumulator, neededShadow, neededStack
					))
				end

				state.hintAccumulator = state.hintAccumulator + neededStack
				state.shadowSpaceStackTop = state.shadowSpaceStackTop + 1
				state.shadowSpaceStack[state.shadowSpaceStackTop] = {
					["top"] = state.hintAccumulator,
					["size"] = neededStack,
					["sizeNoRounding"] = neededShadow,
					["active"] = true,
				}
				return string.format("lea rsp, qword ptr ss:[rsp-%d] #ENDL", neededStack)
			end
		elseif groups[4] then
			--print("#DESTROY_SHADOW_SPACE")
			local shadowEntry = state.shadowSpaceStack[state.shadowSpaceStackTop]
			if state.hintAccumulator ~= shadowEntry.top then IEex_Error("#DESTROY_SHADOW_SPACE() failed - stack top not where it should be") end
			if not groups[5] then
				state.shadowSpaceStackTop = state.shadowSpaceStackTop - 1
			else
				shadowEntry.active = false -- KEEP_ENTRY
			end
			state.hintAccumulator = state.hintAccumulator - shadowEntry.size
			-- LEA maintains flags (as opposed to ADD), which allows us to test a register
			-- and restore it before calling #DESTROY_SHADOW_SPACE and still use the result
			-- for a branch.
			return string.format("lea rsp, qword ptr ss:[rsp+%d]", shadowEntry.size)
		elseif groups[6] then
			--print("#ALIGN_END")
			local alignEntry = state.alignModStack[state.alignModStackTop]
			if alignEntry.madeShadow then state.shadowSpaceStackTop = state.shadowSpaceStackTop - 1 end
			state.alignModStackTop = state.alignModStackTop - 1
			if alignEntry.popAmount > 0 then
				return string.format("lea rsp, qword ptr ss:[rsp+%d] #ENDL", tonumber(alignEntry.popAmount))
			end
		elseif groups[7] then
			local pushedArgBytes = groups[8] and tonumber(groups[8]) or 0
			--print("#ALIGN("..pushedArgBytes..")")
			local neededShadow = 0
			if state.shadowSpaceStackTop == 0 or state.shadowSpaceStack[state.shadowSpaceStackTop].top ~= state.hintAccumulator then
				neededShadow = 32
				state.shadowSpaceStackTop = state.shadowSpaceStackTop + 1
				state.shadowSpaceStack[state.shadowSpaceStackTop] = {
					["top"] = state.hintAccumulator,
					["size"] = neededShadow,
					["sizeNoRounding"] = neededShadow,
				}
			end
			local neededStack = IEex_DistanceToMultiple(state.hintAccumulator + neededShadow + pushedArgBytes, 16) + neededShadow - pushedArgBytes
			state.alignModStackTop = state.alignModStackTop + 1
			state.alignModStack[state.alignModStackTop] = {
				["popAmount"] = neededStack + pushedArgBytes,
				["madeShadow"] = neededShadow > 0,
			}
			if neededStack > 0 then
				return string.format("lea rsp, qword ptr ss:[rsp-%d] #ENDL", neededStack)
			end
		elseif groups[9] then
			--print("#SHADOW_SPACE_BOTTOM")
			local adjustStr = groups[10]
			local adjust = adjustStr
				and (adjustStr:sub(-1) == "h" and tonumber(adjustStr:sub(1,-2), 16) or tonumber(adjustStr))
				or 0
			if adjust >= 0 then IEex_Error("#SHADOW_SPACE_BOTTOM must have a negative offset") end
			local shadowEntry = state.shadowSpaceStack[state.shadowSpaceStackTop]
			local stackModAdj = state.hintAccumulator - shadowEntry.top -- For when #STACK_MOD() adjusts the stack after #MAKE_SHADOW_SPACE()
			return tostring(shadowEntry.sizeNoRounding + stackModAdj + adjust)
		elseif groups[11] then
			--print("#LAST_FRAME_TOP")
			local adjustStr = groups[12]
			local adjust = adjustStr
				and (adjustStr:sub(-1) == "h" and tonumber(adjustStr:sub(1,-2), 16) or tonumber(adjustStr))
				or 0
			if adjust < 0 then IEex_Error("#LAST_FRAME_TOP must have a positive offset") end
			if state.shadowSpaceStackTop == 0 then return adjust end
			local shadowEntry = state.shadowSpaceStack[state.shadowSpaceStackTop]
			local stackModAdj = state.hintAccumulator - shadowEntry.top -- For when #STACK_MOD() adjusts the stack after #MAKE_SHADOW_SPACE()
			return tostring(shadowEntry.size + stackModAdj + adjust)
		elseif groups[13] then
			--print("#RESUME_SHADOW_ENTRY")
			local shadowEntry = state.shadowSpaceStack[state.shadowSpaceStackTop]
			state.hintAccumulator = state.hintAccumulator + shadowEntry.size
			shadowEntry.active = true
		elseif groups[14] then
			--print("#MANUAL_HOOK_EXIT")
			local hadActiveShadowSpace = false
			for i = state.shadowSpaceStackTop, 1, -1 do
				if state.shadowSpaceStack[state.shadowSpaceStackTop].active then
					hadActiveShadowSpace = true
					break
				end
			end
			if hadActiveShadowSpace or state.alignModStackTop ~= 0 then IEex_Error("#MANUAL_HOOK_EXIT cannot exit inside a stack frame") end
			local instance = tonumber(groups[15])
			if instance == nil or instance < 0 then IEex_Error("#MANUAL_HOOK_EXIT has invalid instance") end
			return IEex_PreprocessAssembly(IEex_HookIntegrityWatchdog_HookExit(instance), state)
		elseif groups[16] then
			--print("#DEBUG_ON")
			state.debug = true
		elseif groups[17] then
			--print("#DEBUG_OFF")
			state.debug = false
		end
		return ""
	end)

	-- Standardize string
	toReturn = IEex_ReplacePattern(toReturn, "#ENDL", "\n")    -- Turn ENDL markers into newlines
	toReturn = IEex_ReplacePattern(toReturn, "[ \t]+\n", "\n") -- Remove whitespace before newlines (trailing whitespace)
	toReturn = IEex_ReplacePattern(toReturn, "\n+", "\n")      -- Merge newlines
	toReturn = IEex_ReplacePattern(toReturn, "\n[ \t]+", "\n") -- Remove whitespace after newlines, (indentation)
	toReturn = IEex_ReplacePattern(toReturn, "^[ \t]+", "")    -- Remove initial indent
	toReturn = IEex_ReplacePattern(toReturn, "[ \t]+;", " ;")  -- Remove indentation before comments

	if IEex_DebugPreprocessAssembly then
		print("IEex_PreprocessAssembly returning:\n\n"..toReturn.."\n")
	end

	-- Validate labels to prevent subtle bug where zero-offset branch instructions are written for non-existing labels
	local seenLabels = {}
	IEex_IterateRegex(toReturn, "^\\s*(\\S+):", function(pos, endPos, matchedStr, groups)
		seenLabels[groups[1]] = true
	end)

	local branchUsingLabel = "^\\s*(?:call|ja|jae|jb|jbe|jc|je|jg|jge|jl|jle|jmp|jna|jnae|jnb|jnbe|jnc|jne|jng|jnge|jnl|jnle|jno|jnp|jns|jnz|jo|jp|jpe|jpo|js|jz|loope|loopne|loopnz|loopz)\\s+([^0-9]\\S*)\\s*$"
	IEex_IterateRegex(toReturn, branchUsingLabel, function(pos, endPos, matchedStr, groups)
		local expectedLabel = groups[1]
		if not seenLabels[expectedLabel] then
			IEex_Error(string.format("Label \"%s\" not defined. Did you mean to use \"#L(%s)\"?", expectedLabel, expectedLabel))
		end
	end)

	return toReturn
end

function IEex_PreprocessAssemblyStr(assemblyT, curI, assemblyStr)

	local advanceCount = 1

	-- #IF
	assemblyStr = IEex_ReplacePattern(assemblyStr, "#IF(.*)", function(match)

		if IEex_FindPattern(match.groups[1], "[^%s]") then
			IEex_Error("Text between #IF and immediate condition")
		end

		advanceCount = 2
		local conditionV = assemblyT[curI + 1]

		if type(conditionV) == "boolean" then

			local hadBody = false
			local bodyI = curI + 2
			local bodyV = assemblyT[bodyI]

			if type(bodyV) == "string" then

				-- Find and remove the opening "{"
				local hadOpen = false
				bodyV = IEex_ReplacePattern(bodyV, "^%s-{(.*)", function(bodyMatch)
					hadOpen = true
					return bodyMatch.groups[1], true
				end)

				if hadOpen then

					assemblyT[bodyI] = bodyV

					local curLevel = 1
					repeat
						-- Look for closing "}"
						if type(bodyV) == "string" then

							local findV -- curLevel if not hadBody, else found closingI
							hadBody, findV = IEex_FindClosing(bodyV, "{", "}", curLevel)

							if hadBody then
								-- Save contents before and after the "}" if condition was true,
								-- else only save contents after the "}"
								assemblyT[bodyI] = conditionV and findV > 1
									and bodyV:sub(1, findV - 1)..bodyV:sub(findV + 1)
									or  bodyV:sub(findV + 1)
								break
							end
							curLevel = findV
						end

						-- Skip every assemblyT value until "}" is found
						if not conditionV then
							advanceCount = advanceCount + 1
						end

						bodyI = bodyI + 1
						bodyV = assemblyT[bodyI]

					until bodyV == nil
				end
			end

			if not hadBody then
				IEex_Error("#IF has no immediate body")
			end
		else
			IEex_Error("#IF has no immediate condition")
		end
	end)

	-- #$
	assemblyStr = IEex_ReplacePattern(assemblyStr, "#%$%((%d+)%)", function(match)
		local argIndexStr = match.groups[1]
		local argIndex = tonumber(argIndexStr)
		if not argIndex then IEex_Error(string.format("#$ has invalid arg index: \"%s\"", argIndexStr)) end
		local argsTable = assemblyT[curI + 1]
		if not argsTable or type(argsTable) ~= "table" then IEex_Error("#$ has no immediate arg table") end
		local argsTableSize = #argsTable
		if argIndex > argsTableSize then IEex_Error(string.format("#$%d out of bounds for arg table of size %d", argIndex, argsTableSize)) end
		advanceCount = 2
		local argVal = argsTable[argIndex]
		return type(argVal) == "number"
			and IEex_ToDecStr(argVal)
			or tostring(argVal)
	end)

	-- #L
	assemblyStr = IEex_ReplacePattern(assemblyStr, "#L(%b())", function(match)
		local labelName = match.groups[1]:sub(2, -2)
		local labelAddress = IEex_TryLabel(labelName)
		return labelAddress and IEex_ToDecStr(labelAddress) or labelName
	end)

	-- #REPEAT
	assemblyStr = IEex_ReplacePattern(assemblyStr, "#REPEAT(%b())", function(match)

		local toBuild = {}

		local innerStr = match.groups[1]
		local innerMatch = IEex_FindPattern(innerStr, "^%(%s*(-?%d+)%s*,%s*([^,]+)%)$")
		if not innerMatch then IEex_Error(string.format("Invalid #REPEAT parameters: \"%s\"", innerStr)) end

		local repeatStr = innerMatch.groups[2]
		for i = 1, innerMatch.groups[1] do
			toBuild[i] = repeatStr
		end
		return table.concat(toBuild)
	end)

	return assemblyStr, advanceCount
end

------------
-- Labels --
------------

-- This table is stored in the Lua registry. InfinityLoader automatically
-- updates it when new patterns are added by Lua bindings DLLs.
IEex_GlobalAssemblyLabels = IEex_GetPatternMap()

function IEex_ClearAssemblyLabel(label)
	IEex_GlobalAssemblyLabels[label] = nil
end

function IEex_DefineAssemblyLabel(label, value)
	IEex_GlobalAssemblyLabels[label] = value
end

function IEex_Label(label)
	IEex_ProcessThreadQueue()
	local value = IEex_GlobalAssemblyLabels[label]
	if not value then
		IEex_Error(string.format("Label \"#L(%s)\" not defined", label))
	end
	return IEex_GlobalAssemblyLabels[label]
end

function IEex_LabelDefault(label, default)
	IEex_ProcessThreadQueue()
	return IEex_GlobalAssemblyLabels[label] or default
end

function IEex_RunWithAssemblyLabels(labels, func)
	for _, labelPair in ipairs(labels) do
		IEex_DefineAssemblyLabel(labelPair[1], labelPair[2])
	end
	local retVal = func()
	for _, labelPair in ipairs(labels) do
		IEex_ClearAssemblyLabel(labelPair[1])
	end
	return retVal
end

function IEex_TryLabel(label)
	IEex_ProcessThreadQueue()
	return IEex_GlobalAssemblyLabels[label]
end

--------------------
-- Memory Manager --
--------------------

IEex_MemoryManagerStructDefinitions = {}

IEex_MemoryManager = {}
IEex_MemoryManager.__index = IEex_MemoryManager

function IEex_MemoryManager:destruct()
	for _, entry in pairs(self.nameToEntry) do
		local destructor = (entry.structDefinition or {}).destructor
		if destructor then
			if type(destructor) ~= "function" then
				IEex_TracebackMessage("[IEex_MemoryManager] Invalid destructor type!")
			end
			if not entry.noDestruct then
				destructor(entry.userData and entry.userData or entry.address)
			end
		end
	end
end

function IEex_MemoryManager:free()
	self:destruct()
	IEex_Free(self.address)
end

function IEex_MemoryManager:getAddress(name)
	return self.nameToEntry[name].address
end

function IEex_MemoryManager:getUserData(name)
	return self.nameToEntry[name].userData
end
IEex_MemoryManager.getUD = IEex_MemoryManager.getUserData

function IEex_MemoryManager:init(structEntries, stackModeFunc)

	local getArgs = function(structEntry)
		local args = (structEntry.constructor or {}).args
		local argsType = type(args)
		if argsType == "function" then
			return args(self)
		elseif argsType == "table" then
			return table.unpack(args)
		end
	end

	self.nameToEntry = {}
	local currentOffset = 0

	for _, structEntry in ipairs(structEntries) do

		self.nameToEntry[structEntry.name] = structEntry
		local structDefinition = IEex_MemoryManagerStructDefinitions[structEntry.struct]
		local userType = _G[structEntry.struct]

		local size
		if userType and type(userType) == "table" then
			size = userType.sizeof
			structEntry.userType = userType
		else
			if not structDefinition then
				IEex_TracebackMessage("[IEex_MemoryManager] Struct meta must be defined for non-usertype: \""..structEntry.struct.."\"!")
			end
			size = structDefinition.size
		end

		structEntry.offset = currentOffset
		structEntry.structDefinition = structDefinition

		local sizeType = type(size)
		if sizeType == "function" then
			currentOffset = currentOffset + size(getArgs(structEntry))
		elseif sizeType == "number" then
			currentOffset = currentOffset + size
		else
			IEex_TracebackMessage("[IEex_MemoryManager] Invalid size type!")
		end
	end

	local initMemory = function(startAddress)

		self.address = startAddress

		for _, structEntry in ipairs(structEntries) do

			structEntry.address = startAddress + structEntry.offset

			if structEntry.userType then
				structEntry.userData = IEex_PtrToUD(structEntry.address, structEntry.struct)
			end

			local constructor = ((structEntry.structDefinition or {}).constructors or {})[(structEntry.constructor or {}).variant or "#default"]
			if type(constructor) == "function" then
				constructor(structEntry.userData and structEntry.userData or structEntry.address, getArgs(structEntry))
			elseif type(constructor) == "table" then
				local constructorFunc = constructor.func
				if type(constructorFunc) ~= "function" then
					IEex_TracebackMessage("[IEex_MemoryManager] Invalid constructor.func type!")
				end
				if constructor.usesManager then
					constructor(self, structEntry.userData and structEntry.userData or structEntry.address, getArgs(structEntry))
				else
					constructor(structEntry.userData and structEntry.userData or structEntry.address, getArgs(structEntry))
				end
			elseif constructor ~= nil then
				IEex_TracebackMessage("[IEex_MemoryManager] Invalid constructor type!")
			end
		end
	end

	if stackModeFunc then
		local retVals
		IEex_RunWithStack(currentOffset, function(rsp)
			initMemory(rsp)
			retVals = {stackModeFunc(self)}
			self:destruct()
		end)
		return table.unpack(retVals)
	else
		initMemory(IEex_Malloc(currentOffset))
	end
end

function IEex_MemoryManager:new(structEntries)
	local o = {}
	setmetatable(o, self)
	o:init(structEntries)
	return o
end

function IEex_MemoryManager:runWithStack(structEntries, stackModeFunc)
	local o = {}
	setmetatable(o, self)
	return o:init(structEntries, stackModeFunc)
end

function IEex_NewMemoryManager(structEntries)
	return IEex_MemoryManager:new(structEntries)
end

function IEex_RunWithStackManager(structEntries, func)
	return IEex_MemoryManager:runWithStack(structEntries, func)
end

--------------------
-- Memory Utility --
--------------------

IEex_WriteFailType = {
	["ERROR"]   = 0,
	["DEFAULT"] = 1,
	["NOTHING"] = 2,
}

IEex_WriteType = {
	["BYTE"]    = 0,
	["8"]       = 0,
	["WORD"]    = 1,
	["16"]      = 1,
	["DWORD"]   = 2,
	["32"]      = 2,
	["QWORD"]   = 3,
	["64"]      = 3,
	["POINTER"] = 4,
	["PTR"]     = 4,
	["RESREF"]  = 5,
	["JIT"]     = 6,
}

function IEex_WriteArgs(address, args, writeDefs)
	writeTypeFunc = {
		[IEex_WriteType.BYTE]    = IEex_Write8,
		[IEex_WriteType.WORD]    = IEex_Write16,
		[IEex_WriteType.DWORD]   = IEex_Write32,
		[IEex_WriteType.QWORD]   = IEex_Write64,
		[IEex_WriteType.POINTER] = IEex_WritePtr,
		[IEex_WriteType.RESREF]  = function(address, arg) IEex_WriteLString(address, arg, 8) end,
		[IEex_WriteType.JIT]     = function(address, arg)
			local ptr = arg
			if type(ptr) == "table" then
				ptr = IEex_JITNear(arg)
			end
			IEex_WritePtr(address, ptr)
		end,
	}
	for _, writeDef in ipairs(writeDefs) do
		local argKey = writeDef[1]
		local arg = args[argKey]
		local skipWrite = false
		if not arg then
			local failType = writeDef[4]
			if failType == IEex_WriteFailType.DEFAULT then
				arg = writeDef[5]
			elseif failType == IEex_WriteFailType.ERROR then
				IEex_Error(argKey.." must be defined!")
			else
				skipWrite = true
			end
		end
		if not skipWrite then
			writeTypeFunc[writeDef[3]](address + writeDef[2], arg)
		end
	end
end

IEex_StringCache = {}

function IEex_WriteStringCache(str)
	local cached = IEex_StringCache[str]
	if cached then
		return cached
	else
		local address = IEex_WriteStringAuto(str)
		IEex_StringCache[str] = address
		return address
	end
end

--------------------
-- String Utility --
--------------------

function IEex_FindClosing(str, openStr, endStr, curLevel)
	local strLen = #str
	local openLen = #openStr - 1
	local endLen = #endStr - 1
	curLevel = curLevel or 0
	for i = 1, strLen do
		if str:sub(i, i + openLen) == openStr then
			curLevel = curLevel + 1
		end
		if str:sub(i, i + endLen) == endStr then
			curLevel = curLevel - 1
			if curLevel == 0 then return true, i end
		end
	end
	return false, curLevel
end

function IEex_FindPattern(str, findStr, startI)
	local results = table.pack(str:find(findStr, startI or 1))
	if not results[1] then return end
	return {
		["startI"] = results[1],
		["endI"] = results[2],
		["groups"] = IEex_Subtable(results, 3, results.n)
	}
end

function IEex_FindPatternAll(str, findStr)
	local matches = {}
	local insertI = 1
	local nextStartI = 1
	while true do
		local match = IEex_FindPattern(str, findStr, nextStartI)
		if not match then break end
		matches[insertI] = match
		insertI = insertI + 1
		nextStartI = match.endI + 1
	end
	return matches
end

function IEex_IteratePattern(str, findStr, func)
	local nextStartI = 1
	while true do
		local match = IEex_FindPattern(str, findStr, nextStartI)
		if not match or func(match) then break end
		nextStartI = match.endI + 1
	end
end

function IEex_ReplacePattern(str, findStr, replaceFunc)
	local builtStr = {""}
	local insertI = 1
	local lastAfterEndI = 1
	if type(replaceFunc) == "string" then
		local replaceStr = replaceFunc
		replaceFunc = function(match) return replaceStr end
	end
	IEex_IteratePattern(str, findStr, function(match)
		if match.startI > lastAfterEndI then
			builtStr[insertI] = str:sub(lastAfterEndI, match.startI - 1)
			insertI = insertI + 1
		end
		local v, shouldEnd = replaceFunc(match)
		if v then
			builtStr[insertI] = v
			insertI = insertI + 1
		end
		lastAfterEndI = match.endI + 1
		return shouldEnd
	end)
	local len = #str
	if lastAfterEndI <= len then
		builtStr[insertI] = str:sub(lastAfterEndI, len)
	end
	return table.concat(builtStr)
end

function IEex_ReplaceRegex(str, findStr, replaceFunc)
	local builtStr = {""}
	local insertI = 1
	local lastAfterEndI = 1
	if type(replaceFunc) == "string" then
		local replaceStr = replaceFunc
		replaceFunc = function(pos, endPos, str, groups) return replaceStr end
	end
	IEex_IterateRegex(str, findStr, function(pos, endPos, matchedStr, groups)
		if pos > lastAfterEndI then
			builtStr[insertI] = str:sub(lastAfterEndI, pos - 1)
			insertI = insertI + 1
		end
		local v, shouldEnd = replaceFunc(pos, endPos, matchedStr, groups)
		if v then
			builtStr[insertI] = v
			insertI = insertI + 1
		end
		lastAfterEndI = endPos + 1
		return shouldEnd
	end)
	local len = #str
	if lastAfterEndI <= len then
		builtStr[insertI] = str:sub(lastAfterEndI, len)
	end
	return table.concat(builtStr)
end

-------------------
-- Table Utility --
-------------------

function IEex_FindInTable(t, toFind)
	for i, v in ipairs(t) do
		if v == toFind then
			return i
		end
	end
	return nil
end

function IEex_FlattenTable(table)
	local toReturn = {}
	local insertionIndex = 1
	for i = 1, #table do
		local element = table[i]
		if type(element) == "table" then
			for j = 1, #element do
				toReturn[insertionIndex] = element[j]
				insertionIndex = insertionIndex + 1
			end
		else
			toReturn[insertionIndex] = element
			insertionIndex = insertionIndex + 1
		end
	end
	return toReturn
end

function IEex_ReverseTable(t, tMaxI)
	local newT = {}
	local insertI = 1
	for reverseI = tMaxI or #t, 1, -1 do
		newT[insertI] = t[reverseI]
		insertI = insertI + 1
	end
	return newT
end

function IEex_Subtable(t, startI, endI)
	local subtable = {}
	local insertI = 1
	for i = startI, endI or #t do
		subtable[insertI] = t[i]
		insertI = insertI + 1
	end
	return subtable
end

-----------------------
-- User Data Utility --
-----------------------

IEex_UserDataAuxiliary = {}

function IEex_DeleteUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		IEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	IEex_UserDataAuxiliary[IEex_UDToLightUD(ud)] = nil
end
IEex_DeleteUDAux = IEex_DeleteUserDataAuxiliary

function IEex_GetUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		IEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	local lud = IEex_UDToLightUD(ud)
	local auxiliary = IEex_UserDataAuxiliary[lud]
	if not auxiliary then
		auxiliary = {}
		IEex_UserDataAuxiliary[lud] = auxiliary
	end
	return auxiliary
end
IEex_GetUDAux = IEex_GetUserDataAuxiliary

function IEex_TryGetUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		IEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	return IEex_UserDataAuxiliary[IEex_UDToLightUD(ud)]
end
IEex_TryGetUDAux = IEex_TryGetUserDataAuxiliary

function IEex_UserDataEqual(ud1, ud2)
	return IEex_UDToLightUD(ud1) == IEex_UDToLightUD(ud2)
end
IEex_UDEqual = IEex_UserDataEqual

function IEex_UserDataToHex(ud)
	return ud and IEex_ToHex(IEex_UDToPtr(ud)) or "nil"
end
IEex_UDToHex = IEex_UserDataToHex

function IEex_WriteUserDataArgs(userdata, args, writeDefs)
	for _, writeDef in ipairs(writeDefs) do
		local argKey = writeDef[1]
		local toWrite = args[argKey]
		local doWrite = true
		if not toWrite then
			local failType = writeDef[2]
			if failType == IEex_WriteFailType.DEFAULT then
				toWrite = writeDef[3]
			elseif failType == IEex_WriteFailType.ERROR then
				IEex_Error(argKey.." must be defined!")
			else
				doWrite = false
			end
		end
		if doWrite then
			existingVal = userdata[argKey]
			if type(existingVal) == "userdata" and existingVal.set then
				existingVal:set(toWrite)
			else
				userdata[argKey] = toWrite
			end
		end
	end
end
IEex_WriteUDArgs = IEex_WriteUserDataArgs

--------------
-- Subfiles --
--------------

if IEex_Architecture == "x86" then
	IEex_DoFile("IEex_Assembly_x86")
elseif IEex_Architecture == "x86-64" then
	IEex_DoFile("IEex_Assembly_x86-64")
else
	IEex_Error(string.format("Unhandled IEex_Architecture: \"%s\"", IEex_Architecture))
end
