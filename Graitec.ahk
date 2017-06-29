
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.




; should disable the F1 key unless it's pressed in conjunction with the shift key.
#IfWinActive AutoCAD
+F1::F1 ; (Shift + F1 = F1)
F1::Escape ; (F1 = Escape)
ScrollLock::Escape ; (ScrollLock = Escape)
PrintScreen::Shift ; (Printscreen = Shift)
#IfWinActive
#IfWinActive Autodesk
+F1::F1 ; (Shift + F1 = F1)
F1::Escape ; (F1 = Escape)
#IfWinActive

;should provide today's date in YYYY-MM-DD format:
+^d::
FormatTime, CurrentDateTime,, ShortDate
Send %CurrentDateTime%
return

;should allow us to insert something from the clipboard inside Inventor
#IfWinActive Autodesk Inventor
+^m::Send Master-{ENTER}
return

#IfWinActive Parameters
+^m::Send Master{ENTER}
return

