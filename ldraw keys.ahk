
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.




#IfWinActive ahk_class LDViewWindow ; #IfWinActive LDView
Send ^e ; ctrl + e (to export)
Send {ENTER} ; to save
Send ^q ; ctrl + q (to quit)
#IfWinActive
