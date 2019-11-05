REM copied from here: https://stackoverflow.com/a/30171911/572634
@ECHO OFF

TASKKILL NOTEPAD

START "" "C:\Program Files\Windows NT\Accessories\wordpad.exe"

:LOOP
tasklist | find /i "WORDPAD" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO CONTINUE
) ELSE (
  ECHO Wordpad is still running
  Timeout /T 5 /Nobreak
  GOTO LOOP
)

:CONTINUE
NOTEPAD