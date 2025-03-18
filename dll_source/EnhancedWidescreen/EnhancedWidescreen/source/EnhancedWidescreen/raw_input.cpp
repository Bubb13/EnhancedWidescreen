
#include <list>
#include <mutex>

#include <Windows.h>
#include <hidusage.h>

#include "InfinityLoader/infinity_loader_common_api.h"
#include "window_proc.h"

// Needed for raw input NEXTRAWINPUTBLOCK macro when compiling for x64
typedef unsigned __int64 QWORD;

struct InputState
{
	std::mutex lock;
	USHORT value;
	InputState() : lock(), value(0x0) {}
};

std::mutex registerRawInputLock{};
std::condition_variable registerRawInputCV{};
bool registerRawInputLocked = false;
HWND rawInputWindow = NULL;
bool isWOW64;
InputState inputStates[USHRT_MAX]{};
bool rawInputNeedsClear = false;

std::mutex pressedKeysStackLock{};
std::list<UINT> pressedKeysStack{};

void RunWithRawInputLock(std::function<void()> func)
{
	std::lock_guard<std::mutex> lk { pressedKeysStackLock };
	func();
}

static void setVKeyPressed(const USHORT vKey)
{
	std::lock_guard<std::mutex> lk { pressedKeysStackLock };

	InputState& keyState = inputStates[vKey];
	keyState.lock.lock();
	keyState.value = 0xFFFF;
	keyState.lock.unlock();

	if (std::find(pressedKeysStack.begin(), pressedKeysStack.end(), vKey) == pressedKeysStack.end())
	{
		pressedKeysStack.push_back(vKey);
	}
}

static void setVKeyReleased(const USHORT vKey)
{
	std::lock_guard<std::mutex> lk { pressedKeysStackLock };

	InputState& keyState = inputStates[vKey];
	keyState.lock.lock();
	keyState.value &= 0x7FFF;
	keyState.lock.unlock();

	for (auto itr = pressedKeysStack.begin(); itr != pressedKeysStack.end(); ++itr)
	{
		if (*itr == vKey)
		{
			pressedKeysStack.erase(itr);
			break;
		}
	}
}

static bool checkVKey(const USHORT flags, const USHORT vKey)
{
	if ((flags & RI_KEY_BREAK) == 0)
	{
		setVKeyPressed(vKey);
		return true;
	}
	else
	{
		setVKeyReleased(vKey);
		return false;
	}
}

static void checkVKeyLeftRight(const USHORT flags, const USHORT vGeneralKey, const USHORT vSpecificKey, const USHORT vOtherSpecificKey)
{
	if (checkVKey(flags, vSpecificKey) || (inputStates[vOtherSpecificKey].value & 0x8000) != 0)
	{
		setVKeyPressed(vGeneralKey);
	}
	else
	{
		setVKeyReleased(vGeneralKey);
	}
}

static void checkKey(const USHORT makeCode, const USHORT flags, const USHORT vKey)
{
	// Seen as VK_CONTROL
	//   Left Control  (VK_LCONTROL)                0x1D
	//   Right Control (VK_RCONTROL)    E0 prefix + 0x1D
	//
	// Seen as VK_SHIFT
	//   Left Shift  (VK_LSHIFT)                    0x2A
	//   Right Shift (VK_RSHIFT)                    0x36
	//
	// Seen as VK_MENU
	//   Left Alt  (VK_LMENU)                       0x38
	//   Right Alt (VK_RMENU)           E0 prefix + 0x38
	//
	// Unknown
	//   Left GUI  (VK_LWIN)            E0 prefix + 0x5B
	//   Right GUI (VK_RWIN)            E0 prefix + 0x5C

	const bool hasE0 = (flags & RI_KEY_E0) != 0;
	switch (vKey)
	{
		case VK_CONTROL:
			if (hasE0) checkVKeyLeftRight(flags, VK_CONTROL, VK_RCONTROL, VK_LCONTROL);
			else       checkVKeyLeftRight(flags, VK_CONTROL, VK_LCONTROL, VK_RCONTROL);
			break;
		case VK_SHIFT:
			if (makeCode == 0x36) checkVKeyLeftRight(flags, VK_SHIFT, VK_RSHIFT, VK_LSHIFT);
			else                  checkVKeyLeftRight(flags, VK_SHIFT, VK_LSHIFT, VK_RSHIFT);
			break;
		case VK_MENU:
			if (hasE0) checkVKeyLeftRight(flags, VK_MENU, VK_RMENU, VK_LMENU);
			else       checkVKeyLeftRight(flags, VK_MENU, VK_LMENU, VK_RMENU);
			break;
		default:
			checkVKey(flags, vKey);
			break;
	}
}

