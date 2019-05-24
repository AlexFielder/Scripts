VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} REFindReplaceFrm 
   Caption         =   "RegEx Find and Replace"
   ClientHeight    =   6075
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   6705
   OleObjectBlob   =   "REFindReplaceFrm.frx":0000
   ShowModal       =   0   'False
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "REFindReplaceFrm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Const LVM_FIRST As Long = &H1000
Private Const LVM_SETCOLUMNWIDTH As Long = (LVM_FIRST + 30)
Private Const LVSCW_AUTOSIZE As Long = -1
Private Const LVSCW_AUTOSIZE_USEHEADER As Long = -2

Private Declare Function SendMessage Lib "user32" _
  Alias "SendMessageA" (ByVal hwnd As Long, _
  ByVal wMsg As Long, _
  ByVal wParam As Long, _
  lParam As Any) As Long

Private ReplaceMode As Boolean

Private Sub ImageHelp_Click()
  Call ShowHelp(20000)
End Sub

Private Sub UserForm_Initialize()
  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  Me.Height = 184
  LblReplaceWith.Visible = False
  ComboReplace.Visible = False
  ChkReplaceFirst.Visible = False
  BtnReplaceAll.Visible = False
  BtnReplace.Visible = False
  With ComboWithin
    .AddItem "Sheet"
    .AddItem "Workbook"
    .ListIndex = 0
  End With
  With ComboSearch
    .AddItem "By Rows"
    .AddItem "By Columns"
    .ListIndex = 1
  End With
  With ComboLookIn
    .AddItem "Formulas"
    .AddItem "Values"
    .AddItem "Comments"
    .ListIndex = 1
  End With
  With FindAllListView
    .ColumnHeaders.Add Key:="Book", text:="Book", Width:=.Width * 0.15
    .ColumnHeaders.Add Key:="Sheet", text:="Sheet", Width:=.Width * 0.14
    .ColumnHeaders.Add Key:="Name", text:="Name", Width:=.Width * 0.1
    .ColumnHeaders.Add Key:="Cell", text:="Cell", Width:=.Width * 0.11
    .ColumnHeaders.Add Key:="Value", text:="Value", Width:=.Width * 0.26
    .ColumnHeaders.Add Key:="Formula", text:="Formula", Width:=.Width * 0.23
  End With
  With ImageHelp
    If .Picture Is Nothing Then
      On Error Resume Next
      .Picture = LoadPicture(Environ("AppData") & "\RegExFindReplace\help.gif")
      On Error GoTo ErrHandler
    End If
  End With
  Exit Sub

ErrHandler:
  Call ErrorNotification(Err.Number, Err.Description, "UserForm_Initialize")
  Err.Clear
End Sub

Private Sub UserForm_Activate()
  Me.Height = 184
  LblFindAllTotal.Visible = False
  FindAllListView.Visible = False
  With ComboFind
    .SetFocus
    .SelStart = 0
    .SelLength = .TextLength
  End With
End Sub

Private Sub TabStrip_Change()
  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler

  With TabStrip
    LblReplaceWith.Visible = .Value
    ComboReplace.Visible = .Value
    ChkReplaceFirst.Visible = .Value
    BtnReplaceAll.Visible = .Value
    BtnReplace.Visible = .Value
  End With
  With ComboLookIn
    If TabStrip.Value Then
      Do While .ListCount > 1
        .RemoveItem (.ListCount - 1)
      Loop
    ElseIf .ListCount = 1 Then
      .AddItem "Values"
      .AddItem "Comments"
    End If
  End With
  Exit Sub

ErrHandler:
  Call ErrorNotification(Err.Number, Err.Description, "TabStrip_Change")
  Err.Clear
End Sub

Private Sub UserForm_QueryClose(Cancel As Integer, CloseMode As Integer)
  If CloseMode = 0 Then
    Call BtnClose_Click
    Cancel = True
  End If
End Sub

Private Sub BtnClose_Click()
  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  Me.Hide
  Exit Sub

ErrHandler:
  Call ErrorNotification(Err.Number, Err.Description, "BtnClose_Click")
  Err.Clear
End Sub

