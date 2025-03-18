
#pragma once

#include <afxwin.h>

#include "InfinityLoader/infinity_loader_common_types.h"

class CMyBox : public CWnd
{
    DECLARE_DYNAMIC(CMyBox)
    DECLARE_MESSAGE_MAP()

private:
    ///////////////
    // Variables //
    ///////////////

    String str;

public:
    ///////////////////////////////
    // Constructors + Destructor //
    ///////////////////////////////

    CMyBox();
    virtual ~CMyBox();

    /////////////////////////////
    // Public Member Functions //
    /////////////////////////////

    void GetRect(RECT* out);
    void SetText(const String& str);

private:
    //////////////////////////////
    // Private Member Functions //
    //////////////////////////////

    void Draw(CDC* dc, RECT* inOut, bool onlyCalculate);
    BOOL RegisterWndClass();

    //------------------//
    // Message Handlers //
    //------------------//

    afx_msg void OnPaint();
};
