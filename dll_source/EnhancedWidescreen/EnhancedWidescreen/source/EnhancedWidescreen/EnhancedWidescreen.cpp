
#include <mutex>
#include <shared_mutex>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb/stb_image_write.h"

#include "InfinityLoader/infinity_loader_common_api.h"
#include "engine_structs_bg1.h"
#include "thread_watcher.h"

#include <filesystem>

//////////////////////////////////
// EnhancedWidescreen Namespace //
//////////////////////////////////

void EnhancedWidescreen::GetINIString(
    lua_State *const L,
    const char *const iniPath,
    const char *const section,
    const char *const key,
    const char *const def
)
{
    String result{};

    const DWORD lastError = GetINIStrDef(
        sharedState().WorkingFolder() + NulTermStrToStr(iniPath),
        NulTermStrToStr(section).c_str(),
        NulTermStrToStr(key).c_str(),
        NulTermStrToStr(def).c_str(),
        result
    );

    if (lastError != ERROR_SUCCESS)
    {
        FPrint("[EnhancedWidescreen.dll] EnhancedWidescreen::GetINIStr() - GetINIStrDef() failed (%d)", lastError);
        lua_pushstring(L, def);
        return;
    }

    lua_pushstring(L, StrToStrA(result).c_str());
}

static std::pair<const byte, const char *const> aSpecialVirtualKeyMappings[] = {
	{ VK_OEM_1,      ";"        },
	{ VK_OEM_PLUS,   "="        },
	{ VK_OEM_COMMA,  ","        },
	{ VK_OEM_MINUS,  "-"        },
	{ VK_OEM_PERIOD, "."        },
	{ VK_OEM_2,      "/"        },
	{ VK_OEM_3,      "`"        },
	{ VK_OEM_4,      "["        },
	{ VK_OEM_5,      "\\"       },
	{ VK_OEM_6,      "]"        },
	{ VK_OEM_7,      "'"        },
	{ VK_UP,         "Up"       },
	{ VK_LEFT,       "Left"     },
	{ VK_DOWN,       "Down"     },
	{ VK_RIGHT,      "Right"    },
	{ VK_NUMPAD0,    "Keypad 0" },
	{ VK_NUMPAD1,    "Keypad 1" },
	{ VK_NUMPAD2,    "Keypad 2" },
	{ VK_NUMPAD3,    "Keypad 3" },
	{ VK_NUMPAD4,    "Keypad 4" },
	{ VK_NUMPAD5,    "Keypad 5" },
	{ VK_NUMPAD6,    "Keypad 6" },
	{ VK_NUMPAD7,    "Keypad 7" },
	{ VK_NUMPAD8,    "Keypad 8" },
	{ VK_NUMPAD9,    "Keypad 9" },
};

byte EnhancedWidescreen::StringToVirtualKey(const char *const sAscii)
{
	const char nFirstChar = sAscii[0];

	if (nFirstChar == '\0')
	{
		return 0;
	}

	if (sAscii[1] == '\0')
	{
		// [Ascii a-z]
		if (nFirstChar >= 97 && nFirstChar <= 122)
		{
			return nFirstChar - 32;
		}

		// [Ascii A-Z]
		if (nFirstChar >= 65 && nFirstChar <= 90)
		{
			return nFirstChar;
		}

		// [Ascii 0-9]
		if (nFirstChar >= 48 && nFirstChar <= 57)
		{
			return nFirstChar;
		}
	}

	for (const auto& mapping : aSpecialVirtualKeyMappings)
	{
		if (strcmp(mapping.second, sAscii) == 0)
		{
			return mapping.first;
		}
	}

	return 0;
}

/////////////////
// Lua Utility //
/////////////////

// Expects:       0 [ ... ]
// Returns: nReturn [ ..., return1, ..., returnN ]
static bool luaCallProtected(lua_State *const L, const int nArg, const int nReturn, const std::function<void(int)> setup)
{
	const int top = lua_gettop(L);

	lua_getglobal(L, "debug");                                                                //           1 [ debug ]
	lua_getfield(L, -1, "traceback");                                                         //           2 [ debug, traceback ]

	setup(top);

	if (lua_pcall(L, nArg, nReturn, top + 2) == 0)
	{
																						      // nReturn + 2 [ debug, traceback, return1, ..., returnN ]
		lua_remove(L, top + 2);                                                               // nReturn + 1 [ debug, return1, ..., returnN ]
		lua_remove(L, top + 1);                                                               //     nReturn [ return1, ..., returnN ]
		return true;
	}
	else
	{
																						      //           3 [ debug, traceback, errorMessage ]
        FPrint("[!][EnhancedWidescreen.dll] luaCallProtected() - %s\n", lua_tostring(L, -1));
		lua_pop(L, 3);                                                                        //           0 [ ]
		return false;
	}
}

/////////////////////
// Surface Utility //
/////////////////////

static void writeLockedSurface(void* pRawSurfaceIn, int nPitchInBytes, int nLockWidth, int nLockHeight)
{
    tagRGBQUAD *const pRawSurface = reinterpret_cast<tagRGBQUAD*>(pRawSurfaceIn);

    const int nNumPixels = nLockWidth * nLockHeight;
    tagRGBQUAD *const pBuffer = reinterpret_cast<tagRGBQUAD*>(malloc(nNumPixels * 4));

    tagRGBQUAD* pRawSurfaceLineItr = pRawSurface;
    tagRGBQUAD* pBufferItr = pBuffer;

    for (int y = 0; y < nLockHeight; ++y)
    {
        tagRGBQUAD* pRawSurfaceItr = pRawSurfaceLineItr;

        for (int x = 0; x < nLockWidth; ++x, ++pRawSurfaceItr, ++pBufferItr)
        {
            pBufferItr->rgbRed = pRawSurfaceItr->rgbBlue;
            pBufferItr->rgbGreen = pRawSurfaceItr->rgbGreen;
            pBufferItr->rgbBlue = pRawSurfaceItr->rgbRed;
            pBufferItr->rgbReserved = 0xFF;
        }

        pRawSurfaceLineItr += nPitchInBytes / 4;
    }

    stbi_write_png("debug.png", nLockWidth, nLockHeight, 4, pBuffer, nLockWidth * 4);
    free(pBuffer);
}

static void writeSurface(const char *const suffix, CVidMode *const pVidMode, const int nSurface)
{
    IDirectDrawSurface *const pSurface = pVidMode->m_pTexSurfaces[nSurface];

    DDSURFACEDESC desc{};
    desc.dwSize = sizeof(DDSURFACEDESC);

    pSurface->Lock(NULL, &desc, DDLOCK_WAIT, NULL);
    tagRGBQUAD* pRawSurface = reinterpret_cast<tagRGBQUAD*>(desc.lpSurface);

    int numPixels = desc.dwWidth * desc.dwHeight;
    tagRGBQUAD *const pBuffer = reinterpret_cast<tagRGBQUAD*>(malloc(numPixels * 4));

    tagRGBQUAD* pRawSurfaceItr = pRawSurface;
    tagRGBQUAD* pBufferItr = pBuffer;
    for (int i = 0; i < numPixels; ++i, ++pRawSurfaceItr, ++pBufferItr)
    {
        pBufferItr->rgbRed = pRawSurfaceItr->rgbBlue;
        pBufferItr->rgbGreen = pRawSurfaceItr->rgbGreen;
        pBufferItr->rgbBlue = pRawSurfaceItr->rgbRed;
        pBufferItr->rgbReserved = 0xFF;
    }

    for (int i = 0; ; ++i)
    {
        const std::string fileName = std::format("{}{}.png", i, suffix);

        if (std::filesystem::exists(fileName))
        {
            continue;
        }

        stbi_write_png(fileName.c_str(), desc.dwWidth, desc.dwHeight, 4, pBuffer, desc.lPitch);
        break;
    }

    free(pBuffer);

    pSurface->Unlock(NULL);
}