Private Sub BtnFindNext_Click()
  Static FirstMatchingAddr As String
  Static LastFindPattern As String
  Dim FirstAddr As String
  Dim StringToTest As String
  Dim RE As Object
  Dim SearchRange As Range
  Dim FoundCell As Range
  Dim StartCell As Range
  Dim SearchOrder As XlSearchOrder
  Dim LookIn As XlFindLookIn
  Dim StartSheetIndex As Integer
  Dim CurrentSheetIndex As Integer
  Dim SingleSheet As Worksheet
  Dim WB As Workbook
  Dim LookWithinWB As Boolean
  Dim RepeatedFind As Boolean
  Dim AreaIndex As Long
  Dim Complain As Boolean

  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  If TypeName(Selection) <> "Range" Then
    MsgBox Prompt:="Please select a cell or cell range first.", Buttons:=vbExclamation, _
      Title:="RegEx Find/Replace"
    Exit Sub
  End If

  Set WB = ActiveWorkbook
  Set SingleSheet = ActiveSheet
  Set StartCell = ActiveCell

  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = ComboFind.Value
    ' change empty pattern so we can tell if it's a repeated find later
    If .pattern = vbNullString Then .pattern = ".*"
    .Global = False
    .IgnoreCase = Not ChkMatchCase.Value
    .multiline = ChkMultiLine.Value
    RepeatedFind = (.pattern = LastFindPattern And LastFindPattern <> vbNullString)
    LastFindPattern = .pattern
  End With

  ' it's not a repeated find if we've switched active sheets since
  If Left(FirstMatchingAddr, Len(WB.Name & SingleSheet.Name)) <> WB.Name & SingleSheet.Name Then _
    RepeatedFind = False
  LookWithinWB = (ComboWithin.Value = "Workbook")
  SearchOrder = IIf(ComboSearch.Value = "By Columns", xlByColumns, xlByRows)
  Select Case ComboLookIn.Value
    Case "Formulas"
      LookIn = xlFormulas
    Case "Comments"
      LookIn = xlComments
    Case Else
      LookIn = xlValues
  End Select

  ' update drop-down list
  If Not RepeatedFind Then Call AddDropDownItem(ComboFind, ComboFind.Value)

  ' ReplaceMode is True immediately after a successful replace
  If ReplaceMode Then
    FirstAddr = StartCell.Address
    If Not RepeatedFind Or FirstMatchingAddr = vbNullString Then
      FirstMatchingAddr = WB.Name & SingleSheet.Name & FirstAddr
      RepeatedFind = True
    End If
    ReplaceMode = False
    Complain = False
  Else
    Complain = True
    FirstAddr = vbNullString
  End If

  ' check if pattern will match anything
  If RE.Test(vbNullString) Then
    ' ---------- start cell navigation mode ----------
    If Selection.Cells.Count > 1 And Not LookWithinWB Then
      ' navigate selected cells only
      Set SearchRange = Selection
      AreaIndex = GetAreaOfCell(StartCell)
      ' check if next cell is within selection area
      Select Case SearchOrder
        Case xlByRows
          With StartCell
            Set FoundCell = .Offset(0, 1)
            If Application.Intersect(SearchRange.Areas(AreaIndex), FoundCell) Is Nothing Then _
              Set FoundCell = SingleSheet.Cells(.Row + 1, SearchRange.Areas(AreaIndex).Column)
          End With
        Case xlByColumns
          With StartCell
            Set FoundCell = StartCell.Offset(1, 0)
            If Application.Intersect(SearchRange.Areas(AreaIndex), FoundCell) Is Nothing Then _
              Set FoundCell = SingleSheet.Cells(SearchRange.Areas(AreaIndex).Row, StartCell.Column + 1)
          End With
      End Select
      With SearchRange
        If Application.Intersect(.Areas(AreaIndex), FoundCell) Is Nothing Then _
          Set FoundCell = .Areas(GetNextArea(AreaIndex)).Cells(1)
      End With
      FoundCell.Activate
      Exit Sub
    End If
    ' navigate worksheet/workbook
    With SingleSheet
      Select Case SearchOrder
        Case xlByRows
          Set FoundCell = StartCell.Offset(0, 1)
          If Application.Intersect(.UsedRange, FoundCell) Is Nothing Then _
            Set FoundCell = .Cells(StartCell.Row + 1, 1)
        Case xlByColumns
          Set FoundCell = StartCell.Offset(1, 0)
          If Application.Intersect(.UsedRange, FoundCell) Is Nothing Then _
            Set FoundCell = .Cells(1, StartCell.Column + 1)
      End Select
      If Application.Intersect(.UsedRange, FoundCell) Is Nothing Then _
        Set FoundCell = .Cells(1)
    End With
    With FoundCell
      ' check if we've looped around the whole sheet and we're navigating the workbook
      If Not (FirstMatchingAddr = WB.Name & SingleSheet.Name & .Address And _
        LookWithinWB And RepeatedFind) Then
        If FirstMatchingAddr = vbNullString Or Not RepeatedFind Then _
          FirstMatchingAddr = WB.Name & SingleSheet.Name & .Address
        .Select
        Exit Sub
      End If
    End With

    ' go to next sheet
    StartSheetIndex = SingleSheet.Index
    CurrentSheetIndex = StartSheetIndex
    Do
      CurrentSheetIndex = GetNextSheetIndex(WB.Name, CurrentSheetIndex)
      Set SingleSheet = WB.Sheets(CurrentSheetIndex)
    Loop While SheetIsChart(WB.Name, SingleSheet.Name) And CurrentSheetIndex <> StartSheetIndex
    SingleSheet.Activate
    With SingleSheet.Cells(1)
      FirstMatchingAddr = WB.Name & SingleSheet.Name & .Address
      .Select
    End With
    Exit Sub
  End If
  ' ---------- end cell navigation mode ----------

  Application.StatusBar = "Searching...press Esc to cancel"
  If Selection.Cells.Count > 1 And Not LookWithinWB Then
    ' search selected cells only
    Set SearchRange = Selection
  Else
    ' search entire sheet
    Set SearchRange = SingleSheet.Cells
  End If
  Set FoundCell = SearchRange.Find(What:="*", After:=StartCell, LookIn:=LookIn, SearchOrder:=SearchOrder)
  If Not FoundCell Is Nothing Then
    If Len(FirstAddr) = 0 Then FirstAddr = FoundCell.Address
    Do
      StringToTest = GetStringToTest(FoundCell, LookIn)
      If RE.Test(StringToTest) Then
        Application.StatusBar = False
        Call ResetFind
        With FoundCell
          ' check if we've looped around the whole sheet and we're searching the workbook
          If FirstMatchingAddr = WB.Name & SingleSheet.Name & .Address And _
            LookWithinWB And RepeatedFind Then Exit Do
          If FirstMatchingAddr = vbNullString Or Not RepeatedFind Then _
            FirstMatchingAddr = WB.Name & SingleSheet.Name & .Address
          If GetAreaOfCell(FoundCell) = 0 Or LookWithinWB Then _
            .Select Else .Activate
          Exit Sub
        End With
      End If
      Set FoundCell = SearchRange.FindNext(After:=FoundCell)
    Loop Until FoundCell.Address = FirstAddr
  End If

  If Not LookWithinWB And Complain Then
    Application.StatusBar = False
    Call ResetFind
    MsgBox Prompt:="Microsoft Office Excel cannot find the data you're searching for.", _
      Title:="RegEx Find/Replace"
    Exit Sub
  End If

  ' search the rest of the sheets
  StartSheetIndex = SingleSheet.Index
  CurrentSheetIndex = StartSheetIndex
  Do
    Do
      CurrentSheetIndex = GetNextSheetIndex(WB.Name, CurrentSheetIndex)
      Set SingleSheet = WB.Sheets(CurrentSheetIndex)
    Loop While SheetIsChart(WB.Name, SingleSheet.Name) And CurrentSheetIndex <> StartSheetIndex

    Set SearchRange = SingleSheet.UsedRange
    With SearchRange
      Set StartCell = .Cells(.Cells.Count)
      Set FoundCell = .Find(What:="*", After:=StartCell, LookIn:=LookIn, SearchOrder:=SearchOrder)
    End With
    If Not FoundCell Is Nothing Then
      FirstAddr = FoundCell.Address
      Do
        StringToTest = GetStringToTest(FoundCell, LookIn)
        If RE.Test(StringToTest) Then
          Application.StatusBar = False
          Call ResetFind
          FirstMatchingAddr = WB.Name & SingleSheet.Name & FoundCell.Address
          SingleSheet.Activate
          FoundCell.Select
          Exit Sub
        End If
        Set FoundCell = SearchRange.FindNext(After:=FoundCell)
      Loop Until FoundCell.Address = FirstAddr
    End If
  Loop Until CurrentSheetIndex = StartSheetIndex

  Application.StatusBar = False
  Call ResetFind
  If Complain Then _
    MsgBox Prompt:="Microsoft Office Excel cannot find the data you're searching for.", _
      Title:="RegEx Find/Replace"
  Exit Sub

