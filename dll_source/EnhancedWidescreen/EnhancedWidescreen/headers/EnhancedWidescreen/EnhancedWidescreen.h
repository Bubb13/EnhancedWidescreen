
#pragma once

void InitEnhancedWidescreen();

void __stdcall Export_SignalSyncThread(uintptr_t esp);

void __stdcall Export_OnSyncThreadEntry();
void __stdcall Export_OnSearchThreadEntry();
void __stdcall Export_OnResourceManagerThreadEntry();
void __stdcall Export_OnNetworkThreadEntry();
void __stdcall Export_OnAsyncThreadEntry();

void __stdcall Export_OnBeforeLockObject(uintptr_t returnPtr, uintptr_t objectAddress);
void __stdcall Export_OnAfterLockObject(uintptr_t objectAddress);
void __stdcall Export_OnUnlockingObject(uintptr_t returnPtr, uintptr_t objectAddress);

void __stdcall Export_Patch_CGameArea_AIUpdate_CheckCursorScroll(CGameArea* const pArea);

int __stdcall Export_DivFloor(int a, int b);
int __stdcall Export_Modulo(int a, int b);
void __stdcall Export_BlankBackBuffer(CWarp* pActiveEngine);

void __stdcall Export_BlankCCache1();
void __stdcall Export_BlankCCache2();
void __stdcall Export_BlankCCache3();
int _stdcall Export_CCacheStatusShimMosaicRender(CVidMosaic* pThis, int nDestSurface, int x, int y, CRect* rMosaic, CRect* rClip, uint dwFlags, int bAlreadyDemanded);
int _stdcall Export_CCacheStatusShimFontRender(CVidFont* pThis, CString* pStr, void* pRawSurface, uint lPitch, int x, int y, CRect* rClip, uint dwFlags, int nUnused, int nDemanded);

int __cdecl Export_Override_audioOpen(const char* sPath, uint nFlags);