///////////////
// Uncap FPS //
///////////////

std::mutex syncThreadRunMutex;
std::condition_variable syncThreadRunCondition;
std::condition_variable syncThreadRunningCondition;
bool syncThreadAllowedToRunWithoutSignal = false;
bool syncThreadRun = false;
bool syncThreadRunning = false;
bool syncThreadSpecialPending = false;
bool syncThreadSpecial = false;

void __stdcall Export_SetSyncThreadAllowedToRunWithoutSignal(bool newVal)
{
    {
        std::unique_lock<std::mutex> lock { syncThreadRunMutex };
        syncThreadAllowedToRunWithoutSignal = newVal;
    }
    syncThreadRunCondition.notify_all();
}

static void signalSyncThread(bool special = false)
{
    //FPrint("Async thread signalling sync thread\n");
    {
        std::unique_lock<std::mutex> lock { syncThreadRunMutex };
        syncThreadRun = true;
        syncThreadSpecialPending = special;
    }
    syncThreadRunCondition.notify_all();
}

static void waitForSyncThreadSignal()
{
    std::unique_lock<std::mutex> lock { syncThreadRunMutex };
    syncThreadRunCondition.wait(lock, [] { return syncThreadAllowedToRunWithoutSignal || syncThreadRun; });
    syncThreadRun = false;
    syncThreadRunning = true;
    syncThreadSpecial = syncThreadAllowedToRunWithoutSignal || syncThreadSpecialPending;
}

static void signalSyncThreadNotRunning()
{
    {
        std::unique_lock<std::mutex> lock { syncThreadRunMutex };
        syncThreadRunning = false;
    }
    syncThreadRunningCondition.notify_all();
}

void __stdcall Export_CommandAndWaitForSyncThreadYield()
{
    std::unique_lock<std::mutex> lock { syncThreadRunMutex };
    syncThreadAllowedToRunWithoutSignal = false;
    syncThreadRun = false;
    syncThreadRunningCondition.wait(lock, [] { return !syncThreadRunning; });
}

std::mutex asyncThreadRunMutex;
std::condition_variable asyncThreadRunCondition;
bool asyncThreadRun = false;

static void signalAsyncThread()
{
    //FPrint("Sync thread signalling async thread\n");
    {
        std::unique_lock<std::mutex> lock { asyncThreadRunMutex };
        asyncThreadRun = true;
    }
    asyncThreadRunCondition.notify_all();
}

static void waitForAsyncThreadSignal()
{
    std::unique_lock<std::mutex> lock { asyncThreadRunMutex };
    asyncThreadRunCondition.wait(lock, [] { return asyncThreadRun; });
    asyncThreadRun = false;
}

void CBaldurChitin::Export_AsyncThread()
{
    this->AddThread();

    const HANDLE hCurrentThread = (*p_GetCurrentThread)();
    (*p_SetThreadPriority)(hCurrentThread, THREAD_PRIORITY_TIME_CRITICAL);

    if (!this->m_bNTSmoothSoundInitialized)
    {
        this->m_bNTSmoothSoundInitialized = 1;
        this->AddThread();

        if (this->m_nPlatformId == 2)
        {
            const char *const lpFileName = this->virtual_GetIniName();

            if ((*p_GetPrivateProfileIntA)("Program Options", "NT Smooth Sound", 1, lpFileName))
            {
                (*p_SetThreadPriority)(hCurrentThread, THREAD_PRIORITY_HIGHEST);
            }
        }
    }

    // Reference:
    //     while
    //     (
    //         !this->m_bAsyncThreadDone
    //         &&
    //         WaitForSingleObject(this->m_hEventTimer, 100) != WAIT_ABANDONED
    //     )
    //     {
    //         ResetEvent(this->m_hEventTimer);

    /////////////////
    // Patch Start //
    /////////////////

    while (!this->m_bAsyncThreadDone)
    {
        waitForAsyncThreadSignal();
        //FPrint("Async thread signalled...\n");

        sharedState().ProcessThreadQueue();

        ///////////////
        // Patch End //
        ///////////////

        const DWORD tickCount = (*p_GetTickCount)();

        *p_AsyncThreadTickDelta = tickCount - *p_AsyncThreadLastTickStart;

        if (*p_AsyncThreadTickDelta >= (1000 / *p_MaximumFrameRate) - 10)
        {
            *p_AsyncThreadLastTickStart = tickCount;

            this->m_bInAsyncUpdate = 1;

            if (this->m_bInSyncUpdate)
            {
                FPrint("Async thread running concurrently with sync thread!\n");
            }

            this->virtual_AsynchronousUpdate(0, 0, 0, 0, 0);

            this->m_bInAsyncUpdate = 0;
            this->m_bDisplayStale = 1;

            if (this->m_bAsyncThreadDone)
            {
                (*p_SuspendThread)(this->m_hAsyncThread);
            }
        }

        /////////////////
        // Patch Start //
        /////////////////

        signalSyncThread();

        ///////////////
        // Patch End //
        ///////////////
    }
}

WPARAM CChitin::Export_Update(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd) {

    this->m_nQueryCancelAutoPlayMsg = (*p_RegisterWindowMessageA)("QueryCancelAutoPlay");

    this->m_lpCmdLine = lpCmdLine;
    this->ParseCommandLine();

    if (!this->m_bFullScreen)
    {
        const int nBitDepth = p_GetDeviceBitDepth();

        if (nBitDepth != 16 && nBitDepth != 24 && nBitDepth != 32)
        {
            EngineVal<CString> errorStr{};

            /////////////////
            // Patch Start //
            /////////////////

            // Bugfix - LoadStringA() call not present in oBG1
            errorStr->LoadStringA(this->virtual_GetVideoModeErrorResourceStringID());

            ///////////////
            // Patch End //
            ///////////////

            (*p_MessageBoxA)(NULL, errorStr->m_pchData, this->m_sProductName, 0);
            return 0;
        }
    }

    if (!this->virtual_RegisterCreateWindow(hInstance, nShowCmd))
    {
        return 0;
    }

    (*p_CoInitialize)(NULL);
    this->SetSyncThreadHandle();
    this->SetupThreads();

    MSG message;

    while (true)
    {
        if ((*p_PeekMessageA)(&message, NULL, 0, 0, 0))
        {
            if (!(*p_GetMessageA)(&message, NULL, 0, 0))
            {
                break;
            }

            (*p_TranslateMessage)(&message);
            (*p_DispatchMessageA)(&message);
            continue;
        }

        /////////////////
        // Patch Start //
        /////////////////

        if (!syncThreadSpecial)
        {
            signalAsyncThread();
        }

        waitForSyncThreadSignal();
        //FPrint("Sync thread signalled...\n");

        sharedState().ProcessThreadQueue();

        // Always run SynchronousUpdate()
        this->m_bDisplayStale = 1;

        ///////////////
        // Patch End //
        ///////////////

        if (!this->m_bShuttingDown && this->m_bDisplayStale)
        {
            this->m_bInSyncUpdate = true;
            this->m_bDisplayStale = false;

            if (this->m_bInAsyncUpdate && !syncThreadSpecial)
            {
                FPrint("Sync thread running concurrently with async thread!\n");
            }

            this->virtual_SynchronousUpdate();

            this->m_bInSyncUpdate = false;

            /////////////////
            // Patch Start //
            /////////////////

            signalSyncThreadNotRunning();
            //FPrint("Sync thread sleeping\n");
            Sleep(1);
            //FPrint("Sync thread woke up\n");

            ///////////////
            // Patch End //
            ///////////////
        }
    }

    (*p_CoUninitialize)();
    return message.wParam;
}

