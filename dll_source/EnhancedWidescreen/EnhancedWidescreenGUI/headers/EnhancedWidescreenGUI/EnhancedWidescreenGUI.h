
#pragma once

#ifndef __AFXWIN_H__
	#error "include 'pch.h' before including this file for PCH"
#endif

#include "resource.h"

class CEnhancedWidescreenGUIApp : public CWinApp
{
	DECLARE_MESSAGE_MAP()

public:
	//////////////////
	// Constructors //
	//////////////////

	CEnhancedWidescreenGUIApp();

private:
	//////////////////////
	// Member Functions //
	//////////////////////

	//-----------//
	// Overrides //
	//-----------//

	BOOL InitInstance() override;
};