static void checkMouseButton(const USHORT mouseFlags, const USHORT downFlag, const USHORT upFlag, const int vKey)
{
	if ((mouseFlags & downFlag) != 0)
	{
		setVKeyPressed(vKey);
	}
	else if ((mouseFlags & upFlag) != 0)
	{
		setVKeyReleased(vKey);
	}
}

static void checkLeftMouseButton(const USHORT mouseFlags)
{
	return checkMouseButton(mouseFlags, RI_MOUSE_LEFT_BUTTON_DOWN, RI_MOUSE_LEFT_BUTTON_UP, VK_LBUTTON);
}

static void checkRightMouseButton(const USHORT mouseFlags)
{
	return checkMouseButton(mouseFlags, RI_MOUSE_RIGHT_BUTTON_DOWN, RI_MOUSE_RIGHT_BUTTON_UP, VK_RBUTTON);
}

static void checkMiddleMouseButton(const USHORT mouseFlags)
{
	return checkMouseButton(mouseFlags, RI_MOUSE_MIDDLE_BUTTON_DOWN, RI_MOUSE_MIDDLE_BUTTON_UP, VK_MBUTTON);
}

template<typename RAWINPUTSTRUCT>
static void processRawInputTemplate()
{
	RAWINPUTSTRUCT pBuffer[10];
	constexpr UINT bufferSize = sizeof(pBuffer);

	while (true)
	{
		UINT cbSize = bufferSize;
		const UINT numEntries = GetRawInputBuffer(reinterpret_cast<RAWINPUT*>(pBuffer), &cbSize, sizeof(RAWINPUTHEADER));

		if (numEntries == -1)
		{
			FPrint("[!] GetRawInputBuffer() failed (%d)\n", GetLastError());
			return;
		}
		else if (numEntries == 0)
		{
			break;
		}

		if (!windowHasFocus)
		{
			continue;
		}

		const RAWINPUTSTRUCT* pCurRawInput = pBuffer;
		for (UINT i = 0; i < numEntries; ++i)
		{
			if (pCurRawInput->header.dwType == RIM_TYPEKEYBOARD)
			{
				const RAWKEYBOARD& keyboard = pCurRawInput->data.keyboard;
				checkKey(keyboard.MakeCode, keyboard.Flags, keyboard.VKey);
			}
			else if (pCurRawInput->header.dwType == RIM_TYPEMOUSE)
			{
				const RAWMOUSE& mouse = pCurRawInput->data.mouse;
				const USHORT mouseFlags = mouse.usButtonFlags;

				checkLeftMouseButton(mouseFlags);
				checkRightMouseButton(mouseFlags);
				checkMiddleMouseButton(mouseFlags);
			}

			pCurRawInput = reinterpret_cast<const RAWINPUTSTRUCT*>(NEXTRAWINPUTBLOCK(reinterpret_cast<const RAWINPUT*>(pCurRawInput)));
		}
	}
}

#pragma pack(push, 1)
struct RAWINPUTWOW64
{
	RAWINPUTHEADER header;
	char padding1[8];
	union {
		RAWMOUSE    mouse;
		RAWKEYBOARD keyboard;
		RAWHID      hid;
	} data;
	char padding2[2];
};
#pragma pack(pop)

static void processRawInput()
{
	if (isWOW64)
	{
		processRawInputTemplate<RAWINPUTWOW64>();
	}
	else
	{
		processRawInputTemplate<RAWINPUT>();
	}
}