void __stdcall Export_SignalSyncThread(uintptr_t esp)
{
    //FPrint("[Thread 0x%X] [0x%X] Signaling sync thread...\n", GetCurrentThreadId(), esp);
    signalSyncThread(true);
}

/////////////////////////
// Thread Entry Points //
/////////////////////////

std::unordered_map<DWORD, std::string> threadNames{};
std::shared_mutex threadNamesMutex{};

static std::string getCurrentThreadName()
{
    {
        std::shared_lock lk { threadNamesMutex };
        if (auto itr = threadNames.find(GetCurrentThreadId()); itr != threadNames.end())
        {
            return itr->second;
        }
    }
    static std::string UNKNOWN_STR { "<UNKNOWN>" };
    return UNKNOWN_STR;
}

static void registerThreadName(const char *const threadName)
{
    const DWORD threadId = GetCurrentThreadId();

    {
        std::unique_lock lk { threadNamesMutex };
        threadNames[threadId] = threadName;
    }

    if (threadWatcherMappedMemory == nullptr)
    {
        return;
    }

    for (ThreadNameEntry& threadNameEntry : threadWatcherMappedMemory->threadNames)
    {
        DWORD expected = 0;
        if (threadNameEntry.threadId.compare_exchange_strong(expected, threadId))
        {
            strcpy_s(threadNameEntry.threadName, threadName);
            break;
        }
    }
    threadWatcherMappedMemory->threadNamesHaveUpdate = true;
}

static void onThreadEntry(const char *const threadName)
{
    registerThreadName(threadName);
    if (threadWatcherMappedMemory == nullptr) return;
    ThreadSlot& threadSlot = *threadWatcherMappedMemory->ClaimSlot();
    threadSlot.alwaysShow = true;
}

void __stdcall Export_OnSyncThreadEntry()
{
    onThreadEntry("Render");
}

void __stdcall Export_OnSearchThreadEntry()
{
    onThreadEntry("Pathfinding");
}

void __stdcall Export_OnResourceManagerThreadEntry()
{
    onThreadEntry("Resource Manager");
}

void __stdcall Export_OnNetworkThreadEntry()
{
    onThreadEntry("Network");
}

void __stdcall Export_OnAsyncThreadEntry()
{
    onThreadEntry("Logic");
}

///////////
// Debug //
///////////

void __stdcall Export_OnBeforeLockObject(uintptr_t returnPtr, uintptr_t objectAddress)
{
    ThreadWatcherBeforeLockObject(returnPtr, objectAddress);
}

void __stdcall Export_OnAfterLockObject(uintptr_t objectAddress)
{
    ThreadWatcherAfterLockObject(objectAddress);
}

void __stdcall Export_OnUnlockingObject(uintptr_t returnPtr, uintptr_t objectAddress)
{
    ThreadWatcherUnlockObject(objectAddress);
}

///////////////
// Overrides //
///////////////

static void getViewportThresholds(CInfinity* pInfinity,
    int& scrollLeftDoneThresholdOut,
    int& scrollUpDoneThresholdOut,
    int& scrollRightDoneThresholdOut,
    int& scrollDownDoneThresholdOut)
{
    CRect& rViewPort = pInfinity->m_rViewPort;
    scrollLeftDoneThresholdOut = -EnhancedWidescreen::allowedOutOfBoundsLeft;
    scrollUpDoneThresholdOut = -EnhancedWidescreen::allowedOutOfBoundsTop;
    scrollRightDoneThresholdOut = rViewPort.left + (pInfinity->m_nAreaWidth - rViewPort.right) + EnhancedWidescreen::allowedOutOfBoundsRight;
    scrollDownDoneThresholdOut = rViewPort.top + (pInfinity->m_nAreaHeight - rViewPort.bottom) + EnhancedWidescreen::allowedOutOfBoundsBottom;
}

static void getWorldCoordinates(const CInfinity *const pInfinity, CPoint *const pPointWorldOut, const CPoint *const pPointScreen, const bool bCheckUI)
{
    bool luaRejected = false;

    if (bCheckUI)
    {
        lua_State *const L = luaState();

        const bool luaCallSuccess = luaCallProtected(L, 2, 1, [&](const int)
        {
            lua_getglobal(L, "EnhancedWidescreen_GUI_Extern_RejectGetWorldCoordinates");
            lua_pushinteger(L, pPointScreen->x);
            lua_pushinteger(L, pPointScreen->y);
        });

        if (luaCallSuccess)
        {
            luaRejected = lua_toboolean(L, -1);
            lua_pop(L, 1);
        }
    }

    if
    (
        !luaRejected
        &&
        pPointScreen->x >= pInfinity->m_rViewPort.left
        &&
        pPointScreen->x <= pInfinity->m_rViewPort.right
        &&
        pPointScreen->y >= pInfinity->m_rViewPort.top
        &&
        pPointScreen->y <= pInfinity->m_rViewPort.bottom
    )
    {
        pPointWorldOut->x = pInfinity->m_nNewX + (pPointScreen->x - pInfinity->m_rViewPort.left);
        pPointWorldOut->y = pInfinity->m_nNewY + (pPointScreen->y - pInfinity->m_rViewPort.top);
    }
    else
    {
        pPointWorldOut->x = -1;
        pPointWorldOut->y = -1;
    }
}

CPoint* CInfinity::Export_Override_GetWorldCoordinates(CPoint* pPointWorldOut, CPoint* pPointScreen)
{
    getWorldCoordinates(this, pPointWorldOut, pPointScreen, true);
    return pPointWorldOut;
}

