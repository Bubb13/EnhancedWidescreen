
#include <Windows.h>

extern bool windowHasFocus;

void __cdecl Export_WindowProcHook(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
