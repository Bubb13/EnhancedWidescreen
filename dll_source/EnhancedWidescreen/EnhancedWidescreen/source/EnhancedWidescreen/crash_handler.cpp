
#include <Windows.h>

#include "InfinityLoader/infinity_loader_common_api.h"
#include "engine_function_names.h"

static void dumpThreadStack(uintptr_t* esp, const char* indent, bool onlyRet = false)
{
    void* textBasePtr;
    DWORD textSize;

    if (sharedState().GetSegmentPointerAndSize(".text", textBasePtr, textSize))
    {
        Print("[!][EnhancedWidescreen.dll] DumpThreadStack() - GetSegmentPointerAndSize() failed\n");
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
    const String dmpLocation = WriteDump(sharedState().WorkingFolder(), pExceptionInfo);

    String logName{};
    bool hasLogFile;
    TryRetErr(GetINIStr(iniPath(), TEXT("General"), TEXT("LogFile"), logName, hasLogFile));

    FPrint("[!][EnhancedWidescreen.dll] Crash detected with error code (0x%X)\n", exceptionCode);
    dumpThreadStack(reinterpret_cast<uintptr_t*>(pExceptionInfo->ContextRecord->Esp), "[!][EnhancedWidescreen.dll] ");

    if (hasLogFile)
    {
        const String logLocation = dmpLocation + TEXT(".log");
        CopyFile(logName.c_str(), logLocation.c_str(), FALSE);

        MessageBoxFormat(TEXT("EnhancedWidescreen.dll"), MB_ICONERROR, TEXT("Crash detected with error code 0x%X.\n\n.dmp saved to:\n\n%s\n\n.log saved to:\n\n%s\n\nThe game will exit after you press OK."), exceptionCode, dmpLocation.c_str(), logLocation.c_str());
    }
    else
    {
        MessageBoxFormat(TEXT("EnhancedWidescreen.dll"), MB_ICONERROR, TEXT("Crash detected with error code 0x%X.\n\n.dmp saved to:\n\n%s\n\nThe game will exit after you press OK."), exceptionCode, dmpLocation.c_str());
    }

    exit(exceptionCode);
}