void CGameArea::Export_Override_OnMouseMove(CPoint* pPoint)
{
    if (this->m_bAreaLoaded == 0)
    {
        return;
    }

    CInfinity& infinity = this->m_cInfinity;
    CInfCursor& cursor = *(*p_g_pBaldurChitin)->m_pObjectCursor;

    const int nNewX = infinity.m_nNewX;
    const int nNewY = infinity.m_nNewY;
    const CRect& rViewPort = infinity.m_rViewPort;

    CPoint worldCoordinates;

    if (pPoint->x != -1)
    {
        getWorldCoordinates(&infinity, &worldCoordinates, pPoint, false);
    }
    else
    {
        worldCoordinates.x = -2;
        worldCoordinates.y = -2;
    }

    this->m_cursorPos.x = pPoint->x;
    this->m_cursorPos.y = pPoint->y;
    this->m_nToolTip = 0;

    if (!this->m_groupMove || worldCoordinates.x < -1)
    {
        ///////////////////////////
        // NOT drawing formation //
        ///////////////////////////

        if (this->m_selectSquare.left != -1 && worldCoordinates.x > -2)
        {
            //////////////////////////////////
            // Update selection square rect //
            //////////////////////////////////

            const int pointViewportOffsetX = min(max(0, pPoint->x - rViewPort.left), rViewPort.right - rViewPort.left - 1);
            const int pointViewportOffsetY = min(max(0, pPoint->y - rViewPort.top), rViewPort.bottom - rViewPort.top - 1);

            this->m_selectSquare.right = nNewX + pointViewportOffsetX;
            this->m_selectSquare.bottom = nNewY + pointViewportOffsetY;

            const int selectSquareWidth = abs(this->m_selectSquare.right - this->m_selectSquare.left);
            const int selectSquareHeight = abs(this->m_selectSquare.bottom - this->m_selectSquare.top);

            //////////////////////////
            // Check draw formation //
            //////////////////////////

            int newCursor = 0; // Unpressed hand cursor

            if (selectSquareWidth < 9 && selectSquareHeight < 9)
            {
                ///////////////////////
                // Drawing formation //
                ///////////////////////

                if (cursor.m_nCurrentCursor == 4)
                {
                    this->m_pGame->m_group.GroupDrawMove(
                        this->m_moveDest.x, this->m_moveDest.y,
                        this->m_pGame->m_curFormation,
                        -1, -1
                    );
                }
                else
                {
                    this->m_pGame->m_group.GroupCancelMove();
                }

                newCursor = 4; // Unpressed movement cursor
            }
            else
            {
                ///////////////////////////
                // NOT drawing formation //
                ///////////////////////////

                this->m_pGame->m_group.GroupCancelMove();
            }

            /////////////////////////
            // Update cursor shape //
            /////////////////////////

            if (this->m_pGame->m_nState == 0) // Cursor not in targetting mode
            {
                this->m_pGame->m_tempCursor = newCursor;
            }
        }
    }
    else
    {
        ////////////////////
        // Draw formation //
        ////////////////////

        const int absWorldMoveOffsetX = abs(worldCoordinates.x - this->m_moveDest.x);
        const int absWorldMoveOffsetY = abs(worldCoordinates.y - this->m_moveDest.y);

        if (absWorldMoveOffsetX < 9 && absWorldMoveOffsetY < 9)
        {
            ////////////////////////////////////////////////////////
            // Draw formation WITHOUT rotation relative to cursor //
            ////////////////////////////////////////////////////////

            if
            (
                cursor.m_nCurrentCursor == 4 // Unpressed movement cursor
                ||
                cursor.m_nCurrentCursor == 8 // Rotating formation cursor
            )
            {
                this->m_pGame->m_group.GroupDrawMove(
                    this->m_moveDest.x, this->m_moveDest.y,
                    this->m_pGame->m_curFormation,
                    -1, -1
                );
            }
            else
            {
                this->m_pGame->m_group.GroupCancelMove();
            }

            if (this->m_pGame->m_nState == 0) // Cursor not in targetting mode
            {
                this->m_pGame->m_tempCursor = 4; // Unpressed movement cursor
            }
        }
        else
        {
            /////////////////////////////////////////////////////
            // Draw formation with rotation relative to cursor //
            /////////////////////////////////////////////////////

            if
            (
                pPoint->x >= rViewPort.left
                ||
                pPoint->x < rViewPort.right
                ||
                pPoint->y >= rViewPort.top
                ||
                pPoint->y < rViewPort.bottom
            )
            {
                ///////////////////////
                // Point in viewport //
                ///////////////////////

                worldCoordinates.x = this->m_moveDest.x * 2 - worldCoordinates.x;
                worldCoordinates.y = this->m_moveDest.y * 2 - worldCoordinates.y;
            }
            else
            {
                ///////////////////////////
                // Point NOT in viewport //
                ///////////////////////////

                CPoint screenPoint;
                screenPoint.x = min(max(rViewPort.left, pPoint->x), rViewPort.right - 1);
                screenPoint.y = min(max(rViewPort.top, pPoint->y), rViewPort.bottom - 1);

                CPoint worldPoint;
                getWorldCoordinates(&infinity, &worldPoint, &screenPoint, false);

                worldCoordinates.x = this->m_moveDest.x * 2 - worldPoint.x;
                worldCoordinates.y = this->m_moveDest.y * 2 - worldPoint.y;
            }

            this->m_pGame->m_group.GroupDrawMove(
                this->m_moveDest.x, this->m_moveDest.y,
                this->m_pGame->m_curFormation,
                worldCoordinates.x, worldCoordinates.y
            );

            if (this->m_pGame->m_nState == 0) // Cursor not in targetting mode
            {
                this->m_pGame->m_tempCursor = 8; // Rotating formation cursor
            }
        }

        //////////////////////////////////
        // Update selection square rect //
        //////////////////////////////////

        if
        (
            this->m_pGame->m_nState == 3 // Cursor in guard mode
            &&
            this->m_selectSquare.left != -1
        )
        {
            const int pointViewportOffsetX = min(max(0, pPoint->x - rViewPort.left), (rViewPort.right - rViewPort.left) - 1);
            const int pointViewportOffsetY = min(max(0, pPoint->y - rViewPort.top), (rViewPort.bottom - rViewPort.top) - 1);

            this->m_selectSquare.right = nNewX + pointViewportOffsetX;
            this->m_selectSquare.bottom = nNewY + pointViewportOffsetY;
        }
    }

    /////////////////////////
    // Update scroll state //
    /////////////////////////

    if (this->m_firstRender == 0)
    {
        const short resolutionX = *p_ResolutionX;
        const short resolutionY = *p_ResolutionY;

        const int leftEdgeX = 0;
        const int rightEdgeX = resolutionX - 1;
        const int topEdgeY = 0;
        const int bottomEdgeY = resolutionY - 1;

        int viewportScrollLeftDoneThreshold;
        int viewportScrollUpDoneThreshold;
        int viewportScrollRightDoneThreshold;
        int viewportScrollDownDoneThreshold;

        getViewportThresholds(&infinity,
            viewportScrollLeftDoneThreshold, viewportScrollUpDoneThreshold,
            viewportScrollRightDoneThreshold, viewportScrollDownDoneThreshold
        );

        const int xLeftCornerThreshold = resolutionX / 16;
        const int xRightCornerThreshold = resolutionX - resolutionX / 16;

        const int yTopCornerThreshold = resolutionY / 12;
        const int yBottomCornerThreshold = resolutionY - resolutionY / 12;

        if (pPoint->x == leftEdgeX)
        {
            /////////////////////////
            // Cursor on left edge //
            /////////////////////////

            if (pPoint->y <= yTopCornerThreshold)
            {
                ////////////////////////
                // Cursor in top-left //
                ////////////////////////

                if
                (
                    nNewX <= viewportScrollLeftDoneThreshold
                    &&
                    nNewY <= viewportScrollUpDoneThreshold
                )
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }
                else
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 8;
                }

                cursor.m_nDirection = 7;
            }
            else if (pPoint->y <= yBottomCornerThreshold)
            {
                ///////////////////////////
                // Cursor in middle-left //
                ///////////////////////////

                if (nNewX <= viewportScrollLeftDoneThreshold)
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }
                else
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 7;
                }

                cursor.m_nDirection = 6;
            }
            else
            {
                ///////////////////////////
                // Cursor in bottom-left //
                ///////////////////////////

                if
                (
                    nNewX <= viewportScrollLeftDoneThreshold
                    &&
                    nNewY >= viewportScrollDownDoneThreshold
                )
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }
                else
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 6;
                }

                cursor.m_nDirection = 5;
            }
        }
        else if (pPoint->x == rightEdgeX)
        {
            //////////////////////////
            // Cursor on right edge //
            //////////////////////////

            if (pPoint->y <= yTopCornerThreshold)
            {
                /////////////////////////
                // Cursor in top-right //
                /////////////////////////

                if
                (
                    nNewX < viewportScrollRightDoneThreshold
                    ||
                    nNewY > viewportScrollUpDoneThreshold
                )
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 2;
                }
                else
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }

                cursor.m_nDirection = 1;
            }
            else if (pPoint->y <= yBottomCornerThreshold)
            {
                ////////////////////////////
                // Cursor in middle-right //
                ////////////////////////////

                if (nNewX < viewportScrollRightDoneThreshold)
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 3;
                }
                else
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }

                cursor.m_nDirection = 2;
            }
            else
            {
                ////////////////////////////
                // Cursor in bottom-right //
                ////////////////////////////

                if
                (
                    nNewX < viewportScrollRightDoneThreshold
                    ||
                    nNewY < viewportScrollDownDoneThreshold
                )
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 4;
                }
                else
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }

                cursor.m_nDirection = 3;
            }
        }
        else if (pPoint->y == topEdgeY)
        {
            ////////////////////////
            // Cursor on top edge //
            ////////////////////////

            if (pPoint->x <= xLeftCornerThreshold)
            {
                ////////////////////////
                // Cursor in top-left //
                ////////////////////////

                if
                (
                    nNewX <= viewportScrollLeftDoneThreshold
                    &&
                    nNewY <= viewportScrollUpDoneThreshold
                )
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }
                else
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 8;
                }

                cursor.m_nDirection = 7;
            }
            else if (pPoint->x <= xRightCornerThreshold)
            {
                //////////////////////////
                // Cursor in top-middle //
                //////////////////////////

                if (nNewY <= viewportScrollUpDoneThreshold)
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }
                else
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 1;
                }

                cursor.m_nDirection = 0;
            }
            else
            {
                /////////////////////////
                // Cursor in top-right //
                /////////////////////////

                if
                (
                    nNewX < viewportScrollRightDoneThreshold
                    ||
                    nNewY > viewportScrollUpDoneThreshold
                )
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 2;
                }
                else
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }

                cursor.m_nDirection = 1;
            }
        }
        else if (pPoint->y == bottomEdgeY)
        {
            ///////////////////////////
            // Cursor on bottom edge //
            ///////////////////////////

            if (pPoint->x <= xLeftCornerThreshold)
            {
                ///////////////////////////
                // Cursor in bottom-left //
                ///////////////////////////

                if
                (
                    nNewX <= viewportScrollLeftDoneThreshold
                    &&
                    nNewY >= viewportScrollDownDoneThreshold
                )
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }
                else
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 6;
                }

                cursor.m_nDirection = 5;
            }
            else if (pPoint->x <= xRightCornerThreshold)
            {
                /////////////////////////////
                // Cursor in bottom-middle //
                /////////////////////////////

                if (nNewY < viewportScrollDownDoneThreshold)
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 5;
                }
                else
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }

                cursor.m_nDirection = 4;
            }
            else
            {
                ////////////////////////////
                // Cursor in bottom-right //
                ////////////////////////////

                if
                (
                    nNewX < viewportScrollRightDoneThreshold
                    ||
                    nNewY < viewportScrollDownDoneThreshold
                )
                {
                    cursor.SetCursor(100, 0); // Arrow cursor (scrolling)
                    this->m_nScrollState = 4;
                }
                else
                {
                    cursor.SetCursor(6, 0); // No action cursor
                    this->m_nScrollState = 9;
                }

                cursor.m_nDirection = 3;
            }
        }
        else
        {
            ///////////////////////////////
            // Cursor not on window edge //
            ///////////////////////////////

            this->m_nScrollState = 0;
            infinity.m_nScrollDelay = 15;
        }
    }
    else
    {
        /////////////////////////////////////////////
        // Don't scroll on first world render pass //
        /////////////////////////////////////////////

        this->m_nScrollState = 0;
        infinity.m_nScrollDelay = 15;
    }
}

