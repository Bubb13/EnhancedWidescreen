
#pragma once

#include <Windows.h>

#include "InfinityLoader/shared_state_types_api.h"

EXPORT void InitEnhancedWidescreenGUI(SharedState argSharedDLL);
EXTERN_C_EXPORT void __stdcall AskResolution(DWORD* nWidthRet, DWORD* nHeightRet);