ErrHandler:
  Application.StatusBar = False
  Call ResetFind
  Select Case Err.Number
    Case 18
      Exit Sub
    Case 5019
      MsgBox Prompt:="The regular expression pattern entered is invalid.  Some possible reasons for this error are:" & _
        vbCrLf & "  " & Chr(149) & " A missing opening/closing parenthesis, bracket or brace." & _
        vbCrLf & "  " & Chr(149) & " A special character was not properly escaped." & _
        vbCrLf & "  " & Chr(149) & " The pattern contains an unrecognized character or symbol.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
      With ComboFind
        .SetFocus
        .SelStart = 0
        .SelLength = .TextLength
      End With
      Exit Sub
    Case Else
      Call ErrorNotification(Err.Number, Err.Description, "BtnFindNext_Click")
      Err.Clear
  End Select
End Sub

Private Sub BtnReplace_Click()
  Dim RE As Object

  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  If TypeName(Selection) <> "Range" Then
    MsgBox Prompt:="Please select a cell or cell range first.", Buttons:=vbExclamation, _
      Title:="RegEx Find/Replace"
    Exit Sub
  End If

  Call AddDropDownItem(ComboReplace, ComboReplace.Value)
  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = ComboFind.Value
    .Global = Not ChkReplaceFirst.Value
    .IgnoreCase = Not ChkMatchCase.Value
    .multiline = ChkMultiLine.Value
  End With

  With ActiveCell
    If Not RE.Test(CStr(GetCellContents(ActiveCell))) Then
      MsgBox Prompt:="Microsoft Office Excel cannot find a match.", _
        Title:="RegEx Find/Replace"
      Exit Sub
    End If
    .Formula = RE.Replace(CStr(GetCellContents(ActiveCell)), ComboReplace.Value)
    ReplaceMode = True
  End With

  Call BtnFindNext_Click
  Exit Sub