static int setViewPositionOverride(CInfinity* pInfinity, int x, int y, byte bSetExactScale, bool checkBounds)
{
    /////////////////////////////
    // Enforce viewport bounds //
    /////////////////////////////

    if (checkBounds)
    {
        int viewportScrollLeftDoneThreshold;
        int viewportScrollUpDoneThreshold;
        int viewportScrollRightDoneThreshold;
        int viewportScrollDownDoneThreshold;

        getViewportThresholds(pInfinity,
            viewportScrollLeftDoneThreshold, viewportScrollUpDoneThreshold,
            viewportScrollRightDoneThreshold, viewportScrollDownDoneThreshold
        );

        if (x < viewportScrollLeftDoneThreshold)
        {
            x = viewportScrollLeftDoneThreshold;
            pInfinity->m_ptCurrentPosExact.x = x * 10000;
        }

        if (x > viewportScrollRightDoneThreshold)
        {
            x = viewportScrollRightDoneThreshold;
            pInfinity->m_ptCurrentPosExact.x = x * 10000;
        }

        if (y < viewportScrollUpDoneThreshold)
        {
            y = viewportScrollUpDoneThreshold;
            pInfinity->m_ptCurrentPosExact.y = y * 10000;
        }

        if (y > viewportScrollDownDoneThreshold)
        {
            y = viewportScrollDownDoneThreshold;
            pInfinity->m_ptCurrentPosExact.y = y * 10000;
        }
    }

    //////////////////////////////////////////////////////////////
    // Center area if it is smaller than the main viewport rect //
    //////////////////////////////////////////////////////////////

    const int nViewportWidth = pInfinity->m_rViewPort.right - pInfinity->m_rViewPort.left;
    const int nViewportHeight = pInfinity->m_rViewPort.bottom - pInfinity->m_rViewPort.top;

    const int nEffectiveViewportWidth = nViewportWidth - EnhancedWidescreen::allowedOutOfBoundsLeft - EnhancedWidescreen::allowedOutOfBoundsRight;
    const int nEffectiveViewportHeight = nViewportHeight - EnhancedWidescreen::allowedOutOfBoundsTop - EnhancedWidescreen::allowedOutOfBoundsBottom;

    if (nEffectiveViewportWidth > pInfinity->m_nAreaWidth)
    {
        x = (pInfinity->m_nAreaWidth - nViewportWidth - EnhancedWidescreen::allowedOutOfBoundsLeft + EnhancedWidescreen::allowedOutOfBoundsRight) / 2;
        pInfinity->m_ptCurrentPosExact.x = x * 10000;
    }

    if (nEffectiveViewportHeight > pInfinity->m_nAreaHeight)
    {
        y = (pInfinity->m_nAreaHeight - nViewportHeight - EnhancedWidescreen::allowedOutOfBoundsTop + EnhancedWidescreen::allowedOutOfBoundsBottom) / 2;
        pInfinity->m_ptCurrentPosExact.y = y * 10000;
    }

    //////////////////////////
    // Update view position //
    //////////////////////////

    EngineVal<CSingleLock> lk { &pInfinity->m_viewPositionLock, TRUE };

    pInfinity->m_nNewX = x;
    pInfinity->m_nNewY = y;

    if (bSetExactScale != 0)
    {
        pInfinity->m_ptCurrentPosExact.x = pInfinity->m_nNewX * 10000;
        pInfinity->m_ptCurrentPosExact.y = pInfinity->m_nNewY * 10000;
    }

    pInfinity->m_updateListenPosition = 1;
    return 1;
}

int CInfinity::Export_Override_SetViewPosition(int x, int y, byte bSetExactScale)
{
    return setViewPositionOverride(this, x, y, bSetExactScale, true);
}

int CInfinity::Export_SetViewPositionAdjustToCenter(int x, int y, byte bSetExactScale)
{
    x -= (EnhancedWidescreen::allowedOutOfBoundsLeft - EnhancedWidescreen::allowedOutOfBoundsRight) / 2;
    y -= (EnhancedWidescreen::allowedOutOfBoundsTop - EnhancedWidescreen::allowedOutOfBoundsBottom) / 2;
    return setViewPositionOverride(this, x, y, bSetExactScale, true);
}

int CInfinity::Export_SetViewPositionIgnoreBounds(int x, int y, byte bSetExactScale)
{
    return setViewPositionOverride(this, x, y, bSetExactScale, false);
}

