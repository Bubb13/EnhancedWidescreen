
#pragma once

#include "afxdialogex.h"

#include "CMyBox.h"

class MyDialog : public CDialogEx
{
	DECLARE_DYNAMIC(MyDialog)
	DECLARE_MESSAGE_MAP()

#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_MyDialog };
#endif

public:
	typedef void(__stdcall* type_initcallback)(MyDialog* dialog, void* user);

private:
	///////////////
	// Variables //
	///////////////

	//------//
	// Data //
	//------//

	type_initcallback initProc;
	void* initProcUser;
	int m_listSelectionIndex = -1;

	//----------//
	// Controls //
	//----------//

	CListBox m_list;
	CMyBox m_box;
	CButton m_okButton;

public:
	///////////////////////////////
	// Constructors + Destructor //
	///////////////////////////////

	MyDialog(type_initcallback initProc, void* initProcUser);
	virtual ~MyDialog();

public:
	//////////////////////
	// Member Functions //
	//////////////////////

	CListBox& GetList();
	int GetListSelectionIndex();
	CMyBox& GetBox();
	CButton& GetOkButton();

private:
	//-----------//
	// Overrides //
	//-----------//

	void DoDataExchange(CDataExchange* pDX) override;
	BOOL OnInitDialog() override;

	//------------------//
	// Message Handlers //
	//------------------//

	afx_msg void OnListDoubleClicked();
	afx_msg void OnListSelectionChanged();
	afx_msg void OnOkClicked();
};
