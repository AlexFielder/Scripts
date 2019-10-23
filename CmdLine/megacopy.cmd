@echo off

set XMLSource=C:\temp\Source
set XMLProcessing=C:\temp\Processing
set XMLProcessed=C:\temp\Processed

set MaxLimit=20

for /f "tokens=1* delims=[]" %%G in ('dir /A-D /B "%XMLSource%\*.*" ^| find /v /n ""') do (
    copy /y "%XMLSource%\%%~nxH" "%XMLProcessing%"
    move /y "%XMLSource%\%%~nxH" "%XMLProcessed%"
    if %%G==%MaxLimit% exit /b 0
)