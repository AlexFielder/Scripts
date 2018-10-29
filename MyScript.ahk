; This script was created using Pulover's Macro Creator
; www.macrocreator.com

#NoEnv
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Window
SendMode Input
#SingleInstance Force
SetTitleMatchMode 2
#WinActivateForce
SetControlDelay 1
SetWinDelay 0
SetKeyDelay -1
SetMouseDelay -1
SetBatchLines -1

if WinExist("ahk_class LDViewWindow") {
MsgBox % "The active window's ID is " . WinExist("A")
}
;WinActivate
;Send, ^E
;WinActivate, Export LDraw Model ahk_class #32770
;Send {Enter}
;WinActivate
;Send, ^Q
;}