ErrHandler:
  Select Case Err.Number
    Case 1004
      MsgBox Prompt:="The cell's contents cannot be replaced.  Some possible reasons for this error are:" & _
        vbCrLf & "  " & Chr(149) & " The cell you are trying to change is protected and therefore read-only." & _
        vbCrLf & "  " & Chr(149) & " Text values in formulas are limited to 255 characters." & _
        vbCrLf & "  " & Chr(149) & " The formula length may not exceed the maximum amount of characters allowed in this version of Excel.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
      Exit Sub
    Case 5019
      MsgBox Prompt:="The regular expression pattern entered is invalid.  Some possible reasons for this error are:" & _
        vbCrLf & "  " & Chr(149) & " A missing opening/closing parenthesis, bracket or brace." & _
        vbCrLf & "  " & Chr(149) & " A special character was not properly escaped." & _
        vbCrLf & "  " & Chr(149) & " The pattern contains an unrecognized character or symbol.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
      With ComboFind
        .SetFocus
        .SelStart = 0
        .SelLength = .TextLength
      End With
      Exit Sub
    Case Else
      Call ErrorNotification(Err.Number, Err.Description, "BtnReplace_Click")
      Err.Clear
  End Select
End Sub

Private Sub BtnReplaceAll_Click()
  Dim FirstAddr As String
  Dim Response As Integer
  Dim ReplCount As Long
  Dim SearchRange As Range
  Dim FoundCell As Range
  Dim StartCell As Range
  Dim SearchOrder As XlSearchOrder
  Dim RE As Object
  Dim CellContents As Variant
  Dim Interrupt As Boolean
  Dim WB As Workbook
  Dim SingleSheet As Worksheet
  Dim SheetsToSearch As New Collection
  Dim i As Integer
  Dim Matches As Object
  Dim BlanksMatch As Boolean

  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  If TypeName(Selection) <> "Range" Then
    MsgBox Prompt:="Please select a cell or cell range first.", Buttons:=vbExclamation, _
      Title:="RegEx Find/Replace"
    Exit Sub
  End If

  Call AddDropDownItem(ComboFind, ComboFind.Value)
  Call AddDropDownItem(ComboReplace, ComboReplace.Value)

  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = ComboFind.Value
    .Global = Not ChkReplaceFirst.Value
    .IgnoreCase = Not ChkMatchCase.Value
    .multiline = ChkMultiLine.Value
    If .Test(vbNullString) Then
      If Selection.Cells.Count = 1 Or ComboWithin.Value = "Workbook" Then
        Response = MsgBox("The regular expression pattern entered matches all cells." & _
          vbCrLf & "Replace all cells?", vbExclamation + vbYesNo, "RegEx Find/Replace")
        If Response = vbNo Then Exit Sub
      End If
      BlanksMatch = True
    End If
  End With

  Set WB = ActiveWorkbook
  If WB.Saved = False Then
    Response = MsgBox("Save workbook before continuing?", _
      vbQuestion + vbYesNoCancel, "RegEx Find/Replace")
    If Response = vbYes Then
      If WB.ReadOnly Or WB.Path = vbNullString Then
        Application.Dialogs(xlDialogSaveAs).Show
      Else
        WB.Save
      End If
      If WB.Saved = False Then
        Response = MsgBox("The workbook did not save successfully.  Continue anyway?", _
          vbExclamation + vbYesNo, "RegEx Find/Replace")
        If Response = vbNo Then Exit Sub
      End If
    ElseIf Response = vbCancel Then
      Exit Sub
    End If
  End If

  If ComboWithin.Value = "Workbook" Then
    With WB
      For i = 1 To .Sheets.Count
        If Not SheetIsChart(.Name, .Sheets(i).Name) Then _
          SheetsToSearch.Add Item:=.Sheets(i).Name
      Next
    End With
  Else
    SheetsToSearch.Add Item:=ActiveSheet.Name
  End If

  ReplCount = 0
  SearchOrder = IIf(ComboSearch.Value = "By Columns", xlByColumns, xlByRows)
  Interrupt = False
  Application.StatusBar = "Replacing...press Esc to cancel"

  For i = 1 To SheetsToSearch.Count
    Set SingleSheet = WB.Sheets(SheetsToSearch(i))
    If Selection.Cells.Count > 1 And SheetsToSearch.Count = 1 Then _
      Set SearchRange = Selection Else Set SearchRange = SingleSheet.UsedRange

    Set StartCell = SearchRange.Cells(SearchRange.Cells.Count)
    If SheetsToSearch.Count = 1 Then
      If Not Application.Intersect(SearchRange, ActiveCell) Is Nothing Then _
        Set StartCell = ActiveCell
    End If
    Set FoundCell = SearchRange.Find(What:="*", After:=StartCell, LookIn:=xlFormulas, SearchOrder:=SearchOrder)
    If Interrupt Then Exit For
    If Not FoundCell Is Nothing Then
      FirstAddr = vbNullString
      ' if FirstAddr gets reset in the loop, it's because we can't come back to an empty cell
      Do
        With FoundCell
          If Len(FirstAddr) = 0 Then FirstAddr = .Address
          CellContents = GetCellContents(FoundCell)
          Set Matches = RE.Execute(CStr(CellContents))
          If Matches.Count > 0 Then
            .Formula = RE.Replace(CStr(CellContents), ComboReplace.Value)
            ReplCount = ReplCount + Matches.Count
            If .Formula = vbNullString And .Address = FirstAddr Then _
              FirstAddr = vbNullString
          End If
        End With
        If Interrupt Then Exit Do
        Set FoundCell = SearchRange.FindNext(After:=FoundCell)
        If FoundCell Is Nothing Then Exit Do
      Loop Until FoundCell.Address = FirstAddr
      If Interrupt Then Exit For
    End If
    ' go back and replace empty cells, if necessary
    If BlanksMatch Then _
      SearchRange.Replace What:="", Replacement:=ComboReplace.Value
  Next

  Application.StatusBar = False
  Call ResetFind
  If ReplCount > 0 Then
    If BlanksMatch Then
      If SearchRange.Cells.Count > 1 Then
        MsgBox Prompt:="Excel has completed its search and has made replacements in all selected cells.", _
          Buttons:=vbInformation, Title:="RegEx Find/Replace"
      Else
        MsgBox Prompt:="Excel has completed its search and has made replacements in all cells.", _
          Buttons:=vbInformation, Title:="RegEx Find/Replace"
      End If
    Else
      MsgBox Prompt:="Excel has completed its search and has made " & _
        ReplCount & " replacement" & IIf(ReplCount = 1, ".", "s."), _
        Buttons:=vbInformation, Title:="RegEx Find/Replace"
    End If
  ElseIf Not Interrupt Then
    MsgBox Prompt:="Microsoft Office Excel cannot find any data to replace.", _
      Buttons:=vbExclamation, Title:="RegEx Find/Replace"
  End If
  Exit Sub

