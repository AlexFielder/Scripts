Attribute VB_Name = "REFindReplaceEvt"
Option Private Module
Option Explicit

Public HHwinHwnd As Long

Private Declare Function IsWindow Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" _
  (ByVal hwnd As Long, _
   ByVal wMsg As Long, _
   ByVal wParam As Long, _
   lParam As Any) As Long
Private Declare Function HtmlHelp Lib "hhctrl.ocx" Alias "HtmlHelpA" _
  (ByVal hwnd As Long, _
   ByVal lpHelpFile As String, _
   ByVal wCommand As Long, _
   ByVal dwData As Long) As Long

Public Sub Load_REFindReplace()
  ' initialization code for the add-in
  Dim WBName As String
  Dim EditMenu As CommandBarPopup
  Dim NewCmd As CommandBarButton
  Dim LinksCmd As CommandBarButton
  Dim Pic As stdole.IPictureDisp
  Dim Msk As stdole.IPictureDisp

  On Error Resume Next
  ThisWorkbook.VBProject.References.AddFromGuid "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}", 2, 0
  With Application
    WBName = .ThisWorkbook.Name
    ' set keyboard shortcut
    .MacroOptions Macro:="'" & WBName & "'!RegExFindReplaceGUI", _
      HasShortcutKey:=True, _
      ShortcutKey:="X", _
      HelpFile:=Environ("AppData") & "\RegExFindReplace\RegExFR.chm", _
      HelpContextID:=10000
    ' set function category
    .MacroOptions Macro:="'" & WBName & "'!RegExFind", _
      Category:="Regular Expressions", _
      HelpFile:=Environ("AppData") & "\RegExFindReplace\RegExFR.chm", _
      HelpContextID:=30000
    .MacroOptions Macro:="'" & WBName & "'!RegExReplace", _
      Category:="Regular Expressions", _
      HelpFile:=Environ("AppData") & "\RegExFindReplace\RegExFR.chm", _
      HelpContextID:=50000
    .MacroOptions Macro:="'" & WBName & "'!RegExTest", _
      Category:="Regular Expressions", _
      HelpFile:=Environ("AppData") & "\RegExFindReplace\RegExFR.chm", _
      HelpContextID:=60000
    .MacroOptions Macro:="'" & WBName & "'!RegExMatchCount", _
      Category:="Regular Expressions", _
      HelpFile:=Environ("AppData") & "\RegExFindReplace\RegExFR.chm", _
      HelpContextID:=40000
    ' set project help file path
    .ThisWorkbook.VBProject.HelpFile = Environ("AppData") & "\RegExFindReplace\RegExFR.chm"
  End With
  If CInt(Application.Version) < 12 Then
    ' create menu item in Excel 2003 or earlier (delete existing first)
    Call DeleteCmd("RegExFindReplaceCmd")
    Set EditMenu = CommandBars("Worksheet Menu Bar").FindControl(ID:=30003)
    Set Pic = LoadPicture(Environ("AppData") & "\RegExFindReplace\icon.bmp")
    Set Msk = LoadPicture(Environ("AppData") & "\RegExFindReplace\mask.bmp")
    ' put the menu item before the "Links" command, if possible
    Set LinksCmd = CommandBars.FindControl(ID:=759)
    If Not LinksCmd Is Nothing Then
      Set NewCmd = EditMenu.Controls.Add(Type:=msoControlButton, Before:=LinksCmd.Index, Temporary:=True)
    Else
      Set NewCmd = EditMenu.Controls.Add(Type:=msoControlButton, Temporary:=True)
    End If
    With NewCmd
      .Caption = "RegE&x Find/Replace"
      .OnAction = "'" & WBName & "'!RegExFindReplaceGUI"
      .enabled = (Workbooks.Count > 0)
      .DescriptionText = "Displays a dialog for finding/replacing cell contents using regular expressions"
      .HelpFile = Environ("AppData") & "\RegExFindReplace\RegExFR.chm"
      .HelpContextID = 10000
      .Tag = "RegExFindReplaceCmd"
      .Style = msoButtonAutomatic
      .Priority = 2
      .Picture = Pic
      .Mask = Msk
      .Visible = True
    End With
    Set Pic = Nothing
    Set Msk = Nothing
  End If
  On Error GoTo 0
End Sub

Private Sub DeleteCmd(CmdTag As String)
  ' deletes commandbar control that has the specified tag
  Dim Ctrl As CommandBarControl

  On Error Resume Next
  Set Ctrl = CommandBars.FindControl(Tag:=CmdTag)
  If Not Ctrl Is Nothing Then
    Do
      Ctrl.Delete
      Set Ctrl = CommandBars.FindControl(Tag:=CmdTag)
    Loop Until Ctrl Is Nothing
  End If
  On Error GoTo 0
End Sub

Public Sub UpdateState_REFindReplace(WBCount As Long)
  ' enables or disables the menu/toolbar command depending on if a workbook is open
  Dim CmdBar As CommandBar
  Dim Ctrl As CommandBarControl

  On Error Resume Next
  For Each CmdBar In CommandBars
    Set Ctrl = CmdBar.FindControl(Tag:="RegExFindReplaceCmd", Recursive:=True)
    If Not Ctrl Is Nothing Then Ctrl.enabled = (Workbooks.Count > WBCount)
  Next CmdBar
  On Error GoTo 0
End Sub

Public Sub Unload_REFindReplace()
  ' code to run when uninstalling the add-in
  On Error Resume Next
  Call CloseHelp(HHwinHwnd)
  If CInt(Application.Version) > 11 Then Exit Sub
  Call DeleteCmd("RegExFindReplaceCmd")
  On Error GoTo 0
End Sub

Public Sub ShowHelp(ByVal ContextId As Long)
  Const HH_HELP_CONTEXT = &HF

  HHwinHwnd = HtmlHelp(0, Environ("AppData") & "\RegExFindReplace\RegExFR.chm", HH_HELP_CONTEXT, ContextId)
End Sub

Public Sub CloseHelp(ByVal hwnd As Long)
  Const WM_CLOSE = &H10

  If IsWindow(hwnd) Then SendMessage hwnd, WM_CLOSE, 0, 0
End Sub
