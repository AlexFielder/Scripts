VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisWorkbook"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Private WithEvents App As Application
Attribute App.VB_VarHelpID = -1

Private Sub Workbook_Open()
  On Error Resume Next
  Set App = Application
  On Error GoTo 0
End Sub

Private Sub Workbook_BeforeClose(Cancel As Boolean)
  Call CloseHelp(HHwinHwnd)
End Sub

Private Sub Workbook_AddinInstall()
  On Error Resume Next
  Run "'" & ThisWorkbook.Name & "'!Load_REFindReplace"
  On Error GoTo 0
End Sub

Private Sub Workbook_AddinUnInstall()
  On Error Resume Next
  Run "'" & ThisWorkbook.Name & "'!Unload_REFindReplace"
  On Error GoTo 0
End Sub

Private Sub App_NewWorkbook(ByVal WB As Workbook)
  On Error Resume Next
  If Not Rib Is Nothing Then Rib.Invalidate
  On Error GoTo 0
End Sub

Private Sub App_WorkbookDeactivate(ByVal WB As Workbook)
  On Error Resume Next
  If Not Rib Is Nothing Then Rib.Invalidate
  On Error GoTo 0
End Sub

Private Sub App_WorkbookOpen(ByVal WB As Workbook)
  On Error Resume Next
  If Not Rib Is Nothing Then Rib.Invalidate
  On Error GoTo 0
End Sub