void __stdcall Export_Patch_CGameArea_AIUpdate_CheckCursorScroll(CGameArea *const pArea)
{
    CInfinity& infinity = pArea->m_cInfinity;

    if (pArea->m_firstRender)
    {
        pArea->m_nScrollState = 0;
        infinity.m_nScrollDelay = 15;
        return;
    }

    CInfCursor& cursor = *(*p_g_pBaldurChitin)->m_pObjectCursor;

    const int newX = infinity.m_nNewX;
    const int newY = infinity.m_nNewY;
    const CRect& rViewport = infinity.m_rViewPort;

    const int leftEdgeX = 0;
    const int rightEdgeX = *p_ResolutionX - 1;
    const int topEdgeY = 0;
    const int bottomEdgeY = *p_ResolutionY - 1;

    int viewportScrollLeftDoneThreshold;
    int viewportScrollUpDoneThreshold;
    int viewportScrollRightDoneThreshold;
    int viewportScrollDownDoneThreshold;

    getViewportThresholds(&infinity,
        viewportScrollLeftDoneThreshold, viewportScrollUpDoneThreshold,
        viewportScrollRightDoneThreshold, viewportScrollDownDoneThreshold
    );

    if
    (
        pArea->m_cursorPos.x == leftEdgeX
        &&
        newX <= viewportScrollLeftDoneThreshold
    )
    {
        ///////////////////////////////////////////////////
        // Cursor on left edge and viewport at left edge //
        ///////////////////////////////////////////////////

        if
        (
            pArea->m_nScrollState == 7 // left
            ||
            (
                pArea->m_nScrollState == 8 // top-left
                &&
                newY <= viewportScrollUpDoneThreshold
            )
            ||
            (
                pArea->m_nScrollState == 6 // bottom-left
                &&
                newY >= viewportScrollDownDoneThreshold
            )
        )
        {
            cursor.SetCursor(6, 0); // No action cursor
            cursor.m_nDirection = 6;
            pArea->m_nScrollState = 9;
        }
    }
    else if
    (
        pArea->m_cursorPos.x == rightEdgeX
        &&
        newX >= viewportScrollRightDoneThreshold
    )
    {
        /////////////////////////////////////////////////////
        // Cursor on right edge and viewport at right edge //
        /////////////////////////////////////////////////////

        if
        (
            pArea->m_nScrollState == 3 // right
            ||
            (
                pArea->m_nScrollState == 2 // top-right
                &&
                newY <= viewportScrollUpDoneThreshold
            )
            ||
            (
                pArea->m_nScrollState == 4 // bottom-right
                &&
                newY >= viewportScrollDownDoneThreshold
            )
        )
        {
            cursor.SetCursor(6, 0); // No action cursor
            cursor.m_nDirection = 2;
            pArea->m_nScrollState = 9;
        }
    }
    else if
    (
        pArea->m_cursorPos.y == topEdgeY
        &&
        newY <= viewportScrollUpDoneThreshold
    )
    {
        /////////////////////////////////////////////////
        // Cursor on top edge and viewport at top edge //
        /////////////////////////////////////////////////

        if
        (
            pArea->m_nScrollState == 1 // top
            ||
            (
                pArea->m_nScrollState == 8 // top-left
                &&
                newX <= viewportScrollLeftDoneThreshold
            )
            ||
            (
                pArea->m_nScrollState == 2 // top-right
                &&
                newX >= viewportScrollRightDoneThreshold
            )
        )
        {
            cursor.SetCursor(6, 0); // No action cursor
            cursor.m_nDirection = 0;
            pArea->m_nScrollState = 9;
        }
    }
    else if
    (
        pArea->m_cursorPos.y == bottomEdgeY
        &&
        newY >= viewportScrollDownDoneThreshold
        &&
        (
            pArea->m_nScrollState == 5 // bottom
            ||
            (
                pArea->m_nScrollState == 6 // bottom-left
                &&
                newX <= viewportScrollLeftDoneThreshold
            )
            ||
            (
                pArea->m_nScrollState == 4 // bottom-right
                &&
                newX >= viewportScrollRightDoneThreshold
            )
        )
    )
    {
        cursor.SetCursor(6, 0); // No action cursor
        cursor.m_nDirection = 4;
        pArea->m_nScrollState = 9;
    }
}

static void bltColorFill(CVidMode* pVidMode, IDirectDrawSurface* pSurface, DWORD color)
{
    DDBLTFX fx{};
    fx.dwSize = sizeof(DDBLTFX);
    fx.dwFillColor = color;

    int bltSuccess;
    do
    {
        bltSuccess = pVidMode->CheckBltResult(pSurface->Blt(nullptr, nullptr, nullptr, DDBLT_COLORFILL | DDBLT_WAIT, &fx));
    }
    while (!bltSuccess);
}

CWarp* pBlankBackBufferLastActiveEngine = nullptr;
int nBlankBackBufferCounter = 0;
int nBlankCCacheCounter = 0;

void __stdcall Export_BlankCCache1()
{
    nBlankCCacheCounter = 1;

    CVidMode *const pVidMode = (*p_g_pBaldurChitin)->m_pActiveEngine->m_pVidMode;
    bltColorFill(pVidMode, pVidMode->m_pTexSurfaces[0], 0x000000);
}

void __stdcall Export_BlankCCache2()
{
    if (nBlankCCacheCounter-- > 0)
    {
        CVidMode *const pVidMode = (*p_g_pBaldurChitin)->m_pActiveEngine->m_pVidMode;
        bltColorFill(pVidMode, pVidMode->m_pTexSurfaces[0], 0x000000);
    }
}

void __stdcall Export_BlankCCache3()
{
    CVidMode *const pVidMode = (*p_g_pBaldurChitin)->m_pActiveEngine->m_pVidMode;
    bltColorFill(pVidMode, pVidMode->m_pTexSurfaces[0], 0x000000);
}

void __stdcall Export_BlankBackBuffer(CWarp* pActiveEngine)
{
    if (pActiveEngine != pBlankBackBufferLastActiveEngine)
    {
        nBlankBackBufferCounter = 2;
    }
    pBlankBackBufferLastActiveEngine = pActiveEngine;

    if (nBlankBackBufferCounter-- > 0)
    {
        CVidMode *const pVidMode = pActiveEngine->m_pVidMode;
        bltColorFill(pVidMode, pVidMode->m_pTexSurfaces[0], 0x000000);
    }
}

int _stdcall Export_CCacheStatusShimMosaicRender(CVidMosaic* pThis, int nDestSurface, int x, int y, CRect* rMosaic, CRect* rClip, uint dwFlags, int bAlreadyDemanded)
{
    char resrefStr[9];
    memcpy(resrefStr, pThis->m_cResRef.m_resRef.data, 8);
    resrefStr[8] = '\0';

    const int additionalX = (*p_ResolutionX - 640) / 2;
    const int additionalY = (*p_ResolutionY - 480) / 2;

    CRect rMosaicAdjusted = *rMosaic;
    CRect rClipAdjusted = *rClip;

    if
    (
        strncmp(pThis->m_cResRef.m_resRef.data, "GPROGBAR", 8) == 0
        ||
        strncmp(pThis->m_cResRef.m_resRef.data, "GTRSCRN", 8) == 0)
    {
        rMosaicAdjusted.right = 640;
        rMosaicAdjusted.bottom = 480;
    }
    else if (strncmp(pThis->m_cResRef.m_resRef.data, "GTRBPBAR", 8) == 0)
    {
        rClipAdjusted.left += additionalX;
        rClipAdjusted.right += additionalX;
    }

    //FPrint("rMosaic - resref: %s, left: %d, top: %d, right: %d, bottom: %d\n", resrefStr, rMosaic->left, rMosaic->top, rMosaic->right, rMosaic->bottom);
    //FPrint("rClip - resref: %s, left: %d, top: %d, right: %d, bottom: %d\n", resrefStr, rClip->left, rClip->top, rClip->right, rClip->bottom);
    return pThis->Render(
        nDestSurface,
        x + additionalX,
        y + additionalY,
        &rMosaicAdjusted, &rClipAdjusted, dwFlags, bAlreadyDemanded);
}

