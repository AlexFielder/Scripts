@echo off
setlocal enableDelayedExpansion
echo setting up variables...
SET VAULTBACKUPPATH=F:\Dropbox\Graitec\Vault Backup
SET LOGFILEPATH=F:\Dropbox\Graitec\GRA0387AF_Vault_Backup.txt
SET SEVENZIPLOGFILEPATH=F:\Dropbox\Graitec\GRA0387AF_Zip_Log.txt
SET SEVENZIPPATH=C:\ProgramData\chocolatey\bin\7za.exe
SET ADMSCONSOLEPATH=C:\Program Files\Autodesk\ADMS Professional 2018\ADMS Console\Connectivity.ADMSConsole.exe
SET NUMDAYSBACKUPTOKEEP=-15
SET MINMEMVALUE=2000000
SET MINDRIVESPACE=10000000
REM echo testing available system resources
REM for /f "skip=1" %%p in ('wmic os get freephysicalmemory') do (
	REM SET AVAILABLESYSTEMMEMORY=%%p
	REM )
REM echo "%AVAILABLESYSTEMMEMORY%"
REM if !AVAILABLESYSTEMMEMORY! LSS !MINMEMVALUE! (
	REM echo "%DATE% %TIME%: low available system memory, exiting" >> %LOGFILEPATH%
	REM exit /b 1
REM ) ELSE (
	REM echo "%DATE% %TIME%: sufficient system memory, continuing" >> %LOGFILEPATH%
REM )
echo checking free disk space on F:\
FOR /F "usebackq tokens=3" %%s IN (`DIR F:\ /-C /-O /W`) DO (
	SET FREE_SPACE=%%s
)
if !FREE_SPACE! LSS !MINDRIVESPACE! (
	echo "%DATE% %TIME%: low space on F:, exiting" >> %LOGFILEPATH%
	exit /b 1
) ELSE (
	echo "%DATE% %TIME%: sufficient space on F:\, continuing" >> %LOGFILEPATH%
)
REM echo stopping and disabling Sophos
REM wmic service where "caption like 'Sophos%%'" call Stopservice
REM wmic service where "caption like 'Sophos%%' and  Startmode<>'Disabled'" call ChangeStartmode Disabled
echo pausing Dropbox, Searchindexer, Everything using the sysinternals tool PSSuspend!
pssuspend dropbox
pssuspend searchindexer
pssuspend everything

REM THIS WILL STOP THE WEB SERVER AND "CYCLE" THE SQL SERVER
IISRESET /STOP
NET STOP MSSQL$AUTODESKVAULT
NET START MSSQL$AUTODESKVAULT
IISRESET /RESTART

echo changing to working folder
F:
cd "F:\Dropbox\Graitec\Vault Backup"
echo removing existing backup directories if there are any present
for /f %%i in ('dir /a:d /b Vault*') do rd /s /q %%i
echo performing vault backup from Vault Professional 2018
REM -WA is short for Windows Authentication - does not work with Vault basic!
call "%ADMSCONSOLEPATH%" -Obackup -B"%VAULTBACKUPPATH%" -WA -VAL -DBSC -S -L"%LOGFILEPATH%"

echo Beginning zip and verification using 7zip %date% - %time% >> "%SEVENZIPLOGFILEPATH%"
for /f "Tokens=*" %%i in ('dir /a:d /b Vault*') do (
echo creating a .7z archive of latest backup using the 7zip command line.
call "%SEVENZIPPATH%" a -t7z "%%i.7z" "%%i" -mmt -mx1
echo testing the archive - results can be found in the Vault backup log file!
call "%SEVENZIPPATH%" t "%%i.7z" -mmt -r >> "%SEVENZIPLOGFILEPATH%"
)
echo completed zip and verification using 7zip %date% - %time% >> "%SEVENZIPLOGFILEPATH%"

REM for /f "Tokens=*" %%i in ('dir /b Vault*.7z') do call "%SEVENZIPPATH%" t "%%i" -mmt -r >> "%SEVENZIPLOGFILEPATH%"

echo removing backup directory to prevent Dropbox syncing it to the cloud.
for /f %%i in ('dir /a:d /b Vault*') do rd /s /q %%i
echo removing backups older than 30 days to prevent Dropbox space getting eaten up unecessarily.
forfiles /p "%VAULTBACKUPPATH%" /s /m *.* /d "%NUMDAYSBACKUPTOKEEP%" /c "cmd /c del @path"
echo resuming Dropbox, Searchindexer, Everything and Sophos
pssuspend -r dropbox
pssuspend -r searchindexer
pssuspend -r everything
REM wmic service where "caption like 'Sophos%%' and Startmode='Disabled'" call ChangeStartmode Automatic
REM wmic service where "caption like 'Sophos%%'" call Startservice
echo finished!