REM @echo off

TIMEOUT 3

taskkill /f /im CEWatchFolder.exe

TIMEOUT 3

Setlocal EnableDelayedExpansion

set XMLSource=\\pmt-cabmigsql01\Migrate\OLAP\234814 - CAM\CAD
set XMLProcessing=C:\watchedfolder\Queue\011cadOLAP
set XMLProcessed=\\pmt-cabmigsql01\Migrate\OLAP\234814 - CAM\Processed

set MaxLimit=100

for /f "tokens=1* delims=[]" %%G in ('dir /A-D /B "%XMLSource%\*.*" ^| find /v /n ""') do (
    copy /y "%XMLSource%\%%~nxH" "%XMLProcessing%"
    move /y "%XMLSource%\%%~nxH" "%XMLProcessed%"
    if %%G==%MaxLimit% goto :StartWatchedFolder REM exit /b 0
)

:StartWatchedFolder

TIMEOUT 3

start C:\watchedfolder\Application\CEWatchFolder.exe

exit