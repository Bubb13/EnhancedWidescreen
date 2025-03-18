
#include "pch.h"

#include <algorithm>
#include <ddraw.h>
#include <format>
#include <vector>

#include "framework.h"

#include "InfinityLoader/infinity_loader_common_api.h"
#include "InfinityLoader/shared_state_api.h"
#include "EnhancedWidescreenGUI.h"
#include "MyDialog.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

///////////////
// Constants //
///////////////

const TCHAR *const text = TEXT(R"(This window sets the resolution BG1 will target. You should select a resolution that matches, or is close to your monitor's aspect ratio.

Hints have been provided to help you choose an optimal resolution. Vanilla BG1 targets 640x480; resolutions around this size will yield an optimal UI size.

Note: cnc-ddraw is recommended for smooth rendering / window handling. It should have been automatically installed by setup-B3EnhancedWidescreen.exe.)");

///////////////
// Variables //
///////////////

CEnhancedWidescreenGUIApp theApp;

/////////////////
// Message Map //
/////////////////

BEGIN_MESSAGE_MAP(CEnhancedWidescreenGUIApp, CWinApp)
END_MESSAGE_MAP()

//////////////////
// Constructors //
//////////////////

CEnhancedWidescreenGUIApp::CEnhancedWidescreenGUIApp() {}

/////////////
// Structs //
/////////////

struct ModeEntry
{
	DDSURFACEDESC desc;
	String resolutionStr;
	std::pair<int,int> ratio;
	String ratioStr;
	int ratioDiff;
	const TCHAR* recommendedStr;

	ModeEntry(DDSURFACEDESC* descToCpy)
	{
		memcpy((void*)&desc, (void*)descToCpy, sizeof(DDSURFACEDESC));
	};
};

struct InitDialogStruct
{
	IDirectDraw& pDraw;
	std::vector<ModeEntry> entries{};
	const String& iniPathStr;

	InitDialogStruct(IDirectDraw& y, const String& z) :
		pDraw(y), iniPathStr(z) {};
};

///////////////////////////
// Util Static Functions //
///////////////////////////

static int gcd(const int m, const int n)
{
	if (m == 0) return n;
	return gcd(n % m, m);
}

static int findPercentDifferenceBetweenRatios(
	const std::pair<int,int>& x,
	const std::pair<int,int>& y)
{
	int normalizedXTop = x.first * y.second;
	int normalizedYTop = y.first * x.second;
	return std::abs(((normalizedXTop - normalizedYTop) * 20000) / (normalizedXTop + normalizedYTop));
}

static int findPercentErrorBetweenRatios(
	const std::pair<int,int>& wanted,
	const std::pair<int,int>& gotten)
{
	int normalizedWantedTop = wanted.first * gotten.second;
	int normalizedGottenTop = gotten.first * wanted.second;
	return std::abs(normalizedGottenTop - normalizedWantedTop) * 10000 / normalizedWantedTop;
}

static std::pair<int,int> findRatio(const int x, const int y)
{
	const int divisor = gcd(x, y);
	return { x / divisor, y / divisor };
}

static String formatRatioDiffAsPercent(int diff)
{
	const auto divResult = std::div(diff, 100);

	// Enough for dd.dd (will grow as needed)
	int nBuffSize = 6;
	TCHAR* aBuff;

	while (true)
	{
		aBuff = new TCHAR[nBuffSize];

		int nResult = _snwprintf_s(aBuff, nBuffSize, _TRUNCATE, TEXT("%d.%02d"),
			divResult.quot, divResult.rem);

		if (nResult < nBuffSize)
		{
			// Everything fit in the buffer
			break;
		}

		// Try again with the real size
		nBuffSize = nResult + 1;
		delete[] aBuff;
	}

	const String sBuff{aBuff};
	delete[] aBuff;
	return sBuff;
}