int _stdcall Export_CCacheStatusShimFontRender(
    CVidFont* pThis, CString* pStr, void* pRawSurface, uint lPitch, int x, int y, CRect* rClip, uint dwFlags, int nUnused, int nDemanded)
{
    //FPrint("FONT rClip - left: %d, top: %d, right: %d, bottom: %d\n", rClip->left, rClip->top, rClip->right, rClip->bottom);

    const int additionalX = (*p_ResolutionX - 640) / 2;
    const int additionalY = (*p_ResolutionY - 480) / 2;

    return pThis->Render(pStr, pRawSurface, lPitch,
        x + additionalX,
        y + additionalY,
        rClip, dwFlags, nUnused, nDemanded);
}

int __cdecl Export_Override_audioOpen(const char* sPath, uint nFlags)
{
    char sPathCopy[MAX_PATH]; // Bugfix: Increased from 80
    strcpy(sPathCopy, sPath);

    undefined4 queryCompressedFuncResult = (*p_queryCompressedFunc)(sPathCopy);

    char sUnknown[3];
    int nNumUnknownChars;

    if ((nFlags & 1) == 0)
    {
        if ((nFlags & 2) != 0)
        {
            sUnknown[0] = 'w';
            sUnknown[1] = '+';
            nNumUnknownChars = 2;
        }
        else
        {
            sUnknown[0] = 'r';
            nNumUnknownChars = 1;
        }
    }
    else
    {
        sUnknown[0] = 'w';
        nNumUnknownChars = 1;
    }

    if ((nFlags & 0x4000) == 0)
    {
        if ((nFlags & 0x8000) != 0)
        {
            sUnknown[nNumUnknownChars] = 'b';
        }
    }
    else
    {
        sUnknown[nNumUnknownChars] = 't';
    }

    const undefined4 audioOpenPtrResult = (*p_audioOpenPtr)(sPathCopy, sUnknown);

    if (audioOpenPtrResult == 0)
    {
        return -1;
    }

    int nOpenAudioIndex = 0;

    for (; nOpenAudioIndex < *p_numAudio; ++nOpenAudioIndex)
    {
        if (((*p_audio)[nOpenAudioIndex]._0x0 & 1) == 0)
        {
            break;
        }
    }

    if (nOpenAudioIndex == *p_numAudio)
    {
        if (*p_audio == nullptr)
        {
            *p_audio = reinterpret_cast<tag_soundstruct*>(p_malloc(0x28));
        }
        else
        {
            *p_audio = reinterpret_cast<tag_soundstruct*>(p_realloc(*p_audio, (*p_numAudio + 1) * 0x28));
        }

        ++(*p_numAudio);
    }

    tag_soundstruct *const pAudio = &(*p_audio)[nOpenAudioIndex];
    pAudio->_0x0 = 1;
    pAudio->_0x4 = audioOpenPtrResult;

    if ((-(queryCompressedFuncResult != 0) & 2U) != 2)
    {
        pAudio->_0x18 = p_Unknown_007d7f70(pAudio->_0x4);
        pAudio->_0x24 = 0;

        return nOpenAudioIndex + 1;
    }

    if (p_Unknown_007d7ef0(audioOpenPtrResult) == 0x53464144)
    {
        const size_t size = p_Unknown_007d7ef0(audioOpenPtrResult);
        pAudio->_0xC = 0;
        pAudio->_0x10 = size;
        pAudio->_0x14 = reinterpret_cast<undefined4>(p_malloc(size));

        (*p_Unknown_008a4834)(pAudio->_0x14, 1, size, audioOpenPtrResult);
    }
    else
    {
        pAudio->_0xC = 0;
        pAudio->_0x10 = 0;
        pAudio->_0x14 = 0;

        (*p_Unknown_008a4838)(audioOpenPtrResult, 0, 0);
    }

    pAudio->_0x0 |= 2;
    pAudio->_0x8 = p_Unknown_007c9cc0(p_Unknown_007d7f50, pAudio->_0x4, &pAudio->_0x20, &pAudio->_0x1C, &pAudio->_0x18);
    pAudio->_0x18 *= 2;
    pAudio->_0x24 = 0;

    return nOpenAudioIndex + 1;
}

/////////////////////////////////////////////////////
// START CVidMode0::ConvertSurfaceToBmp() Override //
/////////////////////////////////////////////////////

struct ConvertSurfaceToBmpState
{
    byte* pOut;

    struct SampleBlock
    {
        int nNumHorizontalSrcPixelsPerScaledPixel;
        int nNumVerticalSrcPixelsPerScaledPixel;
        int nNumPixelsInBlock;

        void calculateDerived()
        {
            nNumPixelsInBlock = nNumHorizontalSrcPixelsPerScaledPixel * nNumVerticalSrcPixelsPerScaledPixel;
        }
    }
    sampleBlocks[4];

    byte* pCurSurfacePos;
    int nPitchInBytes;
    int nRedByteOffset;
    int nGreenByteOffset;
    int nBlueByteOffset;
    int nOutEOLPadding;
    int nScaledRectWidth;
    int nLineByteAdvance;
};

static void convertSurfaceToBmpHandlePixel(ConvertSurfaceToBmpState& state, ConvertSurfaceToBmpState::SampleBlock& sampleBlock)
{
    uint nRedSum = 0;
    uint nGreenSum = 0;
    uint nBlueSum = 0;

    for (int nY = 0; nY < sampleBlock.nNumVerticalSrcPixelsPerScaledPixel; ++nY)
    {
        const int nYOffset = nY * state.nPitchInBytes;

        for (int nX = 0; nX < sampleBlock.nNumHorizontalSrcPixelsPerScaledPixel * 4; nX += 4)
        {
            nBlueSum += state.pCurSurfacePos[nYOffset + nX + state.nBlueByteOffset];
            nGreenSum += state.pCurSurfacePos[nYOffset + nX + state.nGreenByteOffset];
            nRedSum += state.pCurSurfacePos[nYOffset + nX + state.nRedByteOffset];
        }
    }

    state.pOut[0] = static_cast<byte>(nBlueSum / sampleBlock.nNumPixelsInBlock);
    state.pOut[1] = static_cast<byte>(nGreenSum / sampleBlock.nNumPixelsInBlock);
    state.pOut[2] = static_cast<byte>(nRedSum / sampleBlock.nNumPixelsInBlock);

    // Pixel advance
    state.pOut += 3;
    state.pCurSurfacePos += sampleBlock.nNumHorizontalSrcPixelsPerScaledPixel * 4;
}

static void convertSurfaceToBmpHandleLine(ConvertSurfaceToBmpState& state, int nSampleBlockI)
{
    auto& sampleBlock = state.sampleBlocks[nSampleBlockI];

    for (int nScaledX = 0; nScaledX < state.nScaledRectWidth - 1; ++nScaledX)
    {
        convertSurfaceToBmpHandlePixel(state, sampleBlock);
    }

    convertSurfaceToBmpHandlePixel(state, state.sampleBlocks[nSampleBlockI + 1]);

    // Line advance
    state.pOut += state.nOutEOLPadding;
    state.pCurSurfacePos -= state.nLineByteAdvance;
}