ErrHandler:
  Select Case Err.Number
    Case 18
      Interrupt = True
      Resume
    Case 1004
      Application.StatusBar = False
      Call ResetFind
      MsgBox Prompt:="A cell's contents cannot be replaced.  Some possible reasons for this error are:" & _
        vbCrLf & "  " & Chr(149) & " A cell you are trying to change is protected and therefore read-only." & _
        vbCrLf & "  " & Chr(149) & " Text values in formulas are limited to 255 characters." & _
        vbCrLf & "  " & Chr(149) & " A formula's length may not exceed the maximum amount of characters allowed in this version of Excel.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
      Exit Sub
    Case 5019
      Application.StatusBar = False
      Call ResetFind
      MsgBox Prompt:="The regular expression pattern entered is invalid.  Some possible reasons for this error are:" & _
        vbCrLf & "  " & Chr(149) & " A missing opening/closing parenthesis, bracket or brace." & _
        vbCrLf & "  " & Chr(149) & " A special character was not properly escaped." & _
        vbCrLf & "  " & Chr(149) & " The pattern contains an unrecognized character or symbol.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
      With ComboFind
        .SetFocus
        .SelStart = 0
        .SelLength = .TextLength
      End With
      Exit Sub
    Case Else
      Application.StatusBar = False
      Call ResetFind
      Call ErrorNotification(Err.Number, Err.Description, "BtnReplaceAll_Click")
      Err.Clear
  End Select
