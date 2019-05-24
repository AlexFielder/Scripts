Attribute VB_Name = "REFindReplaceMod"
Option Explicit

Public Sub RegExFindReplaceGUI()
Attribute RegExFindReplaceGUI.VB_Description = "Shows a dialog box for finding or replacing cells using regular expressions."
Attribute RegExFindReplaceGUI.VB_ProcData.VB_Invoke_Func = "X\n14"
'-------------------------------------------------------------------------------
' Shows a dialog box which allows the user to conduct find and replace
' operations using regular expressions.
'-------------------------------------------------------------------------------
  If TypeName(Selection) = "Range" Then
    REFindReplaceFrm.Show
  Else
    MsgBox Prompt:="Please select a cell or cell range first.", Buttons:=vbExclamation, _
      Title:="RegEx Find/Replace"
  End If
End Sub

Public Function RegExFind(text As String, _
  pattern As String, _
  Optional position As Variant = 0, _
  Optional match_case As Boolean = True, _
  Optional multiline As Boolean = False) As Variant
Attribute RegExFind.VB_Description = "Searches the input text using a regular expression pattern.  If position is 0 or omitted, an array of all matches is returned.  Otherwise it returns the Nth match (or if position is negative, the Nth match from the end of the text)."
Attribute RegExFind.VB_HelpID = 30000
Attribute RegExFind.VB_ProcData.VB_Invoke_Func = " \n17"
'-------------------------------------------------------------------------------
' Uses regular expressions to parse a string and return matches to a pattern.
' If position is omitted, the function returns a zero-based array of all
' matches.  If position is 0, it returns the last match.  Otherwise it returns
' the Nth match.  If no match is found, the function returns an empty string.
' If match_case is omitted or True then the pattern must match case.  If
' multiline is omitted or False, ^ and $ only match at the beginning/end of the
' entire cell contents, not at the beginning/end of each line.  You can use
' range references for any of the arguments.  If you return the full array,
' make sure to set up the formula as an array formula.  If you need the array
' formula to go down a column, use the TRANSPOSE worksheet function.
'-------------------------------------------------------------------------------
  Dim RE As Object
  Dim Matches As Object
  Dim Answer() As Variant
  Dim i As Long

  On Error Resume Next
  ' validate position
  If Not IsNumeric(position) Then
    RegExFind = CVErr(xlErrValue)
    Exit Function
  Else
    position = ConvLng(position)
  End If

  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = pattern
    .Global = (position <> 1)
    .IgnoreCase = Not match_case
    .multiline = multiline
  End With

  ' the matches are returned as a zero-based collection
  Set Matches = RE.Execute(text)
  If Matches.Count > 0 Then
    ' next pattern is used to check if result is number
    RE.pattern = "^\s*-?\d+\.?\d*\s*$"
    If position = 0 Then
      ' put all the matches in an array
      ReDim Answer(0 To Matches.Count - 1) As Variant
      For i = 0 To UBound(Answer)
        Answer(i) = Matches(i)
        ' if result is a number, return it as such
        If IsNumeric(Answer(i)) And RE.Test(Answer(i)) Then _
          Answer(i) = Val(Answer(i))
      Next
      RegExFind = Answer
    Else
      Select Case position
        Case -Matches.Count To -1
          ' Nth from last (or last) match
          RegExFind = Matches(Matches.Count + position)
        Case 1 To Matches.Count
          ' Nth match
          RegExFind = Matches(position - 1)
        Case Else
          ' invalid position number
          RegExFind = vbNullString
      End Select
      ' if result is a number, return it as such
      If IsNumeric(RegExFind) And RE.Test(RegExFind) Then _
        RegExFind = Val(RegExFind)
    End If
  Else
    ' there were no matches
    RegExFind = vbNullString
  End If

  Set Matches = Nothing
  Set RE = Nothing
  On Error GoTo 0
End Function

Public Function RegExReplace(text As String, _
  pattern As String, _
  replace_with As String, _
  Optional position As Variant = 0, _
  Optional match_case As Boolean = True, _
  Optional multiline As Boolean = False) As Variant