static void screenRectToClientRect(RECT* inOut)
{
	inOut->right = inOut->right - inOut->left;
	inOut->left = 0;
	inOut->bottom = inOut->bottom - inOut->top;
	inOut->top = 0;
}

//////////////////////
// Static Functions //
//////////////////////

static HRESULT FAR PASCAL enumDisplayModesCallback(LPDDSURFACEDESC desc, LPVOID user)
{
	std::vector<ModeEntry>* entries = (std::vector<ModeEntry>*)user;

	if ((desc->dwFlags & (DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT)) == (DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT)
		&& desc->dwWidth >= 640 && desc->dwHeight >= 480
		&& (desc->ddpfPixelFormat.dwFlags & DDPF_RGB) != 0
		&& desc->ddpfPixelFormat.dwRGBBitCount == 32)
	{
		entries->emplace_back(desc);
	}

	return 1;
}

static bool displayModeEntrySortCallback(const ModeEntry& i, const ModeEntry& j)
{
	if (i.desc.dwWidth > j.desc.dwWidth)
	{
		return true;
	}
	else if (i.desc.dwWidth == j.desc.dwWidth)
	{
		return i.desc.dwHeight > j.desc.dwHeight;
	}
	else
	{
		return false;
	}
}

static void __stdcall initCallBack(MyDialog* dialog, void* user)
{
	InitDialogStruct& pInitDialog = *reinterpret_cast<InitDialogStruct*>(user);
	pInitDialog.pDraw.EnumDisplayModes(NULL, NULL, &pInitDialog.entries, enumDisplayModesCallback);

	std::sort(pInitDialog.entries.begin(), pInitDialog.entries.end(), displayModeEntrySortCallback);

	const int screenWidth = GetSystemMetrics(SM_CXSCREEN);
	const int screenHeight = GetSystemMetrics(SM_CYSCREEN);
	const std::pair<int,int> screenRatio = findRatio(screenWidth, screenHeight);

	bool hasLastResolution;
	String lastResolution;
	GetINIStr(pInitDialog.iniPathStr, TEXT("Enhanced Widescreen"), TEXT("Last Resolution"), lastResolution, hasLastResolution);

	int lastWidth;
	int lastHeight;

	if (hasLastResolution)
	{
		if (const size_t separatorI = lastResolution.find(TEXT("x")); separatorI != std::string::npos)
		{
			const String lastWidthStr = lastResolution.substr(0, separatorI);
			DecStrToInt(lastWidthStr, lastWidth);

			const String lastHeightStr = lastResolution.substr(separatorI + 1);
			DecStrToInt(lastHeightStr, lastHeight);
		}
		else
		{
			hasLastResolution = false;
		}
	}

	int lastResolutionI = -1;
	int maxResolutionStrLen = 0;
	int maxRatioStrLen = 0;
	int maxRecommendedStrLen = 0;

	for (size_t i = 0; i < pInitDialog.entries.size(); ++i)
	{
		ModeEntry& x = pInitDialog.entries.at(i);
		const DWORD modeWidth = x.desc.dwWidth;
		const DWORD modeHeight = x.desc.dwHeight;

		if (hasLastResolution && modeWidth == lastWidth && modeHeight == lastHeight)
		{
			lastResolutionI = i;
		}

		x.resolutionStr = std::format(TEXT("{}x{}"), modeWidth, modeHeight);

		const int resolutionStrLen = x.resolutionStr.size();
		if (resolutionStrLen > maxResolutionStrLen)
		{
			maxResolutionStrLen = resolutionStrLen;
		}

		x.ratio = findRatio(modeWidth, modeHeight);
		x.ratioStr = std::format(TEXT("{}/{}"), x.ratio.first, x.ratio.second);

		const int ratioStrLen = x.ratioStr.size();
		if (ratioStrLen > maxRatioStrLen)
		{
			maxRatioStrLen = ratioStrLen;
		}

		//x.ratioDiff = findPercentDifferenceBetweenRatios(screenRatio, x.ratio);
		x.ratioDiff = findPercentErrorBetweenRatios(screenRatio, x.ratio);

		int recommendedStrLen;
		if (x.ratioDiff <= 50)
		{
			if (modeWidth <= 1600 && modeHeight >= 768)
			{
				x.recommendedStr = TEXT("Recommended");
				recommendedStrLen = sizeof("Recommended") - 1;
			}
			else
			{
				x.recommendedStr = TEXT("Good Ratio");
				recommendedStrLen = sizeof("Good Ratio") - 1;
			}
		}
		else
		{
			x.recommendedStr = TEXT("");
			recommendedStrLen = sizeof("") - 1;
		}

		if (recommendedStrLen > maxRecommendedStrLen)
		{
			maxRecommendedStrLen = recommendedStrLen;
		}
	}

	CListBox& list = dialog->GetList();
	CDC& listDeviceContent = *list.GetWindowDC();
	listDeviceContent.SelectObject(list.GetFont());

	int maxLineLength = 0;
	int listContentHeight = 0;

	for (const ModeEntry& x : pInitDialog.entries)
	{
		const String formatted = std::format(TEXT("{:<{}} | {:<{}} | {:<{}} | {}%"),
			x.resolutionStr.c_str(), maxResolutionStrLen,
			x.ratioStr.c_str(), maxRatioStrLen,
			x.recommendedStr, maxRecommendedStrLen,
			formatRatioDiffAsPercent(x.ratioDiff).c_str()
		);

		list.AddString(formatted.c_str());

		const CSize lineSize = listDeviceContent.GetTextExtent(formatted.c_str());
		listContentHeight += lineSize.cy;

		if (lineSize.cx > maxLineLength)
		{
			maxLineLength = lineSize.cx;
		}
	}

	// Select last resolution
	if (lastResolutionI != -1)
	{
		list.SetCurSel(lastResolutionI);
		// Notify the dialog
		const HWND listHwnd = list.GetSafeHwnd();
		const WPARAM wParam = MAKEWPARAM(GetDlgCtrlID(listHwnd), LBN_SELCHANGE);
		const LPARAM lParam = reinterpret_cast<LPARAM>(listHwnd);
		list.GetParent()->PostMessage(WM_COMMAND, wParam, lParam);
	}

	// Find list vertical scrollbar width
	SCROLLBARINFO scrollbarInfo;
	scrollbarInfo.cbSize = sizeof(SCROLLBARINFO);
	GetScrollBarInfo(list.GetSafeHwnd(), OBJID_VSCROLL, &scrollbarInfo);
	const RECT& scrollbarRect = scrollbarInfo.rcScrollBar;

	// Calculate list dimensions
	const int halfScreenHeight = screenHeight / 2;
	const int listHeight = listContentHeight <= halfScreenHeight
		? listContentHeight
		: halfScreenHeight;

	const int listWidth = maxLineLength + (scrollbarRect.right - scrollbarRect.left);

	// Grab window rect
	RECT windowRect;
	dialog->GetWindowRect(&windowRect);

	// Find the height of the menu bar
	CPoint clientScreenPos { 0, 0 };
	ClientToScreen(dialog->GetSafeHwnd(), &clientScreenPos);
	const int topBarHeight = clientScreenPos.y - windowRect.top;

	// Expand list to fit contents
	RECT listRect;
	listRect.left = 5;
	listRect.top = 5;
	listRect.right = listRect.left + listWidth + 20;
	listRect.bottom = listRect.top + listHeight + 10;
	list.SetWindowPos(nullptr,
		listRect.left,
		listRect.top,
		listRect.right - listRect.left,
		listRect.bottom - listRect.top,
		0
	);

	// Set explanation text
	CMyBox& myBox = dialog->GetBox();
	myBox.SetText(text);

	///////////////////////////////////////////////
	// Move explanation to the right of the list //
	///////////////////////////////////////////////

	// Set initial position and maximum bounds
	RECT myBoxRect;
	myBox.GetWindowRect(&myBoxRect);
	const int myBoxWidth = myBoxRect.right - myBoxRect.left;
	myBoxRect.left = listRect.right + 5;
	myBoxRect.top = 5;
	myBoxRect.right = myBoxRect.left + myBoxWidth;
	myBoxRect.bottom = screenHeight - topBarHeight - 13;

	// Calculate draw size
	RECT myBoxClientRect = myBoxRect;
	screenRectToClientRect(&myBoxClientRect);
	myBox.GetRect(&myBoxClientRect);
	myBoxRect.right = myBoxRect.left + (myBoxClientRect.right - myBoxClientRect.left);
	myBoxRect.bottom = myBoxRect.top + (myBoxClientRect.bottom - myBoxClientRect.top);

	// Update position and size
	myBox.SetWindowPos(nullptr,
		myBoxRect.left,
		myBoxRect.top,
		myBoxRect.right - myBoxRect.left,
		myBoxRect.bottom - myBoxRect.top,
		0
	);

	// Center SELECT button
	CButton& okBtutton = dialog->GetOkButton();
	RECT okButtonRect;
	okBtutton.GetWindowRect(&okButtonRect);
	const int okButtonWidth = okButtonRect.right - okButtonRect.left;
	const int okButtonHeight = okButtonRect.bottom - okButtonRect.top;
	okButtonRect.left = listRect.right / 2 - okButtonWidth / 2;
	okButtonRect.top = listRect.bottom + 2;
	okButtonRect.right = okButtonRect.left + okButtonWidth;
	okButtonRect.bottom = okButtonRect.top + okButtonHeight;
	okBtutton.SetWindowPos(nullptr,
		okButtonRect.left,
		okButtonRect.top,
		okButtonWidth,
		okButtonHeight,
		0
	);

	// Expand window width to fit list and explanation
	windowRect.right = myBoxRect.right;
	const int windowWidth = windowRect.right - windowRect.left;

	// Resize window

	const int bottomOfContent = okButtonRect.bottom > myBoxRect.bottom
		? okButtonRect.bottom
		: myBoxRect.bottom + 2;

	dialog->SetWindowPos(nullptr,
		0,
		0,
		windowWidth + 10,
		bottomOfContent + topBarHeight + 5,
		0
	);
}

