
#include "ThreadWatcher/thread_watcher_mapped_memory.h"

extern ThreadWatcherMappedMemory* threadWatcherMappedMemory;

void InitThreadWatcherMappedMemory();
void LaunchThreadWatcher();

void ThreadWatcherBeforeLockObject(uintptr_t esp, uintptr_t object);
void ThreadWatcherAfterLockObject(uintptr_t object);
void ThreadWatcherUnlockObject(uintptr_t object);