End Sub

Private Sub BtnFindAll_Click()
  Dim FirstAddr As String
  Dim Key As String
  Dim StringToTest As String
  Dim Response As Integer
  Dim SearchRange As Range
  Dim FoundCell As Range
  Dim LookIn As XlFindLookIn
  Dim SearchOrder As XlSearchOrder
  Dim RE As Object
  Dim Interrupt As Boolean
  Dim WB As Workbook
  Dim SingleSheet As Worksheet
  Dim SheetsToSearch As New Collection
  Dim i As Integer
  Dim LastCell As Range

  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  If TypeName(Selection) <> "Range" Then
    MsgBox Prompt:="Please select a cell or cell range first.", Buttons:=vbExclamation, _
      Title:="RegEx Find/Replace"
    Exit Sub
  End If

  Call AddDropDownItem(ComboFind, ComboFind.Value)

  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = ComboFind.Value
    .Global = False
    .IgnoreCase = Not ChkMatchCase.Value
    .multiline = ChkMultiLine.Value
    If .Test(vbNullString) Then
      MsgBox Prompt:="The regular expression pattern entered matches all cells.", _
        Buttons:=vbInformation, Title:="RegEx Find/Replace"
      Exit Sub
    End If
  End With

  FindAllListView.ListItems.Clear

  Set WB = ActiveWorkbook
  If ComboWithin.Value = "Workbook" Then
    With WB
      For i = 1 To .Sheets.Count
        If Not SheetIsChart(.Name, .Sheets(i).Name) Then _
          SheetsToSearch.Add Item:=.Sheets(i).Name
      Next
    End With
  Else
    SheetsToSearch.Add Item:=ActiveSheet.Name
  End If

  SearchOrder = IIf(ComboSearch.Value = "By Columns", xlByColumns, xlByRows)
  Select Case ComboLookIn.Value
    Case "Formulas"
      LookIn = xlFormulas
    Case "Comments"
      LookIn = xlComments
    Case Else
      LookIn = xlValues
  End Select
  Interrupt = False
  Application.StatusBar = "Searching...press Esc to cancel"

  For i = 1 To SheetsToSearch.Count
    Set SingleSheet = WB.Sheets(SheetsToSearch(i))
    If Selection.Cells.Count > 1 And SheetsToSearch.Count = 1 Then
      Set SearchRange = Selection
      With SearchRange
        Set LastCell = .Areas(.Areas.Count).Cells(.Areas(.Areas.Count).Cells.Count)
      End With
    Else
      Set SearchRange = SingleSheet.UsedRange
      With SearchRange
        Set LastCell = .Cells(.Cells.Count)
      End With
    End If

    Set FoundCell = SearchRange.Find(What:="*", After:=LastCell, LookIn:=LookIn, SearchOrder:=SearchOrder)
    If Interrupt Then Exit For
    If Not FoundCell Is Nothing Then
      FirstAddr = FoundCell.Address
      Do
        StringToTest = GetStringToTest(FoundCell, LookIn)
        If RE.Test(StringToTest) Then
          Key = WB.Name & SingleSheet.Name & FoundCell.Address
          FindAllListView.ListItems.Add Key:=Key, text:=WB.Name
          With FindAllListView.ListItems(Key).ListSubItems
            .Add Key:="Sheet", text:=SingleSheet.Name
            .Add Key:="Name", text:=NameOfRange(FoundCell)
            .Add Key:="Cell", text:=FoundCell.Address
            .Add Key:="Value", text:=CStr(FoundCell.Value)
            .Add Key:="Formula", text:=IIf(FoundCell.HasFormula, FoundCell.Formula, vbNullString)
          End With
        End If
        If Interrupt Then Exit Do
        Set FoundCell = SearchRange.FindNext(After:=FoundCell)
      Loop Until FoundCell.Address = FirstAddr
      If Interrupt Then Exit For
    End If
  Next

  Application.StatusBar = False
  Call ResetFind
  With FindAllListView
    If .ListItems.Count > 0 Then
      LblFindAllTotal.Caption = .ListItems.Count & " cell(s) found"
      If .ListItems.Count > 10 Then
        Call SendMessage(.hwnd, LVM_SETCOLUMNWIDTH, 5, ByVal LVSCW_AUTOSIZE_USEHEADER)
        .ColumnHeaders("Value").Width = .ColumnHeaders("Value").Width - 2
      End If
      .enabled = True
      LblFindAllTotal.Visible = True
      .Visible = True
      Me.Height = 325
      .SetFocus
      Set .SelectedItem = .ListItems(1)
      Call FindAllListView_ItemClick(.ListItems(1))
    ElseIf Not Interrupt Then
      MsgBox Prompt:="Microsoft Office Excel cannot find the data you're searching for.", _
        Title:="RegEx Find/Replace"
    End If
  End With
  Exit Sub

