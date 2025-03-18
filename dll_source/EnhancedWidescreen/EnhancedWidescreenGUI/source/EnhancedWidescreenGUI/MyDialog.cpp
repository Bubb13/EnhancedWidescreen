
#include "pch.h"

#include "afxdialogex.h"

#include "EnhancedWidescreenGUI.h"
#include "MyDialog.h"

/////////////
// Dynamic //
/////////////

IMPLEMENT_DYNAMIC(MyDialog, CDialogEx)

/////////////////
// Message Map //
/////////////////

BEGIN_MESSAGE_MAP(MyDialog, CDialogEx)
	ON_LBN_DBLCLK(IDC_LIST1, &MyDialog::OnListDoubleClicked)
	ON_LBN_SELCHANGE(IDC_LIST1, &MyDialog::OnListSelectionChanged)
	ON_BN_CLICKED(IDOK, &MyDialog::OnOkClicked)
	ON_WM_CLOSE()
END_MESSAGE_MAP()

///////////////
// Variables //
///////////////

typedef void(__stdcall* type_initcallback)(MyDialog* dialog, void* user);
type_initcallback initProc;
void* initProcUser;
int listSelectIndex;

CFont font;

///////////////////////////////
// Constructors + Destructor //
///////////////////////////////

MyDialog::MyDialog(type_initcallback initProc, void* initProcUser)
	: CDialogEx(IDD_MyDialog, NULL), initProc(initProc), initProcUser(initProcUser) {}

MyDialog::~MyDialog() {}

//////////////////////
// Member Functions //
//////////////////////

CListBox& MyDialog::GetList()
{
	return m_list;
}

int MyDialog::GetListSelectionIndex()
{
	return m_listSelectionIndex;
}

CMyBox& MyDialog::GetBox()
{
	return m_box;
}

CButton& MyDialog::GetOkButton()
{
	return m_okButton;
}

//-----------//
// Overrides //
//-----------//

void MyDialog::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_LIST1, m_list);
	DDX_Control(pDX, IDOK, m_okButton);
	DDX_Control(pDX, IDC_CUSTOM2, m_box);
}

BOOL MyDialog::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	font.CreatePointFont(90, TEXT("Consolas"));
	m_list.SetFont(&font);

	initProc(this, initProcUser);

	return TRUE; // return TRUE unless you set the focus to a control
				 // EXCEPTION: OCX Property Pages should return FALSE
}

//////////////////////
// Message Handlers //
//////////////////////

afx_msg void MyDialog::OnListDoubleClicked()
{
	m_listSelectionIndex = m_list.GetCurSel();
	OnOkClicked();
}

afx_msg void MyDialog::OnListSelectionChanged()
{
	m_listSelectionIndex = m_list.GetCurSel();
}

afx_msg void MyDialog::OnOkClicked()
{
	if (m_listSelectionIndex != -1)
	{
		CDialogEx::OnOK();
	}
}