Attribute RegExReplace.VB_Description = "Replaces text using a regular expression pattern and returns the result.  If position is 0 or omitted, all matches are replaced.  Otherwise the Nth match is replaced (or if position is negative, the Nth match from the end of the text is replaced)."
Attribute RegExReplace.VB_HelpID = 50000
Attribute RegExReplace.VB_ProcData.VB_Invoke_Func = " \n17"
'-------------------------------------------------------------------------------
' Uses regular expressions to parse a string and replace parts of the string
' matching the specified pattern with another string.  The optional argument
' ReplaceAll controls whether all instances of the matched string are replaced
' (True) or just the first (False).  By default, RegExp is case-sensitive in
' pattern matching.  To keep this, omit match_case or set it to True.  If
' multiline is omitted or False, ^ and $ only match at the beginning/end of the
' entire cell contents, not at the beginning/end of each line.  If this
' function is used from Excel, you may substitute range references for all the
' arguments.  Returns a copy of the LookIn string if no matches are found.
'-------------------------------------------------------------------------------
  Dim RE As Object
  Dim Matches As Object
  Dim Match As String
  Dim i As Long

  On Error Resume Next
  ' validate position
  If Not IsNumeric(position) Then
    RegExReplace = CVErr(xlErrValue)
    Exit Function
  Else
    position = ConvLng(position)
  End If

  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = pattern
    .Global = (position <> 1)
    .IgnoreCase = Not match_case
    .multiline = multiline
  End With

  ' determine which match to replace
  If position = 0 Or position = 1 Then
    ' replace all/first match only
    RegExReplace = RE.Replace(text, replace_with)
  Else
    ' manually perform the replace at the requested match position only
    Set Matches = RE.Execute(text)
    If Matches.Count = 0 Or position > Matches.Count Or position < -Matches.Count Then
      ' no matches found or invalid position number
      RegExReplace = text
    Else
      ' adjust position to the actual index of the Matches collection
      position = IIf(position > 0, position - 1, Matches.Count + position)
      With Matches(position)
        If .SubMatches.Count > 0 Then
          ' momentarily substitute literal dollar signs with a placeholder
          replace_with = Replace(replace_with, Chr(26), vbNullString)
          replace_with = Replace(replace_with, "$$", Chr(26))
          ' insert backreference text
          For i = 0 To .SubMatches.Count - 1
            replace_with = Replace(replace_with, "$" & CStr(i + 1), .SubMatches(i))
          Next
          ' re-insert dollar signs
          replace_with = Replace(replace_with, Chr(26), "$")
        End If
        RegExReplace = Left(text, .FirstIndex) & replace_with & Mid(text, .FirstIndex + .Length + 1)
      End With
    End If
  End If

  ' next pattern is used to check if result is number
  RE.pattern = "^\s*-?\d+\.?\d*\s*$"
  If IsNumeric(RegExReplace) And RE.Test(RegExReplace) Then _
    RegExReplace = Val(RegExReplace)

  Set Matches = Nothing
  Set RE = Nothing
  On Error GoTo 0
End Function

Public Function RegExTest(text As String, _
  pattern As String, _
  Optional match_case As Boolean = True, _
  Optional multiline As Boolean = False) As Boolean
Attribute RegExTest.VB_Description = "Evaluates the input text to see if it matches a regular expression pattern and returns True or False accordingly."
Attribute RegExTest.VB_HelpID = 60000
Attribute RegExTest.VB_ProcData.VB_Invoke_Func = " \n17"
'-------------------------------------------------------------------------------
' Returns True/False depending on if text matches the provided
' RegEx pattern.  If match_case is omitted or True then the pattern is case
' sensitive.  If multiline is omitted or False, ^ and $ in the pattern only
' match at the beginning/end of the entire cell contents, not at the beginning/
' end of each line.
'-------------------------------------------------------------------------------
  Dim RE As Object

  On Error Resume Next
  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = pattern
    .Global = False
    .IgnoreCase = Not match_case
    .multiline = multiline
  End With

  ' test to see if there are any matches
  RegExTest = RE.Test(text)

  Set RE = Nothing
  On Error GoTo 0
End Function

Public Function RegExMatchCount(text As String, _
  pattern As String, _
  Optional match_case As Boolean = True, _
  Optional multiline As Boolean = False) As Long
Attribute RegExMatchCount.VB_Description = "Returns the number of times a regular expression pattern matches the input text."
Attribute RegExMatchCount.VB_HelpID = 40000
Attribute RegExMatchCount.VB_ProcData.VB_Invoke_Func = " \n17"
'-------------------------------------------------------------------------------
' Returns the number of times the pattern provided matches text.
' If match_case is omitted or True then the pattern is case sensitive.  If
' multiline is omitted or False, ^ and $ in the pattern only match at the
' beginning/end of the entire cell contents, not at the beginning/end of each
' line.
'-------------------------------------------------------------------------------
  Dim RE As Object
  Dim Matches As Object

  On Error Resume Next
  Set RE = CreateObject("VBScript.RegExp")
  With RE
    .pattern = pattern
    .Global = True
    .IgnoreCase = Not match_case
    .multiline = multiline
  End With

  ' get matches
  Set Matches = RE.Execute(text)
  RegExMatchCount = Matches.Count

  Set Matches = Nothing
  Set RE = Nothing
  On Error GoTo 0
End Function

Private Function ConvLng(ByVal Number As Variant) As Long
'-------------------------------------------------------------------------------
' Returns a number or string converted to a Long data type.  If the number falls
' outside the range of a Long, the number is changed to the upper/lower bound
' accordingly.  Any decimals in the number are discarded in the return value.
' If a string that doesn't start with a number is passed to the function,
' it returns zero.
'-------------------------------------------------------------------------------
  Number = Val(Number)
  Select Case Number
    Case Is > 2147483647
      Number = 2147483647
    Case Is < -2147483648#
      Number = -2147483648#
    Case Else
      Number = Fix(Number)
  End Select
  ConvLng = Number
End Function