static void clearRawInput()
{
	std::lock_guard<std::mutex> lk { pressedKeysStackLock };

	//Print("Clearing raw input\n");
	for (InputState& inputState : inputStates)
	{
		inputState.lock.lock();
		inputState.value = 0x0;
		inputState.lock.unlock();
	}

	pressedKeysStack.clear();
}

static LRESULT CALLBACK IEexRawInputWindowProc(const HWND hwnd, const UINT uMsg, const WPARAM wParam, const LPARAM lParam)
{
	//FPrint("[?][IEexHelper.dll] IEexRawInputWindowProc() - uMsg: %d, wParam: %d\n", uMsg, wParam);
	return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

static HWND createWindow(const HWND hWndParent)
{
	const HMODULE hInstance = GetModuleHandle(NULL);

	if (hInstance == NULL)
	{
		FPrint("[!] GetModuleHandle() failed (%d)\n", GetLastError());
		return NULL;
	}

	WNDCLASS wndClass{};
	wndClass.lpfnWndProc = IEexRawInputWindowProc;
	wndClass.hInstance = hInstance;
	wndClass.lpszClassName = TEXT("IEexRawInputWindowClass");
	if (RegisterClass(&wndClass) == NULL)
	{
		FPrint("[!] RegisterClass() failed (%d)\n", GetLastError());
		return NULL;
	}

	const HWND hWnd = CreateWindow(
		TEXT("IEexRawInputWindowClass"), // lpClassName
		TEXT("IEex Raw Input Window"),   // lpWindowName
		0,                               // dwStyle
		0,                               // x
		0,                               // y
		0,                               // nWidth
		0,                               // nHeight
		HWND_MESSAGE,                    // hWndParent
		NULL,                            // hMenu
		hInstance,                       // hInstance
		NULL                             // lpParam
	);

	if (hWnd == NULL)
	{
		FPrint("[!] CreateWindow() failed (%d)\n", GetLastError());
		return NULL;
	}

	return hWnd;
}

static void unlockRegisterRawInput()
{
	{
		std::lock_guard<std::mutex> lk { registerRawInputLock };
		registerRawInputLocked = false;
	}
	registerRawInputCV.notify_all();
}

static DWORD WINAPI RawInputThread(const LPVOID lpThreadParameter)
{
	rawInputWindow = createWindow(reinterpret_cast<HWND>(lpThreadParameter));

	if (rawInputWindow == NULL)
	{
		unlockRegisterRawInput();
		return 0;
	}

	RAWINPUTDEVICE Rid[2];

	Rid[0].usUsagePage = HID_USAGE_PAGE_GENERIC;
	Rid[0].usUsage = HID_USAGE_GENERIC_KEYBOARD;
	Rid[0].dwFlags = RIDEV_INPUTSINK;
	Rid[0].hwndTarget = rawInputWindow;

	Rid[1].usUsagePage = HID_USAGE_PAGE_GENERIC;
	Rid[1].usUsage = HID_USAGE_GENERIC_MOUSE;
	Rid[1].dwFlags = RIDEV_INPUTSINK;
	Rid[1].hwndTarget = rawInputWindow;

	if (!RegisterRawInputDevices(Rid, _countof(Rid), sizeof(Rid[0])))
	{
		FPrint("[!] RegisterRawInputDevices() failed (%d)\n", GetLastError());
		unlockRegisterRawInput();
		return 0;
	}

	unlockRegisterRawInput();

	while (true)
	{
		MSG msg;

		if (PeekMessage(&msg, NULL, 0, WM_INPUT - 1, PM_REMOVE))
		{
			//FPrint("[?][IEexHelper.dll] RawInputThread() - uMsg: %d, wParam: %d\n", msg.message, msg.wParam);
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		if (PeekMessage(&msg, NULL, WM_INPUT + 1, UINT_MAX, PM_REMOVE))
		{
			//FPrint("[?][IEexHelper.dll] RawInputThread() - uMsg: %d, wParam: %d\n", msg.message, msg.wParam);
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}

		processRawInput();

		if (rawInputNeedsClear)
		{
			rawInputNeedsClear = false;
			clearRawInput();
		}

		Sleep(1);
	}
}

void __stdcall Export_RegisterRawInput(HWND hWndParent)
{
	std::unique_lock<std::mutex> lk { registerRawInputLock };
	registerRawInputCV.wait(lk, [] { return !registerRawInputLocked; });

	if (rawInputWindow != NULL)
	{
		return;
	}

	BOOL isWOW64Bool;
	if (!IsWow64Process(GetCurrentProcess(), &isWOW64Bool))
	{
		FPrint("[!] IsWow64Process() failed (%d)\n", GetLastError());
		return;
	}
	isWOW64 = isWOW64Bool;

	const HANDLE hThread = CreateThread(
		nullptr,        // lpThreadAttributes
		0,              // dwStackSize (default)
		RawInputThread, // lpStartAddress
		hWndParent,     // lpParameter
		0,              // dwCreationFlags
		nullptr         // lpThreadId
	);

	if (hThread == NULL)
	{
		FPrint("[!] CreateThread() failed (%d)\n", GetLastError());
		return;
	}

	// `registerRawInputLocked` intentionally held on success.
	// The thread will release it when it is done registering raw input.
	registerRawInputLocked = true;
}

SHORT __stdcall Export_GetAsyncKeyStateWrapper(const int vKey)
{
	InputState& state = inputStates[vKey];
	state.lock.lock();
	const USHORT value = state.value;
	state.value = value & 0xFFFE;
	state.lock.unlock();
	const USHORT toReturn = value & 0x8001;
	//if (toReturn != 0)
	//{
	//	FPrint("Returning 0x%hX for %d\n", toReturn, vKey);
	//}
	return toReturn;
}

SHORT __stdcall Export_GetAsyncKeyStateClient(const int nClient, const int vKey)
{
	InputState& state = inputStates[vKey];
	state.lock.lock();
	const USHORT value = state.value;
	state.value = value & ~(1 << nClient);
	state.lock.unlock();
	const USHORT toReturn = (value & 0x8000) | ((value & (1 << nClient)) != 0);
	//if (toReturn != 0)
	//{
	//	FPrint("Returning 0x%hX for %d (client %d)\n", toReturn, vKey, nClient);
	//}
	return toReturn;
}

void __stdcall Export_FakeKeyEvent(const int vFakeKey, const bool isDown)
{
	int makeCode;
	int baseFlags;

	switch (vFakeKey)
	{
		case VK_LBUTTON: baseFlags = isDown ? RI_MOUSE_LEFT_BUTTON_DOWN   : RI_MOUSE_LEFT_BUTTON_UP;   break;
		case VK_RBUTTON: baseFlags = isDown ? RI_MOUSE_RIGHT_BUTTON_DOWN  : RI_MOUSE_RIGHT_BUTTON_UP;  break;
		case VK_MBUTTON: baseFlags = isDown ? RI_MOUSE_MIDDLE_BUTTON_DOWN : RI_MOUSE_MIDDLE_BUTTON_UP; break;
		default:
			makeCode = MapVirtualKeyEx(vFakeKey, MAPVK_VK_TO_VSC, NULL);
			baseFlags = !isDown ? RI_KEY_BREAK : 0;
			break;
	}

	switch (vFakeKey)
	{
		case VK_LCONTROL: checkKey(makeCode, baseFlags,             VK_CONTROL); break;
		case VK_RCONTROL: checkKey(makeCode, baseFlags | RI_KEY_E0, VK_CONTROL); break;

		case VK_LSHIFT:
		case VK_RSHIFT:
			checkKey(makeCode, baseFlags, VK_SHIFT);
			break;

		case VK_LMENU: checkKey(makeCode, baseFlags,             VK_MENU); break;
		case VK_RMENU: checkKey(makeCode, baseFlags | RI_KEY_E0, VK_MENU); break;

		case VK_LBUTTON: checkLeftMouseButton(baseFlags);   break;
		case VK_RBUTTON: checkRightMouseButton(baseFlags);  break;
		case VK_MBUTTON: checkMiddleMouseButton(baseFlags); break;

		default: checkKey(makeCode, baseFlags, vFakeKey); break;
	}
}