ErrHandler:
  Select Case Err.Number
    Case 18
      Interrupt = True
      Resume
    Case 5019
      Application.StatusBar = False
      Call ResetFind
      MsgBox Prompt:="The regular expression pattern entered is invalid.  Some possible reasons for this error are:" & _
        vbCrLf & "  " & Chr(149) & " A missing opening/closing parenthesis, bracket or brace." & _
        vbCrLf & "  " & Chr(149) & " A special character was not properly escaped." & _
        vbCrLf & "  " & Chr(149) & " The pattern contains an unrecognized character or symbol.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
      With ComboFind
        .SetFocus
        .SelStart = 0
        .SelLength = .TextLength
      End With
      Exit Sub
    Case Else
      Application.StatusBar = False
      Call ResetFind
      Call ErrorNotification(Err.Number, Err.Description, "BtnFindAll_Click")
      Err.Clear
  End Select
End Sub

Private Sub FindAllListView_ItemClick(ByVal Item As MSComctlLib.ListItem)
  Dim WorkbookName As String
  Dim WorksheetName As String

  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler

  WorkbookName = Item.text
  WorksheetName = Item.ListSubItems("Sheet")
  If Not WorksheetExists(WorkbookName, WorksheetName) Then
    FindAllListView.ListItems.Clear
    LblFindAllTotal.Visible = False
    Exit Sub
  End If
  Workbooks(WorkbookName).Sheets(WorksheetName).Activate
  Range(Item.ListSubItems("Cell")).Select
  Exit Sub

ErrHandler:
  Call ErrorNotification(Err.Number, Err.Description, "FindAllListView_ItemClick")
  Err.Clear
End Sub

Private Function GetCellContents(InputCell As Range) As Variant
  On Error Resume Next
  GetCellContents = InputCell.Formula
  If Err.Number > 0 Then
    Err.Clear
    If Not InputCell.HasFormula Then GetCellContents = InputCell.Value Else GetCellContents = vbNullString
  End If
  If Err.Number > 0 Then GetCellContents = vbNullString
  On Error GoTo 0
End Function

Private Function WorksheetExists(WorkbookName As String, WorksheetName As String) As Boolean
  On Error Resume Next
  WorksheetExists = (Workbooks(WorkbookName).Sheets(WorksheetName).Name <> "")
  On Error GoTo 0
