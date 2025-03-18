
#pragma once

#include <functional>
#include <list>

#include <Windows.h>

extern std::list<UINT> pressedKeysStack;
extern bool rawInputNeedsClear;

SHORT __stdcall Export_GetAsyncKeyStateWrapper(const int vKey);
SHORT __stdcall Export_GetAsyncKeyStateClient(const int nClient, const int vKey);
void __stdcall Export_RegisterRawInput(HWND hWndParent);

void RunWithRawInputLock(std::function<void()> func);
