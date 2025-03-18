
#include <format>

#include <Windows.h>

#include "InfinityLoader/infinity_loader_common_types.h"
#include "ThreadWatcher/thread_watcher_mapped_memory.h"
#include "init_time.h"

HANDLE hThreadWatcherMappedMemory;
ThreadWatcherMappedMemory* threadWatcherMappedMemory = nullptr;
thread_local ThreadSlot* threadSlot = nullptr;

static DWORD createThreadWatcherProcess(const char* applicationPath, const char* commandLineArgs, HANDLE& hThreadWatcherProcessOut)
{
    STARTUPINFOA si{};
    si.cb = sizeof(STARTUPINFOA);

    PROCESS_INFORMATION pi{};

    const BOOL createProcessResult = CreateProcessA(
        applicationPath,
        const_cast<char*>(commandLineArgs),
        NULL,
        NULL,
        TRUE,
        CREATE_NEW_CONSOLE,
        NULL,
        NULL,
        &si,
        &pi
    );

    if (!createProcessResult)
    {
        const DWORD lastError = GetLastError();
        FPrint("[!][EnhancedWidescreen.dll] createThreadWatcherProcess() - CreateProcess() failed (%d)\n", lastError);
        return lastError;
    }

    hThreadWatcherProcessOut = pi.hProcess;
    CloseHandle(pi.hThread);
    return ERROR_SUCCESS;
}

void InitThreadWatcherMappedMemory()
{
    DWORD lastError = ThreadWatcherMappedMemory::Create(hThreadWatcherMappedMemory, threadWatcherMappedMemory);
    if (lastError)
    {
        FPrint("[!][EnhancedWidescreen.dll] Failed to create thread watcher mapped memory (%d)\n", lastError);
        return;
    }

    HANDLE hCurrentProcess = GetCurrentProcess();
    if (!DuplicateHandle(hCurrentProcess, hCurrentProcess, hCurrentProcess, &threadWatcherMappedMemory->hParentProcess, 0, TRUE, DUPLICATE_SAME_ACCESS))
    {
        lastError = GetLastError();
        FPrint("[!][EnhancedWidescreen.dll] InitThreadWatcherMappedMemory() - DuplicateHandle() failed (%d)\n", lastError);
        return;
    }

    threadWatcherMappedMemory->initTime = GetCurrentMicroseconds();

    //for (DynamicAllocationEntry& pendingAllocationEntry : pendingAllocationEntries)
    //{
    //    threadWatcherMappedMemory->dynamicAllocations[threadWatcherMappedMemory->nextDynamicAllocationI++] = pendingAllocationEntry;
    //}
    //pendingAllocationEntries.~vector();
}

void LaunchThreadWatcher()
{
    const std::string handleStr = std::format("ThreadWatcherHost.exe 0x{:X}", reinterpret_cast<uintptr_t>(hThreadWatcherMappedMemory));

    HANDLE hThreadWatcherProcess;
    const DWORD lastError = createThreadWatcherProcess("ThreadWatcherHost.exe", handleStr.c_str(), hThreadWatcherProcess);

    if (lastError != ERROR_SUCCESS)
    {
        FPrint("[!][EnhancedWidescreen.dll] Failed to start ThreadWatcherHost.exe (%d)\n", lastError);
        return;
    }

    DWORD exitCode;
    while (GetExitCodeProcess(hThreadWatcherProcess, &exitCode) && exitCode == STILL_ACTIVE && !threadWatcherMappedMemory->initialized)
    {
        Sleep(33);
    }
}

static ThreadSlot& getThreadSlot()
{
    if (threadSlot == nullptr) threadSlot = threadWatcherMappedMemory->ClaimSlot();
    return *threadSlot;
}

void ThreadWatcherBeforeLockObject(uintptr_t esp, uintptr_t object)
{
    ThreadSlot& threadSlot = getThreadSlot();
    LockedObject* lockedObject = threadSlot.lockedObjects;

    for (int i = 0; i < threadSlot.curLockedObjectI; ++i, ++lockedObject)
    {
        if (lockedObject->object == object)
        {
            return;
        }
    }

    //FPrint("[0x%X] BEFORE INCREMENT: threadSlot.curLockedObjectI: %d\n", GetCurrentThreadId(), threadSlot.curLockedObjectI);
    lockedObject->esp = esp;
    lockedObject->object = object;
    lockedObject->acquiring = true;
    ++threadSlot.curLockedObjectI;
}

void ThreadWatcherAfterLockObject(uintptr_t object)
{
    ThreadSlot& threadSlot = getThreadSlot();
    LockedObject* lockedObject = threadSlot.lockedObjects;

    for (int i = 0; i < threadSlot.curLockedObjectI; ++i, ++lockedObject)
    {
        if (lockedObject->object == object)
        {
            lockedObject->acquiring = false;
            return;
        }
    }
}

void ThreadWatcherUnlockObject(uintptr_t object)
{
    ThreadSlot& threadSlot = getThreadSlot();
    LockedObject* lockedObject = threadSlot.lockedObjects;

    for (int i = 0; i < threadSlot.curLockedObjectI; ++i, ++lockedObject)
    {
        if (lockedObject->object == object)
        {
            LockedObject* shiftLockedObject = lockedObject + 1;

            for (int j = i + 1; j < threadSlot.curLockedObjectI; ++j, ++lockedObject, ++shiftLockedObject)
            {
                *lockedObject = *shiftLockedObject;
            }

            //FPrint("[0x%X] BEFORE DECREMENT: threadSlot.curLockedObjectI: %d\n", GetCurrentThreadId(), threadSlot.curLockedObjectI);
            --threadSlot.curLockedObjectI;
            break;
        }
    }
}
