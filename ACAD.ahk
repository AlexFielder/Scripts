
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

~Mbutton & WheelDown::AltTab ;middle click middle mouse button and roll to see AltTab options
~MButton & WheelUp::ShiftAltTab ;middle click middle mouse button and roll to see AltTab options

~RButton & WheelDown::Ctrl Tab ;middle click middle mouse button and roll to see AltTab options
~RButton & WheelUp::Ctrl Shift Tab ;middle click middle mouse button and roll to see AltTab options