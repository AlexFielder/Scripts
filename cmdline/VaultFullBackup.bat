@echo off
setlocal enableDelayedExpansion
echo setting up variables...
SET VAULTBACKUPPATH=C:\Users\alex.fielder\Dropbox\ManAndMachine\VaultBackup
REM SET VAULTBACKUPPATH=F:\Onedrive For Business\OneDrive - GRAITEC\Vault Backup <-removed because OneDrive for business is b0rked.
REM SET LOGFILEPATH=F:\Onedrive For Business\OneDrive - GRAITEC\GRA0387AF_Vault_Backup.txt
SET LOGFILEPATH=C:\Users\alex.fielder\Dropbox\ManAndMachine\%computername%_Vault_Backup.txt
REM SET SEVENZIPLOGFILEPATH=F:\Onedrive For Business\OneDrive - GRAITEC\GRA0387AF_Zip_Log.txt
SET SEVENZIPLOGFILEPATH=C:\Users\alex.fielder\Dropbox\ManAndMachine\AFIELDER-P7760_Zip_Log.txt
SET SEVENZIPPATH=C:\ProgramData\chocolatey\bin\7z.exe
SET ADMSCONSOLEPATH=C:\Program Files\Autodesk\Vault Server 2023\ADMS Console\Connectivity.ADMSConsole.exe
SET NUMDAYSBACKUPTOKEEP=-60
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
echo checking free disk space on C:\
FOR /F "usebackq tokens=3" %%s IN (`DIR C:\ /-C /-O /W`) DO (
	SET FREE_SPACE=%%s
)
if !FREE_SPACE! LSS !MINDRIVESPACE! (
	echo "%DATE% %TIME%: low space on C:, exiting" >> %LOGFILEPATH%
	exit /b 1
) ELSE (
	echo "%DATE% %TIME%: sufficient space on C:\, continuing" >> %LOGFILEPATH%
)
REM echo stopping and disabling Sophos
REM wmic service where "caption like 'Sophos%%'" call Stopservice
REM wmic service where "caption like 'Sophos%%' and  Startmode<>'Disabled'" call ChangeStartmode Disabled
echo pausing Dropbox, Searchindexer, Everything using the sysinternals tool PSSuspend!
pssuspend dropbox
pssuspend searchindexer
pssuspend everything64
pssuspend onedrive

REM THIS WILL STOP THE WEB SERVER AND "CYCLE" THE SQL SERVER
IISRESET /STOP
NET STOP MSSQL$AUTODESKVAULT
NET START MSSQL$AUTODESKVAULT
IISRESET /RESTART

echo changing to working folder: "%VAULTBACKUPPATH%"
REM F:
IF EXIST "%VAULTBACKUPPATH%" (
	cd %VAULTBACKUPPATH%
	echo removing existing backup directories if there are any present
	for /f %%i in ('dir /a:d /b Vault*') do rd /s /q %%i
	echo performing vault backup from Vault Professional 2023
	REM -WA is short for Windows Authentication - does not work with Vault basic!
	REM NO DOMAIN means the -WA option doesn't work.
	REM call "%ADMSCONSOLEPATH%" -Obackup -B"%VAULTBACKUPPATH%" -WA -VAL -DBSC -S -L"%LOGFILEPATH%"
	call "%ADMSCONSOLEPATH%" -Obackup -B"%VAULTBACKUPPATH%" -VUAdministrator -VAL -DBSC -S -L"%LOGFILEPATH%"
)
IF EXIST "%SEVENZIPPATH%" (
	echo Beginning zip and verification using 7zip %date% - %time% >> "%SEVENZIPLOGFILEPATH%"
	for /f "Tokens=*" %%i in ('dir /a:d /b Vault*') do (
	echo creating a .7z archive of latest backup using the 7zip command line.
	call "%SEVENZIPPATH%" a -t7z "%%i.7z" "%%i" -mmt -mx1
	echo testing the archive - results can be found in the Vault backup log file!
	call "%SEVENZIPPATH%" t "%%i.7z" -mmt -r >> "%SEVENZIPLOGFILEPATH%"
	)
	echo completed zip and verification using 7zip %date% - %time% >> "%SEVENZIPLOGFILEPATH%"
)
REM for /f "Tokens=*" %%i in ('dir /b Vault*.7z') do call "%SEVENZIPPATH%" t "%%i" -mmt -r >> "%SEVENZIPLOGFILEPATH%"

echo removing backup directory to prevent Dropbox syncing it to the cloud.
for /f %%i in ('dir /a:d /b Vault*') do rd /s /q %%i
echo removing backups older than 30 days to prevent Dropbox space getting eaten up unecessarily.
forfiles /p "%VAULTBACKUPPATH%" /s /m *.* /d "%NUMDAYSBACKUPTOKEEP%" /c "cmd /c del @path"
echo resuming Dropbox, Searchindexer, Everything and Sophos
pssuspend -r dropbox
pssuspend -r searchindexer
pssuspend -r everything64
pssuspend -r onedrive
REM wmic service where "caption like 'Sophos%%' and Startmode='Disabled'" call ChangeStartmode Automatic
REM wmic service where "caption like 'Sophos%%'" call Startservice
echo finished!