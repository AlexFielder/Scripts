REM copied from here: https://stackoverflow.com/a/8185270/572634
@ECHO OFF

PSKILL NOTEPAD

START "" "C:\Program Files\Windows NT\Accessories\wordpad.exe"

:LOOP
PSLIST wordpad >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO CONTINUE
) ELSE (
  ECHO Wordpad is still running
  TIMEOUT /T 5
  GOTO LOOP
)

:CONTINUE
NOTEPAD