End Function

Private Function SheetIsChart(WorkbookName As String, SheetName As String) As Boolean
  Dim TempChart As Chart

  On Error Resume Next
  Set TempChart = Workbooks(WorkbookName).Charts(SheetName)
  SheetIsChart = IIf(TempChart Is Nothing, False, True)
  On Error GoTo 0
End Function

Private Function NameOfRange(InputRange As Range) As String
  On Error Resume Next
  NameOfRange = vbNullString
  NameOfRange = InputRange.Name.Name
  On Error GoTo 0
End Function

Private Function GetNextSheetIndex(WorkbookName As String, FromSheetIndex As Integer) As Integer
  On Error Resume Next
  GetNextSheetIndex = 1
  GetNextSheetIndex = Workbooks(WorkbookName).Sheets(FromSheetIndex + 1).Index
  On Error GoTo 0
End Function

Private Function GetStringToTest(InputCell As Range, LookIn As XlFindLookIn) As String
  On Error Resume Next
  GetStringToTest = vbNullString
  With InputCell
    Select Case LookIn
      Case xlFormulas
        GetStringToTest = CStr(.Formula)
        If Err.Number > 0 Then
          Err.Clear
          If Not .HasFormula Then GetStringToTest = CStr(.Value) Else GetStringToTest = vbNullString
        End If
        If Err.Number > 0 Then GetStringToTest = vbNullString
      Case xlComments
        GetStringToTest = CStr(.Comment.text)
      Case Else
        GetStringToTest = CStr(.Value)
    End Select
  End With
  On Error GoTo 0
End Function

Private Function GetAreaOfCell(InputCell As Range) As Long
  Dim i As Integer

  On Error Resume Next
  GetAreaOfCell = 0
  For i = 1 To Selection.Areas.Count
    If Not Application.Intersect(InputCell, Selection.Areas(i)) Is Nothing Then
      GetAreaOfCell = i
      Exit For
    End If
  Next
  On Error GoTo 0
End Function

Private Function GetNextArea(CurrentArea As Long) As Long
  On Error Resume Next
  GetNextArea = IIf(CurrentArea < Selection.Areas.Count, CurrentArea + 1, 1)
  On Error GoTo 0
End Function

Private Sub ResetFind()
  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler

  If ActiveSheet Is Nothing Then Exit Sub
  With ActiveSheet.UsedRange
    .Find What:="", LookIn:=xlValues, SearchOrder:=xlByColumns
  End With
  Exit Sub

ErrHandler:
  Call ErrorNotification(Err.Number, Err.Description, "ResetFind")
  Err.Clear
End Sub

Private Sub AddDropDownItem(Combo As ComboBox, ItemToAdd As String)
  Dim i As Long

  On Error Resume Next
  If ItemToAdd = vbNullString Then Exit Sub
  With Combo
    .AddItem ItemToAdd, 0
    For i = .ListCount - 1 To 1 Step -1
      If .List(i) = .List(0) Then .RemoveItem i
    Next
  End With
  On Error GoTo 0
End Sub

Private Sub ErrorNotification(ByVal ErrNumber As Long, ByVal ErrDescr As String, _
  CallingProc As String)
  On Error GoTo ErrHandler
  Application.EnableCancelKey = xlErrorHandler
  Select Case ErrNumber
    Case 18
      MsgBox Prompt:="The current action has been interrupted.", _
        Buttons:=vbExclamation, Title:="RegEx Find/Replace"
    Case Else
      MsgBox Prompt:="An unexpected error has occurred." & vbCrLf & _
        "Please note the following information before contacting the author:" & _
        vbCrLf & vbCrLf & "Error " & ErrNumber & ":  " & ErrDescr & vbCrLf & _
        "[" & CallingProc & "]", Buttons:=vbCritical, Title:="RegEx Find/Replace"
  End Select
  Exit Sub

ErrHandler:
  MsgBox Prompt:="A critical error has occurred." & vbCrLf & _
    "Please note the following information before contacting the author:" & _
    vbCrLf & vbCrLf & "Error " & Err.Number & ":  " & Err.Description & vbCrLf & _
    "[ErrorNotification] while reporting error " & ErrNumber & " in [" & _
    CallingProc & "]", Buttons:=vbCritical, Title:="RegEx Find/Replace"
  Err.Clear
End Sub
