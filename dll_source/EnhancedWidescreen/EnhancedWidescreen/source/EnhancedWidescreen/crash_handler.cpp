
#include <Windows.h>

#include "InfinityLoader/infinity_loader_common_api.h"
#include "engine_function_names.h"

static void logThreadStack(uintptr_t* esp, const char* indent, bool onlyRet = false)
{
    void* textBasePtr;
    DWORD textSize;

    if (sharedState().GetSegmentPointerAndSize(".text", textBasePtr, textSize))
    {
        Print("[!][EnhancedWidescreen.dll] logThreadStack() - GetSegmentPointerAndSize() failed\n");
        return;
    }

    const uintptr_t textBase = reinterpret_cast<uintptr_t>(textBasePtr);
    const uintptr_t textEnd = textBase + textSize;

    const NT_TIB *const tib = reinterpret_cast<NT_TIB*>(__readfsdword(0x18));
    void *const stackTop = tib->StackBase;

    FPrint("%sStack dump:\n", indent);

    for (uintptr_t* curStackPtr = esp; curStackPtr < stackTop; ++curStackPtr)
    {
        uintptr_t readVal = *curStackPtr;

        if (readVal >= textBase && readVal < textEnd)
        {
            const std::string& possibleName = GetContainingFunctionName(readVal);

            if (possibleName != "")
            {
                FPrint("%s    stack[0x%08X] = 0x%08X ; Possible RET to %s()\n", indent, curStackPtr, readVal, possibleName.c_str());
            }
            else
            {
                FPrint("%s    stack[0x%08X] = 0x%08X ; Possible RET\n", indent, curStackPtr, readVal);
            }
        }
        else if (!onlyRet)
        {
            FPrint("%s    stack[0x%08X] = 0x%08X\n", indent, curStackPtr, readVal);
        }
    }
}

LONG WINAPI EnhancedWidescreenUnhandledExceptionFilter(PEXCEPTION_POINTERS pExceptionInfo)
{
    const DWORD exceptionCode = pExceptionInfo->ExceptionRecord->ExceptionCode;

    // Dump the stack
    FPrint("[!][EnhancedWidescreen.dll] Crash detected with error code (0x%X)\n", exceptionCode);
    logThreadStack(reinterpret_cast<uintptr_t*>(pExceptionInfo->ContextRecord->Esp), "[!][EnhancedWidescreen.dll] ");

    // InfinityLoaderCommon.dll handles writing "*_big.dmp", "*.dmp", "*.log"
    DumpCrashInfo(pExceptionInfo);

    exit(exceptionCode);
}
