
#pragma once

#include <stdio.h>

#include <Windows.h>

#include "ThreadWatcher/thread_watcher_mapped_memory.h"

DWORD ThreadWatcherMappedMemory::Create(HANDLE& handleOut, ThreadWatcherMappedMemory*& mappedMemoryOut)
{
	// Allows child processes to use this handle
	SECURITY_ATTRIBUTES securityAttributes{};
	securityAttributes.nLength = sizeof(SECURITY_ATTRIBUTES);
	securityAttributes.bInheritHandle = TRUE;

	constexpr size_t sharedMemSize = sizeof(ThreadWatcherMappedMemory);
	HANDLE mappedHandle = CreateFileMapping(
		INVALID_HANDLE_VALUE,
		&securityAttributes,
		PAGE_READWRITE,
#ifdef _WIN64
		sharedMemSize >> 32,
#else
		0,
#endif
		sharedMemSize & 0xFFFFFFFF,
		nullptr                     // No name
	);

	if (mappedHandle == NULL)
	{
		const DWORD lastError = GetLastError();
		printf("[!] CreateThreadWatcherMappedMemory() - CreateFileMapping() failed (%d)\n", lastError);
		return lastError;
	}

	handleOut = mappedHandle;

	ThreadWatcherMappedMemory *const mappedMemory = reinterpret_cast<ThreadWatcherMappedMemory*>(MapViewOfFile(
		mappedHandle,
		FILE_MAP_ALL_ACCESS,
		0,                   // Offset to map (high)
		0,                   // Offset to map (low)
		0                    // Number of bytes to map (0 = to end of file)
	));

	if (mappedMemory == nullptr)
	{
		const DWORD lastError = GetLastError();
		printf("[!] CreateThreadWatcherMappedMemory() - MapViewOfFile() failed (%d)\n", lastError);
		return lastError;
	}

	mappedMemoryOut = mappedMemory;
	return ERROR_SUCCESS;
}

DWORD ThreadWatcherMappedMemory::Map(HANDLE mappedMemoryHandle, ThreadWatcherMappedMemory*& mappedMemoryOut) {

	ThreadWatcherMappedMemory *const mappedMemory = reinterpret_cast<ThreadWatcherMappedMemory*>(MapViewOfFile(mappedMemoryHandle,
		FILE_MAP_ALL_ACCESS,
		0,                   // Offset to map (high)
		0,                   // Offset to map (low)
		0                    // Number of bytes to map (0 = to end of file)
	));

	if (mappedMemory == nullptr)
	{
		const DWORD lastError = GetLastError();
		printf("[!] MapThreadWatcherMemory() - MapViewOfFile() failed (%d)\n", lastError);
		return lastError;
	}

	mappedMemoryOut = mappedMemory;
	return ERROR_SUCCESS;
}

ThreadSlot* ThreadWatcherMappedMemory::ClaimSlot()
{
	const DWORD threadId = GetCurrentThreadId();

	for (ThreadSlot& threadSlot : threadSlots)
	{
		bool expected = false;
		if (threadSlot.claimed.compare_exchange_strong(expected, true))
		{
			threadSlot.threadId = GetCurrentThreadId();
			return &threadSlot;
		}
		else if (threadSlot.threadId == threadId)
		{
			return &threadSlot;
		}
	}
	return nullptr;
}

ThreadSlot* ThreadWatcherMappedMemory::FindSlot(const DWORD threadId)
{
	for (ThreadSlot& threadSlot : threadSlots)
	{
		if (threadSlot.threadId == threadId)
		{
			return &threadSlot;
		}
	}
	return nullptr;
}