//////////////////////
// Member Functions //
//////////////////////

BOOL CEnhancedWidescreenGUIApp::InitInstance()
{
	CWinApp::InitInstance();
	return TRUE;
}

//////////////////////
// Export Functions //
//////////////////////

EXPORT void InitEnhancedWidescreenGUI(SharedState argSharedDLL)
{
	sharedState() = argSharedDLL;
}

EXTERN_C_EXPORT void __stdcall AskResolution(DWORD* nWidthRet, DWORD* nHeightRet)
{
	AFX_MANAGE_STATE(AfxGetStaticModuleState());

	IDirectDraw* pDraw;
	DirectDrawCreate(NULL, &pDraw, NULL);

	const String iniPath = sharedState().WorkingFolder() + TEXT("EnhancedWidescreen.ini");

	InitDialogStruct dialogState { *pDraw, iniPath };
	MyDialog myDialog { initCallBack, &dialogState };

	if (myDialog.DoModal() == -1)
	{
		MessageBoxFormatA("EnhancedWidescreenGUI", MB_ICONERROR, "Error: %d", GetLastError());
	}

	ModeEntry& selectedEntry = dialogState.entries.at(myDialog.GetListSelectionIndex());

	const int nWidth = selectedEntry.desc.dwWidth;
	const int nHeight = selectedEntry.desc.dwHeight;

	const String resolutionStr = std::format(TEXT("{}x{}"), nWidth, nHeight);
	WritePrivateProfileString(TEXT("Enhanced Widescreen"), TEXT("Last Resolution"), resolutionStr.c_str(), iniPath.c_str());

	*nWidthRet = nWidth;
	*nHeightRet = nHeight;
}
