@echo off

REM TIMEOUT 3

REM taskkill /f /im CEWatchFolder.exe

REM TIMEOUT 3

:LOOP
tasklist | find /i "CEWatchFolder" >nul 2>&1
IF ERRORLEVEL 1 (
  GOTO CONTINUE
) ELSE (
  ECHO CEWatchFolder is still running
  Timeout /T 10 /Nobreak
  GOTO LOOP
)

:CONTINUE

Setlocal EnableDelayedExpansion

set XMLSource=\\PMT-CABMIGSQL01\Migrate\CHANGEME\CAD
set XMLProcessing=C:\watchedfolder\Queue\CHANGEME
set XMLProcessed=\\PMT-CABMIGSQL01\Migrate\CHANGEME\Processed

set MaxLimit=100

REM setlocal enableextensions
set count=0
for %%x in ("%XMLSource%\*.*") do set /a count+=1
REM endlocal
echo %count%

if %count% gtr 0 (
    for /f "tokens=1* delims=[]" %%G in ('dir /A-D /B "%XMLSource%\*.*" ^| find /v /n ""') do (
        copy /y "%XMLSource%\%%~nxH" "%XMLProcessing%"
        move /y "%XMLSource%\%%~nxH" "%XMLProcessed%"
        if %%G==%MaxLimit% goto :StartWatchedFolder REM exit /b 0
    )

) ELSE (
    echo "Done processing..?"
    exit
)

:StartWatchedFolder

    TIMEOUT 3

    start C:\watchedfolder\Application\CEWatchFolder.exe
    start C:\watchedfolder\Application\megacopycad.cmd REM - rename this as appropriate
exit