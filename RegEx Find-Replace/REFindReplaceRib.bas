Attribute VB_Name = "REFindReplaceRib"
Option Explicit

Public Rib As IRibbonUI

' callback for customUI.onLoad
Private Sub RibbonOnLoad_REFindReplace(Ribbon As IRibbonUI)
  On Error Resume Next
  Set Rib = Ribbon
  On Error GoTo 0
End Sub

' callback for getEnabled
Private Sub GetEnabled_REFindReplace(Ctrl As IRibbonControl, ByRef enabled)
  On Error Resume Next
  enabled = (Workbooks.Count > 0)
  On Error GoTo 0
End Sub

' callback for onAction
Private Sub ShowRegExFindReplace(Ctrl As IRibbonControl)
  Call RegExFindReplaceGUI
End Sub
