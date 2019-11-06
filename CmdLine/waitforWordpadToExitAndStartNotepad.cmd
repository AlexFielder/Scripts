REM copied from here: https://stackoverflow.com/a/30171911/572634
@ECHO OFF

REM TASKKILL /IM NOTEPAD.exe /f

START "" "\\PMT-CABMIGSQL01\Migrate\generic\megabatch_generic_scripts\megacopy.cmd" REM "C:\Program Files\Windows NT\Accessories\wordpad.exe"

:LOOP
tasklist | find /i "CEWatchFolder.exe" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO CONTINUE
) ELSE (
  ECHO WatchedFolder is still running
  Timeout /T 2 /Nobreak
  GOTO LOOP
)

:CONTINUE
cmd /c "D:\Dropbox\Scripts\CmdLine\waitforWordpadToExitAndStartNotepad.cmd"
REM NOTEPAD