
#include "raw_input.h"

bool windowHasFocus = false;

void __cdecl Export_WindowProcHook(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
        case WM_SETCURSOR:
        {
            windowHasFocus = true;
            break;
        }
        case WM_KILLFOCUS:
        {
            windowHasFocus = false;
            rawInputNeedsClear = true;
            break;
        }
    }
}
