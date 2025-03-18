
#pragma once

#include <Windows.h>

#include <atomic>

struct ReturnPtr
{
    void* sourceESP = nullptr;
    long function = 0;
    void* returnPtr = nullptr;
    bool alsoPopPrevious = false;
    int startTime = 0;
};

struct LockedObject
{
    uintptr_t esp = 0x0;
    uintptr_t object = 0x0;
    bool acquiring = false;
};

struct ThreadSlot
{
	std::atomic<bool> claimed = false;
    DWORD threadId = 0;
    bool alwaysShow = false;
    int lastUpdate = 0;
    int curReturnPtrI = 0;
    ReturnPtr returnPtrs[1000];
    int curLockedObjectI = 0;
    LockedObject lockedObjects[1000];
};

struct ThreadNameEntry
{
    std::atomic<DWORD> threadId = 0;
    char threadName[100];
};

struct DynamicAllocationEntry
{
    uintptr_t base = 0;
    DWORD size = 0;
};

struct ThreadWatcherMappedMemory
{
    HANDLE hParentProcess = nullptr;
    long long initTime = 0;
    std::atomic<bool> threadNamesHaveUpdate = false;
    ThreadNameEntry threadNames[1000];
    ThreadSlot threadSlots[1000];
    DynamicAllocationEntry dynamicAllocations[100];
    int nextDynamicAllocationI = 0;
    bool initialized = false;

    static DWORD Create(HANDLE& handleOut, ThreadWatcherMappedMemory*& mappedMemoryOut);
    static DWORD Map(HANDLE mappedMemoryHandle, ThreadWatcherMappedMemory*& mappedMemoryOut);
    ThreadSlot* ClaimSlot();
    ThreadSlot* FindSlot(DWORD threadId);
};
