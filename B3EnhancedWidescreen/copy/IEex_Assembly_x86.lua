
-------------
-- Hooking --
-------------

function IEex_ForceJump(address)
	local _, jmpDest, instructionLength, _ = IEex_GetJmpInfo(address)
	IEex_JITAt(address, {[[
		jmp short ]], jmpDest, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {instructionLength - 5}
	})
end

function IEex_HookAfterCall(address, assemblyT)
	local opcode = IEex_ReadU8(address)
	if opcode ~= 0xE8 then IEex_Error("Not disp32 call: "..IEex_ToHex(opcode)) end
	local afterCall = address + 5
	IEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + IEex_Read32(address + 1)
	local hookAddress = IEex_JITNear(IEex_FlattenTable({
		{"call #$(1) #ENDL", {target}},
		assemblyT,
		{"jmp #$(1) #ENDL", {afterCall}},
	}))
	IEex_JITAt(address, {"jmp short "..hookAddress})
end

function IEex_HookAfterRestore(address, restoreDelay, restoreSize, returnDelay, assemblyT)

	local restoreBytes = IEex_StoreBytesAssembly(address + restoreDelay, restoreSize)
	local returnAddress = address + returnDelay
	IEex_DefineAssemblyLabel("return", returnAddress)

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		restoreBytes,
		assemblyT,
		{[[
			jmp ]], returnAddress, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function IEex_HookBeforeAndAfterCall(address, beforeAssemblyT, afterAssemblyT)
	local opcode = IEex_ReadU8(address)
	if opcode ~= 0xE8 then IEex_Error("Not disp32 call: "..IEex_ToHex(opcode)) end
	local afterCall = address + 5
	IEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + IEex_Read32(address + 1)
	local hookAddress = IEex_JITNear(IEex_FlattenTable({
		beforeAssemblyT, "#ENDL",
		{"call #$(1) #ENDL", {target}},
		afterAssemblyT, "#ENDL",
		{"jmp #$(1) #ENDL", {afterCall}},
	}))
	IEex_JITAt(address, {"jmp short "..hookAddress})
end

function IEex_HookBeforeAndAfterRestore(address, restoreDelay, restoreSize, returnDelay, beforeAssemblyT, afterAssemblyT)

	local restoreBytes = IEex_StoreBytesAssembly(address + restoreDelay, restoreSize)
	local returnAddress = address + returnDelay
	IEex_DefineAssemblyLabel("return", returnAddress)

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		beforeAssemblyT,
		restoreBytes,
		afterAssemblyT,
		{[[
			jmp ]], returnAddress, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function IEex_HookBeforeCall(address, assemblyT)
	local opcode = IEex_ReadU8(address)
	if opcode ~= 0xE8 then IEex_Error("Not disp32 call: "..IEex_ToHex(opcode)) end
	local afterCall = address + 5
	IEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + IEex_Read32(address + 1)
	local hookAddress = IEex_JITNear(IEex_FlattenTable({
		assemblyT,
		{"call #$(1) #ENDL", {target}},
		{"jmp #$(1) #ENDL", {afterCall}},
	}))
	IEex_JITAt(address, {"jmp short "..hookAddress})
end

function IEex_HookBeforeRestore(address, restoreDelay, restoreSize, returnDelay, assemblyT)

	local restoreBytes = IEex_StoreBytesAssembly(address + restoreDelay, restoreSize)
	local returnAddress = address + returnDelay

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		assemblyT,
		{[[
			return:
		]]},
		restoreBytes,
		{[[
			jmp ]], returnAddress, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function IEex_HookBetweenRestore(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, assemblyT)

	local restoreBytes1 = IEex_StoreBytesAssembly(address + restoreDelay1, restoreSize1)
	local restoreBytes2 = IEex_StoreBytesAssembly(address + restoreDelay2, restoreSize2)
	local returnAddress = address + returnDelay

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		restoreBytes1,
		assemblyT,
		restoreBytes2,
		{[[
			return:
			jmp ]], returnAddress, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function IEex_HookJump(address, restoreSize, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = IEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = IEex_StoreBytesAssembly(afterInstruction, restoreSize)

	IEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		assemblyT,
		{[[
			jmp:
		]]},
		{
			jmpMnemonic, " ", jmpDest, [[ #ENDL
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function IEex_HookJumpAuto(address, restoreSize, assemblyT, bAutoSuccess)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = IEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = IEex_StoreBytesAssembly(afterInstruction, restoreSize)

	IEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		assemblyT,
		{[[
			#IF ]], bAutoSuccess, [[ {
				jmp #L(jmp_success)
			}
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function IEex_HookJumpAutoFail(address, restoreSize, assemblyT)
	IEex_HookJumpAuto(address, restoreSize, assemblyT, false)
end

function IEex_HookJumpAutoSucceed(address, restoreSize, assemblyT)
	IEex_HookJumpAuto(address, restoreSize, assemblyT, true)
end

function IEex_HookJumpOnFail(address, restoreSize, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = IEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = IEex_StoreBytesAssembly(afterInstruction, restoreSize)

	IEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		{jmpMnemonic, " ", jmpDest, "#ENDL"},
		assemblyT,
		{[[
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function IEex_HookJumpOnSuccess(address, restoreSize, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = IEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = IEex_StoreBytesAssembly(afterInstruction, restoreSize)

	IEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = IEex_JITNear(IEex_FlattenTable({
		{jmpMnemonic, [[ jmp_succeeded
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
		{[[
			jmp_succeeded:
		]]},
		assemblyT,
		{"jmp ", jmpDest, "#ENDL"},
	}))

	IEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function IEex_HookNOPs(address, nopCount, assemblyStr)
	IEex_DefineAssemblyLabel("return", address + 5 + nopCount)
	local hookAddress = IEex_JITNear(assemblyStr)
	IEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {nopCount}
	})
end

function IEex_HookRelativeBranch(address, assemblyT)
	local opcode = IEex_ReadU8(address)
	if opcode ~= 0xE8 and opcode ~= 0xE9 then IEex_Error("Not disp32 relative: "..IEex_ToHex(opcode)) end
	local afterCall = address + 5
	IEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + IEex_Read32(address + 1)
	IEex_DefineAssemblyLabel("original", target)
	local hookAddress = IEex_JITNear(assemblyT)
	IEex_JITAt(address, {"jmp short "..hookAddress})
end

function IEex_HookReplaceFunctionMaintainOriginal(address, restoreSize, originalLabel, assembly)

	IEex_DefineAssemblyLabel(originalLabel, IEex_JITNear(IEex_FlattenTable({
		IEex_StoreBytesAssembly(address, restoreSize),
		{"jmp ", address + restoreSize, "#ENDL"}
	})))

	IEex_JITAt(address, {[[
		jmp ]], IEex_JITNear(assembly), [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5}, [[ #ENDL
	]]})
end

---------------------
-- Hooking Utility --
---------------------

IEex_LuaCallReturnType = {
	["Boolean"] = 0,
	["Number"] = 1,
}

function IEex_GenLuaCall(funcName, meta)

	local numArgs = #((meta or {}).args or {})

	local argsUserType = {}
	local argsCastFunction = {}

	local labelSuffix = (meta or {}).labelSuffix or ""

	local errorFunc
	local errorFuncLuaStackPopAmount
	if (meta or {}).errorFunction then
		errorFunc = meta.errorFunction.func
		errorFuncLuaStackPopAmount = errorFunc and (1 + (meta.errorFunction.precursorAmount or 0)) or 0
	else
		errorFunc = {[[
			push ]], IEex_WriteStringCache("debug"), [[ ; name
			push ebx                                    ; L
			call #L(Hardcoded_lua_getglobal)
			add esp, 8

			push ]], IEex_WriteStringCache("traceback"), [[ ; k
			push -1                                         ; index
			push ebx                                        ; L
			call #L(Hardcoded_lua_getfield)
			add esp, 0xC
		]]}
		errorFuncLuaStackPopAmount = 2
	end

	local pushArgTemplate = function(argI)

		local userType = argsUserType[argI + 1]
		local userTypeType = type(userType)

		if userType == nil then

			return {[[
				push ebx ; L
				call #L(Hardcoded_lua_pushinteger)
				add esp, 8
			]]}

		elseif userTypeType == "string" then

			if userType == "string" then
				return {[[
					push ebx ; L
					call #L(Hardcoded_lua_pushstring)
					add esp, 8
				]]}
			else
				local argCastFunction = argsCastFunction[argI + 1]
				if argCastFunction then

					return {[[

						push ]], IEex_WriteStringCache(argCastFunction), [[ ; name
						push ebx                                            ; L
						call #L(Hardcoded_lua_getglobal)
						add esp, 8

						push dword ptr ss:[esp]                                           ; v
						mov dword ptr ss:[esp+4], ]], IEex_WriteStringCache(userType), [[ ; type
						push ebx                                                          ; L
						call #L(Hardcoded_tolua_pushusertype)
						add esp, 0xC

						push 0                                      ; k
						push 0                                      ; ctx
						push ]], errorFunc and -(4 + argI) or 0, [[ ; errfunc
						push 1                                      ; nresults
						push 1                                      ; nargs
						push ebx                                    ; L
						call #L(Hardcoded_lua_pcallk)
						add esp, 0x18

						call #L(IEex_CheckCallError)
						test eax, eax
						jz IEex_GenLuaCall_arg#$(1)_cast_function_no_error#$(2) ]], {argI, labelSuffix}, [[ #ENDL

						; Clear function args, function, and error function (+ its precursors) off of Lua stack
						push ]], -(2 + errorFuncLuaStackPopAmount + argI), [[ ; index
						push ebx                                              ; L
						call #L(Hardcoded_lua_settop)
						add esp, 8

						jmp IEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL

						IEex_GenLuaCall_arg#$(1)_cast_function_no_error#$(2): ]], {argI, labelSuffix}, [[ #ENDL
					]]}
				else
					return {[[
						push dword ptr ss:[esp]                                           ; v
						mov dword ptr ss:[esp+4], ]], IEex_WriteStringCache(userType), [[ ; type
						push ebx                                                          ; L
						call #L(Hardcoded_tolua_pushusertype)
						add esp, 0xC
					]]}
				end
			end
		else
			IEex_Error("[IEex_GenLuaCall] Invalid arg usertype: "..userTypeType)
		end
	end

	local genStoreArgs = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = numArgs, 1, -1 do
			local argT, argUT, argCastFunction = table.unpack(args[i])
			toReturn[insertionIndex] = argT
			argsUserType[i] = argUT
			argsCastFunction[i] = argCastFunction
			insertionIndex = insertionIndex + 1
		end

		return IEex_FlattenTable(toReturn)
	end

	local genFunc = function()
		if funcName then
			if meta then
				if meta.functionChunk then IEex_Error("[IEex_GenLuaCall] funcName and meta.functionChunk are exclusive") end
				if meta.functionSrc then IEex_Error("[IEex_GenLuaCall] funcName and meta.functionSrc are exclusive") end
			end
			return {[[
				push ]], IEex_WriteStringCache(funcName), [[ ; name
				push ebx                                     ; L
				call #L(Hardcoded_lua_getglobal)
				add esp, 8
			]]}
		elseif meta then
			if meta.functionChunk then
				if numArgs > 0 then IEex_Error("[IEex_GenLuaCall] Lua chunks can't be passed arguments") end
				if meta.functionSrc then IEex_Error("[IEex_GenLuaCall] meta.functionChunk and meta.functionSrc are exclusive") end
				return IEex_FlattenTable({
					meta.functionChunk,
					{[[
						push ebx ; L
						call #L(Hardcoded_luaL_loadstring)
						add esp, 8

						test eax, eax
						jz IEex_GenLuaCall_loadstring_no_error#$(1) ]], {labelSuffix}, [[ #ENDL

						#IF ]], errorFunc ~= nil, [[ {

							; Call error function with loadstring message
							push 0       ; k
							push 0       ; ctx
							push 0       ; errfunc
							push 1       ; nresults
							push 1       ; nargs
							push ebx     ; L
							call #L(Hardcoded_lua_pcallk)
							add esp, 0x18

							call #L(IEex_CheckCallError)
							test eax, eax
							jnz IEex_GenLuaCall_error_in_error_handling#$(1) ]], {labelSuffix}, [[ #ENDL

							call #L(IEex_PrintPopLuaString)

							IEex_GenLuaCall_error_in_error_handling#$(1): ]], {labelSuffix}, [[ #ENDL
							; Clear error function precursors off of Lua stack
							push ]], -errorFuncLuaStackPopAmount, [[ #ENDL
							push ebx
							call #L(Hardcoded_lua_settop)
							add esp, 8

							jmp IEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
						}

						#IF ]], errorFunc == nil, [[ {
							call #L(IEex_PrintPopLuaString)
							jmp IEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
						}

						IEex_GenLuaCall_loadstring_no_error#$(1): ]], {labelSuffix}, [[ #ENDL
					]]},
				})
			elseif meta.functionSrc then
				if meta.functionChunk then IEex_Error("[IEex_GenLuaCall] meta.functionSrc and meta.functionChunk are exclusive") end
				return meta.functionSrc
			end
		end

		IEex_Error("[IEex_GenLuaCall] meta.functionChunk or meta.functionSrc must be defined when funcName = nil")
	end

	local genArgPushes = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = 0, numArgs - 1 do
			toReturn[insertionIndex] = pushArgTemplate(i)
			insertionIndex = insertionIndex + 1
		end

		return IEex_FlattenTable(toReturn)
	end

	local genReturnHandling = function()

		if not meta then return {} end
		local returnType = meta.returnType
		if not returnType then return {} end

		if returnType == IEex_LuaCallReturnType.Boolean then
			return {[[
				push -1  ; index
				push ebx ; L
				call #L(Hardcoded_lua_toboolean)
				add esp, 8
				push eax
			]]}
		elseif returnType == IEex_LuaCallReturnType.Number then
			return {[[
				push 0   ; isnum
				push -1  ; index
				push ebx ; L
				call #L(Hardcoded_lua_tointegerx)
				add esp, 0xC
				push eax
			]]}
		else
			IEex_Error("[IEex_GenLuaCall] meta.returnType invalid")
		end
	end

	local numRet = (meta or {}).returnType and 1 or 0
	local toReturn = IEex_FlattenTable({
		{[[
			push ebx
			push ebp
			mov ebp, esp
		]]},
		genStoreArgs(),
		(meta or {}).luaState or {[[
			call #L(Hardcoded_getLuaState)
			mov ebx, eax
		]]},
		errorFunc or {},
		genFunc(),
		genArgPushes(),
		{[[
			push 0                                         ; k
			push 0                                         ; ctx
			push ]], errorFunc and -(2 + numArgs) or 0, [[ ; errfunc
			push ]], numRet, [[                            ; nresults
			push ]], numArgs, [[                           ; nargs
			push ebx                                       ; L
			call #L(Hardcoded_lua_pcallk)
			add esp, 0x18

			call #L(IEex_CheckCallError)
			test eax, eax

			#IF ]], errorFunc ~= nil, [[ {

				jz IEex_GenLuaCall_no_error#$(1) ]], {labelSuffix}, [[ #ENDL

				; Clear error function and its precursors off of Lua stack
				push ]], -(1 + errorFuncLuaStackPopAmount), [[ ; index
				push ebx                                       ; L
				call #L(Hardcoded_lua_settop)
				add esp, 8

				jmp IEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
			}

			#IF ]], errorFunc == nil, [[ {
				jnz IEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
			}

			IEex_GenLuaCall_no_error#$(1): ]], {labelSuffix}, [[ #ENDL
		]]},
		genReturnHandling(),
		{[[
			; Clear return values and error function (+ its precursors) off of Lua stack
			push ]], -(1 + errorFuncLuaStackPopAmount + numRet), [[ ; index
			push ebx                                                ; L
			call #L(Hardcoded_lua_settop)
			add esp, 8

			#IF ]], numRet > 0, [[ {
				pop eax
			}

			jmp IEex_GenLuaCall_resume#$(1) ]], {labelSuffix}, [[ #ENDL

			IEex_GenLuaCall_call_error#$(1): ]], {labelSuffix}, [[ #ENDL
			mov esp, ebp
			pop ebp
			pop ebx
			jmp call_error#$(1) ]], {labelSuffix}, [[ #ENDL

			IEex_GenLuaCall_resume#$(1): ]], {labelSuffix}, [[ #ENDL
			mov esp, ebp
			pop ebp
			pop ebx
		]]},
	})

	return toReturn
end

function IEex_GetJmpInfo(address)

	local opcode = IEex_ReadU8(address)
	local hadWordPrefix = false
	local curAddress = address

	if opcode == 0x66 then
		hadWordPrefix = true
		curAddress = curAddress + 1
		opcode = IEex_ReadU8(curAddress)
	end

	local entry
	if opcode ~= 0x0F then
		entry = ({
			[0x70] = { "jo",     1                        },
			[0x71] = { "jno",    1                        },
			[0x72] = { "jb",     1                        },
			[0x73] = { "jnb",    1                        },
			[0x74] = { "jz",     1                        },
			[0x75] = { "jnz",    1                        },
			[0x76] = { "jbe",    1                        },
			[0x77] = { "ja",     1                        },
			[0x78] = { "js",     1                        },
			[0x79] = { "jns",    1                        },
			[0x7A] = { "jp",     1                        },
			[0x7B] = { "jnp",    1                        },
			[0x7C] = { "jl",     1                        },
			[0x7D] = { "jnl",    1                        },
			[0x7E] = { "jle",    1                        },
			[0x7F] = { "jg",     1                        },
			[0xE0] = { "loopnz", 1                        },
			[0xE1] = { "loopz",  1                        },
			[0xE2] = { "loop",   1                        },
			[0xE3] = { "jcxz",   1                        },
			[0xE8] = { "call",   hadWordPrefix and 2 or 4 },
			[0xE9] = { "jmp",    hadWordPrefix and 2 or 4 },
			[0xEB] = { "jmp",    1                        },
		})[opcode]
	else
		curAddress = curAddress + 1
		opcode = IEex_ReadU8(curAddress)
		local length = hadWordPrefix and 2 or 4
		entry = ({
			[0x80] = { "jo",  length },
			[0x81] = { "jno", length },
			[0x82] = { "jb",  length },
			[0x83] = { "jnb", length },
			[0x84] = { "jz",  length },
			[0x85] = { "jnz", length },
			[0x86] = { "jbe", length },
			[0x87] = { "ja",  length },
			[0x88] = { "js",  length },
			[0x89] = { "jns", length },
			[0x8A] = { "jp",  length },
			[0x8B] = { "jnp", length },
			[0x8C] = { "jl",  length },
			[0x8D] = { "jnl", length },
			[0x8E] = { "jle", length },
			[0x8F] = { "jg",  length },
		})[opcode]
	end

	local readLen = entry[2]
	local readFunc = ({
		[1] = IEex_Read8,
		[2] = IEex_Read16,
		[4] = IEex_Read32,
	})[readLen]

	curAddress = curAddress + 1
	local afterInst = curAddress + readLen
	return entry[1], afterInst + readFunc(curAddress), afterInst - address, afterInst
end

function IEex_StoreBytesAssembly(startAddress, size)
	if size <= 0 then return {} end
	local bytes = {".DB "}
	for i = startAddress, startAddress + size - 1 do
		table.insert(bytes, IEex_ReadU8(i))
		table.insert(bytes, ", ")
	end
	if size > 0 then
		table.remove(bytes)
		table.insert(bytes, "#ENDL")
	end
	return bytes
end
