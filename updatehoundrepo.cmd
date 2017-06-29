@echo off
echo updating hound with latest from cetdev\version 8.0
SET SOURCEPATH=C:\CETDEV\VERSION8.0\HOME
SET DESTPATH=C:\CM\HOME
robocopy %SOURCEPATH% %DESTPATH% *.RS *.CM /S /PURGE /XO /MT
cd /d %DESTPATH%
for /d %%i in (*.*) do rd "%%i" > nul 2>&1
cd ..
echo pausing whilst we manually run the UTF-8 encoding update in Notepad++
pause
git add .
git commit -m "%DATE% %TIME%: Updating from source via batch file"
git push
