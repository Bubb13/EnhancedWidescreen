
#include "engine_structs_bg1.h"

int EnhancedWidescreen::allowedOutOfBoundsLeft;
int EnhancedWidescreen::allowedOutOfBoundsTop;
int EnhancedWidescreen::allowedOutOfBoundsRight;
int EnhancedWidescreen::allowedOutOfBoundsBottom;
type_AssertionFailed p_AssertionFailed;
type_GetDeviceBitDepth p_GetDeviceBitDepth;
type_realloc p_realloc;
type_Unknown_007c9cc0 p_Unknown_007c9cc0;
type_Unknown_007d7ef0 p_Unknown_007d7ef0;
type_Unknown_007d7f50 p_Unknown_007d7f50;
type_Unknown_007d7f70 p_Unknown_007d7f70;
CBaldurChitin** p_g_pBaldurChitin;
DWORD* p_AsyncThreadLastTickStart;
DWORD* p_AsyncThreadTickDelta;
UINT* p_MaximumFrameRate;
short* p_ResolutionX;
short* p_ResolutionY;
HRESULT (__stdcall **p_CoInitialize)(LPVOID pvReserved);
void (__stdcall **p_CoUninitialize)();
LRESULT (__stdcall **p_DispatchMessageA)(const MSG* lpMsg);
HANDLE (__stdcall **p_GetCurrentThread)();
BOOL (__stdcall **p_GetCursorPos)(LPPOINT lpPoint);
BOOL (__stdcall **p_GetMessageA)(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
UINT (__stdcall **p_GetPrivateProfileIntA)(LPCSTR lpAppName, LPCSTR lpKeyName, INT nDefault, LPCSTR lpFileName);
DWORD (__stdcall **p_GetTickCount)();
int (__stdcall **p_MessageBoxA)(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType);
BOOL (__stdcall **p_PeekMessageA)(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg);
UINT (__stdcall **p_RegisterWindowMessageA)(LPCSTR lpString);
BOOL (__stdcall **p_SetThreadPriority)(HANDLE hThread, int nPriority);
DWORD (__stdcall **p_SuspendThread)(HANDLE hThread);
BOOL (__stdcall **p_TranslateMessage)(const MSG* lpMsg);
undefined4 (__cdecl **p_queryCompressedFunc)(char* arg0);
undefined4 (__cdecl **p_audioOpenPtr)(const char* filename, const char* mode);
undefined4 (__cdecl **p_Unknown_008a4834)(undefined4 arg0, undefined4 arg1, undefined4 arg2, undefined4 arg3);
undefined4 (__cdecl **p_Unknown_008a4838)(undefined4 arg0, undefined4 arg1, undefined4 arg2);
tag_soundstruct** p_audio;
int* p_numAudio;
CUIControlBase::type_CreateControl CUIControlBase::p_CreateControl;
CString::type_Destruct CString::p_Destruct;
CString::type_LoadStringA CString::p_LoadStringA;
CString::type_SetFromChars CString::p_SetFromChars;
const char* CString::afxPchNil;
CSingleLock::type_Construct CSingleLock::p_Construct;
CSingleLock::type_Destruct CSingleLock::p_Destruct;
CSingleLock::type_Lock CSingleLock::p_Lock;
CSingleLock::type_Unlock CSingleLock::p_Unlock;
CVidMode::type_CheckBltResult CVidMode::p_CheckBltResult;
CVidMode::type_LockTexSurface CVidMode::p_LockTexSurface;
CVidMode::type_UnlockTexSurface CVidMode::p_UnlockTexSurface;
CRes::type_DecrementDemands CRes::p_DecrementDemands;
CRes::type_DecrementRequests CRes::p_DecrementRequests;
CRes::type_Demand CRes::p_Demand;
CRes::type_Request CRes::p_Request;
CResUI::type_DecrementDemands CResUI::p_DecrementDemands;
CResUI::type_Demand CResUI::p_Demand;
CResUI::type_GetControl CResUI::p_GetControl;
CResUI::type_GetControlNo CResUI::p_GetControlNo;
CResUI::type_GetPanel CResUI::p_GetPanel;
CResUI::type_GetPanelNo CResUI::p_GetPanelNo;
CResMosaic::type_DecrementDemands CResMosaic::p_DecrementDemands;
CResMosaic::type_Demand CResMosaic::p_Demand;
CInfCursor::type_SetCursor CInfCursor::p_SetCursor;
CAIGroup::type_GroupCancelMove CAIGroup::p_GroupCancelMove;
CAIGroup::type_GroupDrawMove CAIGroup::p_GroupDrawMove;
CVidFont::type_Render CVidFont::p_Render;
CVidMosaic::type_Render CVidMosaic::p_Render;
CUIPanel::type_Construct CUIPanel::p_Construct;
CUIPanel::type_InvalidateRect CUIPanel::p_InvalidateRect;
CUIManager::type_Construct CUIManager::p_Construct;
CUIManager::type_Destruct CUIManager::p_Destruct;
CUIManager::type_GetPanel CUIManager::p_GetPanel;
CUIManager::type_Invalidate CUIManager::p_Invalidate;
CResourceManager::type_GetResObject CResourceManager::p_GetResObject;
CResourceManager::type_DumpResObject CResourceManager::p_DumpResObject;
CInfinity::type_SetViewPosition CInfinity::p_SetViewPosition;
CChitin::type_AddThread CChitin::p_AddThread;
CChitin::type_ParseCommandLine CChitin::p_ParseCommandLine;
CChitin::type_SetSyncThreadHandle CChitin::p_SetSyncThreadHandle;
CChitin::type_SetupThreads CChitin::p_SetupThreads;

template<typename OutType>
static void attemptFillPointer(const String& patternName, OutType& pointerOut) {
	PatternValueHandle patternHandle;
	switch (sharedState().GetPatternValue(patternName, patternHandle)) {
		case PatternValueType::SINGLE: {
			pointerOut = reinterpret_cast<OutType>(sharedState().GetSinglePatternValue(patternHandle));
			break;
		}
		case PatternValueType::INVALID: {
			FPrintT(TEXT("[!][EnhancedWidescreen.dll] attemptFillPointer() - Binding pattern [%s] missing; using this binding will crash the game\n"), patternName.c_str());
			break;
		}
		default: {
			FPrintT(TEXT("[!][EnhancedWidescreen.dll] attemptFillPointer() - Binding pattern [%s].Type not SINGLE; using this binding will crash the game\n"), patternName.c_str());
			break;
		}
	}
}

void InitBindingsInternal() {
	attemptFillPointer(TEXT("AssertionFailed"), p_AssertionFailed);
	attemptFillPointer(TEXT("GetDeviceBitDepth"), p_GetDeviceBitDepth);
	attemptFillPointer(TEXT("realloc"), p_realloc);
	attemptFillPointer(TEXT("Unknown_007c9cc0"), p_Unknown_007c9cc0);
	attemptFillPointer(TEXT("Unknown_007d7ef0"), p_Unknown_007d7ef0);
	attemptFillPointer(TEXT("Unknown_007d7f50"), p_Unknown_007d7f50);
	attemptFillPointer(TEXT("Unknown_007d7f70"), p_Unknown_007d7f70);
	attemptFillPointer(TEXT("g_pBaldurChitin"), p_g_pBaldurChitin);
	attemptFillPointer(TEXT("AsyncThreadLastTickStart"), p_AsyncThreadLastTickStart);
	attemptFillPointer(TEXT("AsyncThreadTickDelta"), p_AsyncThreadTickDelta);
	attemptFillPointer(TEXT("MaximumFrameRate"), p_MaximumFrameRate);
	attemptFillPointer(TEXT("ResolutionX"), p_ResolutionX);
	attemptFillPointer(TEXT("ResolutionY"), p_ResolutionY);
	attemptFillPointer(TEXT("CoInitialize"), p_CoInitialize);
	attemptFillPointer(TEXT("CoUninitialize"), p_CoUninitialize);
	attemptFillPointer(TEXT("DispatchMessageA"), p_DispatchMessageA);
	attemptFillPointer(TEXT("GetCurrentThread"), p_GetCurrentThread);
	attemptFillPointer(TEXT("GetCursorPos"), p_GetCursorPos);
	attemptFillPointer(TEXT("GetMessageA"), p_GetMessageA);
	attemptFillPointer(TEXT("GetPrivateProfileIntA"), p_GetPrivateProfileIntA);
	attemptFillPointer(TEXT("GetTickCount"), p_GetTickCount);
	attemptFillPointer(TEXT("MessageBoxA"), p_MessageBoxA);
	attemptFillPointer(TEXT("PeekMessageA"), p_PeekMessageA);
	attemptFillPointer(TEXT("RegisterWindowMessageA"), p_RegisterWindowMessageA);
	attemptFillPointer(TEXT("SetThreadPriority"), p_SetThreadPriority);
	attemptFillPointer(TEXT("SuspendThread"), p_SuspendThread);
	attemptFillPointer(TEXT("TranslateMessage"), p_TranslateMessage);
	attemptFillPointer(TEXT("queryCompressedFunc"), p_queryCompressedFunc);
	attemptFillPointer(TEXT("audioOpenPtr"), p_audioOpenPtr);
	attemptFillPointer(TEXT("Unknown_008a4834"), p_Unknown_008a4834);
	attemptFillPointer(TEXT("Unknown_008a4838"), p_Unknown_008a4838);
	attemptFillPointer(TEXT("audio"), p_audio);
	attemptFillPointer(TEXT("numAudio"), p_numAudio);
	attemptFillPointer(TEXT("CUIControlBase::CreateControl"), CUIControlBase::p_CreateControl);
	attemptFillPointer(TEXT("CString::Destruct"), CString::p_Destruct);
	attemptFillPointer(TEXT("CString::LoadStringA"), CString::p_LoadStringA);
	attemptFillPointer(TEXT("CString::operator=(char*)"), CString::p_SetFromChars);
	attemptFillPointer(TEXT("CString::afxPchNil"), CString::afxPchNil);
	attemptFillPointer(TEXT("CSingleLock::Construct"), CSingleLock::p_Construct);
	attemptFillPointer(TEXT("CSingleLock::Destruct"), CSingleLock::p_Destruct);
	attemptFillPointer(TEXT("CSingleLock::Lock"), CSingleLock::p_Lock);
	attemptFillPointer(TEXT("CSingleLock::Unlock"), CSingleLock::p_Unlock);
	attemptFillPointer(TEXT("CVidMode::CheckBltResult"), CVidMode::p_CheckBltResult);
	attemptFillPointer(TEXT("CVidMode::LockTexSurface"), CVidMode::p_LockTexSurface);
	attemptFillPointer(TEXT("CVidMode::UnlockTexSurface"), CVidMode::p_UnlockTexSurface);
	attemptFillPointer(TEXT("CRes::DecrementDemands"), CRes::p_DecrementDemands);
	attemptFillPointer(TEXT("CRes::DecrementRequests"), CRes::p_DecrementRequests);
	attemptFillPointer(TEXT("CRes::Demand"), CRes::p_Demand);
	attemptFillPointer(TEXT("CRes::Request"), CRes::p_Request);
	attemptFillPointer(TEXT("CResUI::DecrementDemands"), CResUI::p_DecrementDemands);
	attemptFillPointer(TEXT("CResUI::Demand"), CResUI::p_Demand);
	attemptFillPointer(TEXT("CResUI::GetControl"), CResUI::p_GetControl);
	attemptFillPointer(TEXT("CResUI::GetControlNo"), CResUI::p_GetControlNo);
	attemptFillPointer(TEXT("CResUI::GetPanel"), CResUI::p_GetPanel);
	attemptFillPointer(TEXT("CResUI::GetPanelNo"), CResUI::p_GetPanelNo);
	attemptFillPointer(TEXT("CResMosaic::DecrementDemands"), CResMosaic::p_DecrementDemands);
	attemptFillPointer(TEXT("CResMosaic::Demand"), CResMosaic::p_Demand);
	attemptFillPointer(TEXT("CInfCursor::SetCursor"), CInfCursor::p_SetCursor);
	attemptFillPointer(TEXT("CAIGroup::GroupCancelMove"), CAIGroup::p_GroupCancelMove);
	attemptFillPointer(TEXT("CAIGroup::GroupDrawMove"), CAIGroup::p_GroupDrawMove);
	attemptFillPointer(TEXT("CVidFont::Render"), CVidFont::p_Render);
	attemptFillPointer(TEXT("CVidMosaic::Render"), CVidMosaic::p_Render);
	attemptFillPointer(TEXT("CUIPanel::Construct"), CUIPanel::p_Construct);
	attemptFillPointer(TEXT("CUIPanel::InvalidateRect"), CUIPanel::p_InvalidateRect);
	attemptFillPointer(TEXT("CUIManager::Construct"), CUIManager::p_Construct);
	attemptFillPointer(TEXT("CUIManager::Destruct"), CUIManager::p_Destruct);
	attemptFillPointer(TEXT("CUIManager::GetPanel"), CUIManager::p_GetPanel);
	attemptFillPointer(TEXT("CUIManager::Invalidate"), CUIManager::p_Invalidate);
	attemptFillPointer(TEXT("CResourceManager::GetResObject"), CResourceManager::p_GetResObject);
	attemptFillPointer(TEXT("CResourceManager::DumpResObject"), CResourceManager::p_DumpResObject);
	attemptFillPointer(TEXT("CInfinity::SetViewPosition"), CInfinity::p_SetViewPosition);
	attemptFillPointer(TEXT("CChitin::AddThread"), CChitin::p_AddThread);
	attemptFillPointer(TEXT("CChitin::ParseCommandLine"), CChitin::p_ParseCommandLine);
	attemptFillPointer(TEXT("CChitin::SetSyncThreadHandle"), CChitin::p_SetSyncThreadHandle);
	attemptFillPointer(TEXT("CChitin::SetupThreads"), CChitin::p_SetupThreads);
}
