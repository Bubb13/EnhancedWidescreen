
#include "pch.h"

#include "CMyBox.h"

/////////////
// Dynamic //
/////////////

IMPLEMENT_DYNAMIC(CMyBox, CWnd)

/////////////////
// Message Map //
/////////////////

BEGIN_MESSAGE_MAP(CMyBox, CWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()

///////////////////////////////
// Constructors + Destructor //
///////////////////////////////

CMyBox::CMyBox()
{
    RegisterWndClass();
}

CMyBox::~CMyBox() {}

//////////////////////
// Static Functions //
//////////////////////

static void drawBorder(CDC *const dc, const RECT *const rect)
{
    CPen pen { PS_SOLID, 1, RGB(130, 135, 144) };
    CPen *const pOldPen = dc->SelectObject(&pen);

    // Draw black border
    dc->MoveTo(rect->left, rect->top);
    dc->LineTo(rect->right - 1, rect->top);
    dc->LineTo(rect->right - 1, rect->bottom - 1);
    dc->LineTo(rect->left, rect->bottom - 1);
    dc->LineTo(rect->left, rect->top);

    dc->SelectObject(pOldPen);
}

static bool isCncDDrawPresent()
{
    const HMODULE ddrawHandle = GetModuleHandleA("ddraw");
    if (ddrawHandle == NULL) return false;
    return GetProcAddress(ddrawHandle, "GameHandlesClose") != nullptr;
}

/////////////////////////////
// Public Member Functions //
/////////////////////////////

void CMyBox::GetRect(RECT *const out)
{
    Draw(this->GetDC(), out, true);
}

void CMyBox::SetText(const String& str)
{
    this->str = str;
}

//////////////////////////////
// Private Member Functions //
//////////////////////////////

void CMyBox::Draw(CDC *const dc, RECT *const inOut, const bool onlyCalculate = false)
{
    RECT clippingRect = *inOut;

    // Create 10 pixel padding
    RECT textClippingRectBackup = clippingRect;
    textClippingRectBackup.left += 10;
    textClippingRectBackup.top += 10;
    textClippingRectBackup.right -= 10;
    textClippingRectBackup.bottom -= 10;

    RECT textClippingRect = textClippingRectBackup;

    CFont font;
    font.CreatePointFont(90, TEXT("Segoe UI"), NULL);
    const HGDIOBJ pOldFont = dc->SelectObject(font);

    // Draw the main explanation text
    const int firstPartHeight = DrawText(dc->GetSafeHdc(), str.c_str(), -1, &textClippingRect,
        DT_WORDBREAK | (onlyCalculate ? DT_CALCRECT : 0));

    // Calculate the size of 1 line
    textClippingRect = textClippingRectBackup;
    const int lineHeight = DrawText(dc->GetSafeHdc(), TEXT("a"), -1, &textClippingRect, DT_CALCRECT);

    // Move text drawing down to the cnc-ddraw status line
    textClippingRectBackup.top += firstPartHeight + lineHeight;
    textClippingRect = textClippingRectBackup;

    // Calculate the x value after the cnc-ddraw label
    DrawText(dc->GetSafeHdc(), TEXT("cnc-ddraw: "), -1, &textClippingRect, DT_CALCRECT);
    const int rightOfLabel = textClippingRect.right;

    // Draw the cnc-ddraw label
    textClippingRect = textClippingRectBackup;
    DrawText(dc->GetSafeHdc(), TEXT("cnc-ddraw: "), -1, &textClippingRect, onlyCalculate ? DT_CALCRECT : 0);

    // Move the text clipping rect right to after the cnc-ddraw label
    textClippingRect = textClippingRectBackup;
    textClippingRect.left = rightOfLabel;

    // Draw the cnc-ddraw status message
    COLORREF oldColor;
    if (isCncDDrawPresent())
    {
        oldColor = SetTextColor(dc->GetSafeHdc(), RGB(34, 139, 34));
        DrawText(dc->GetSafeHdc(), TEXT("Present"), -1, &textClippingRect, onlyCalculate ? DT_CALCRECT : 0);
    }
    else
    {
        oldColor = SetTextColor(dc->GetSafeHdc(), RGB(255, 0, 0));
        DrawText(dc->GetSafeHdc(), TEXT("Not Present"), -1, &textClippingRect, onlyCalculate ? DT_CALCRECT : 0);
    }

    SetTextColor(dc->GetSafeHdc(), oldColor);
    dc->SelectObject(pOldFont);

    // Fill the bounding box of the drawn control
    inOut->left = clippingRect.left;
    inOut->top = clippingRect.top;
    inOut->right = clippingRect.right;
    inOut->bottom = (std::min)(textClippingRect.top + lineHeight + 10, clippingRect.bottom);

    // Draw the black border
    if (!onlyCalculate)
    {
        drawBorder(dc, inOut);
    }
}

BOOL CMyBox::RegisterWndClass()
{
    WNDCLASS wndClass;
    HINSTANCE hInst = AfxGetInstanceHandle();

    if (!(GetClassInfo(hInst, TEXT("CMyBox"), &wndClass)))
    {
        wndClass.style = NULL;
        wndClass.lpfnWndProc = ::DefWindowProc;
        wndClass.cbClsExtra = 0;
        wndClass.cbWndExtra = 0;
        wndClass.hInstance = hInst;
        wndClass.hIcon = NULL;
        wndClass.hCursor = AfxGetApp()->LoadStandardCursor(IDC_ARROW);
        wndClass.hbrBackground = GetSysColorBrush(COLOR_WINDOW);
        wndClass.lpszMenuName = NULL;
        wndClass.lpszClassName = TEXT("CMyBox");

        if (!AfxRegisterClass(&wndClass))
        {
            AfxThrowResourceException();
            return FALSE;
        }
    }

    return TRUE;
}

//////////////////////
// Message Handlers //
//////////////////////

afx_msg void CMyBox::OnPaint()
{
    CPaintDC dc { this };
    RECT clientRect;
    GetClientRect(&clientRect);
    Draw(&dc, &clientRect);
}