byte CVidMode0::Export_Override_ConvertSurfaceToBmp(
    void** ppOut, uint nSurface, CRect* rRect, uint* pOutSize, short nScaleDivisor)
{
    const int nRectWidth = rRect->right - rRect->left;
    const int nRectHeight = rRect->bottom - rRect->top;

    const int nScaledRectWidth = nRectWidth / nScaleDivisor;
    const int nScaledRectHeight = nRectHeight / nScaleDivisor;
    uint nOutEOLPadding = nScaledRectWidth * 3 % 4;

    if (nOutEOLPadding != 0)
    {
        nOutEOLPadding = 4 - nOutEOLPadding;
    }

    constexpr int bitmapHeaderSize = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);
    *pOutSize = bitmapHeaderSize + (nScaledRectWidth * 3 + nOutEOLPadding) * nScaledRectHeight;
    *ppOut = p_malloc(*pOutSize);

    if (*ppOut == nullptr)
    {
        p_AssertionFailed(5630, "D:\\Dev\\chitin\\ChVideo.cpp", nullptr);
    }

    byte* pOut = reinterpret_cast<byte*>(*ppOut);

    BITMAPFILEHEADER& bitmapFileHeader = *reinterpret_cast<BITMAPFILEHEADER*>(pOut);
    bitmapFileHeader.bfType      = 0x4D42;           // "BM"
    bitmapFileHeader.bfSize      = *pOutSize;        // Size of BMP file
    bitmapFileHeader.bfReserved1 = 0;                // Reserved 1
    bitmapFileHeader.bfReserved2 = 0;                // Reserved 2
    bitmapFileHeader.bfOffBits   = bitmapHeaderSize; // Pixel array offset

    BITMAPINFOHEADER& bitmapInfoHeader = *reinterpret_cast<BITMAPINFOHEADER*>(pOut + sizeof(BITMAPFILEHEADER));
    bitmapInfoHeader.biSize          = sizeof(BITMAPINFOHEADER);
    bitmapInfoHeader.biWidth         = nScaledRectWidth;  // Bitmap width (signed)
    bitmapInfoHeader.biHeight        = nScaledRectHeight; // Bitmap height (signed)
    bitmapInfoHeader.biPlanes        = 1;                 // Num color planes (must be 1)
    bitmapInfoHeader.biBitCount      = 24;                // Bits per pixel
    bitmapInfoHeader.biCompression   = BI_RGB;            // Compression method
    bitmapInfoHeader.biSizeImage     = 0;                 // Image size (dummy 0)
    bitmapInfoHeader.biXPelsPerMeter = 0;                 // Horizontal resolution (dummy 0)
    bitmapInfoHeader.biYPelsPerMeter = 0;                 // Vertical resolution (dummy 0)
    bitmapInfoHeader.biClrUsed       = 0x1000000;         // Num colors in palette
    bitmapInfoHeader.biClrImportant  = 0;                 // All colors important

    pOut += bitmapHeaderSize;

    DDSURFACEDESC surfaceDesc{};
    surfaceDesc.dwSize = sizeof(DDSURFACEDESC);

    CRect rLockedRect;
    CopyRect(&rLockedRect, rRect);

    if (!this->LockTexSurface(nSurface, &surfaceDesc, &rLockedRect))
    {
        p_free(*ppOut);
        return 0;
    }

    if ((*p_g_pBaldurChitin)->m_cVideo.m_nBitDepth != 32)
    {
        this->UnlockTexSurface(nSurface, surfaceDesc.lpSurface);
        p_free(*ppOut);
        return 0;
    }

    ConvertSurfaceToBmpState state;

    state.pOut = pOut;

    // Bottom row of surface (non-last column)
    state.sampleBlocks[0].nNumHorizontalSrcPixelsPerScaledPixel = nScaleDivisor;
    state.sampleBlocks[0].nNumVerticalSrcPixelsPerScaledPixel = nRectHeight - nScaleDivisor * (nScaledRectHeight - 1); // nScaleDivisor + remainder(nRectHeight / nScaleDivisor)
    state.sampleBlocks[0].calculateDerived();

    // Bottom row of surface (last column)
    state.sampleBlocks[1].nNumHorizontalSrcPixelsPerScaledPixel = nRectWidth - nScaleDivisor * (nScaledRectWidth - 1); // nScaleDivisor + remainder(nRectWidth / nScaleDivisor)
    state.sampleBlocks[1].nNumVerticalSrcPixelsPerScaledPixel = state.sampleBlocks[0].nNumVerticalSrcPixelsPerScaledPixel;
    state.sampleBlocks[1].calculateDerived();

    // Non-bottom row of surface (non-last column)
    state.sampleBlocks[2].nNumHorizontalSrcPixelsPerScaledPixel = nScaleDivisor;
    state.sampleBlocks[2].nNumVerticalSrcPixelsPerScaledPixel = nScaleDivisor;
    state.sampleBlocks[2].calculateDerived();

    // Non-bottom row of surface (last column)
    state.sampleBlocks[3].nNumHorizontalSrcPixelsPerScaledPixel = state.sampleBlocks[1].nNumHorizontalSrcPixelsPerScaledPixel;
    state.sampleBlocks[3].nNumVerticalSrcPixelsPerScaledPixel = nScaleDivisor;
    state.sampleBlocks[3].calculateDerived();

    state.pCurSurfacePos = reinterpret_cast<byte*>(surfaceDesc.lpSurface)
        + surfaceDesc.lPitch * (nRectHeight - state.sampleBlocks[0].nNumVerticalSrcPixelsPerScaledPixel);

    state.nPitchInBytes = surfaceDesc.lPitch;
    state.nRedByteOffset = this->m_nRedBitOffset / 8;
    state.nGreenByteOffset = this->m_nGreenBitOffset / 8;
    state.nBlueByteOffset = this->m_nBlueBitOffset / 8;
    state.nOutEOLPadding = nOutEOLPadding;
    state.nScaledRectWidth = nScaledRectWidth;
    state.nLineByteAdvance = 4 * nRectWidth + surfaceDesc.lPitch * nScaleDivisor;

    convertSurfaceToBmpHandleLine(state, 0);

    for (int nScaledY = nScaledRectHeight - 2; nScaledY >= 0; --nScaledY)
    {
        convertSurfaceToBmpHandleLine(state, 2);
    }

    this->UnlockTexSurface(nSurface, surfaceDesc.lpSurface);
    return 1;
}

///////////////////////////////////////////////////
// END CVidMode0::ConvertSurfaceToBmp() Override //
///////////////////////////////////////////////////

///////////////////////////
// Misc Exported Utility //
///////////////////////////

int __stdcall Export_DivFloor(int a, int b)
{
    int res = a / b;
    int rem = a % b;
    int corr = (rem != 0 && ((rem < 0) != (b < 0)));
    return res - corr;
}

int __stdcall Export_Modulo(int a, int b)
{
    if (a >= 0)
    {
        return b - a % b;
    }
    else
    {
        return -a % b;
    }
}

////////////////////////////////////////
// Enhanced Widescreen Initialization //
////////////////////////////////////////

void InitEnhancedWidescreen()
{
    EnhancedWidescreen::allowedOutOfBoundsLeft = 0;
    EnhancedWidescreen::allowedOutOfBoundsTop = 0;
    EnhancedWidescreen::allowedOutOfBoundsRight = 0;
    EnhancedWidescreen::allowedOutOfBoundsBottom = 0;
}
