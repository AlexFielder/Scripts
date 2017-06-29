@echo off
setlocal enableDelayedExpansion
echo setting up variables...
echo stopping and disabling Sophos
wmic service where "caption like 'Sophos%%'" call Stopservice
wmic service where "caption like 'Sophos%%' and  Startmode<>'Disabled'" call ChangeStartmode Disabled
echo pausing Dropbox, Searchindexer, Everything using the sysinternals tool PSSuspend!
pssuspend dropbox
pssuspend searchindexer
pssuspend everything
SET VAULTBACKUPPATH=C:\Users\alex.fielder\Dropbox\Graitec\Vault Backup
SET LOGFILEPATH=C:\Users\alex.fielder\Dropbox\Graitec\ADR1010AF_Vault_Backup.txt
SET SEVENZIPLOGFILEPATH=C:\Users\alex.fielder\Dropbox\Graitec\ADR1010AF_Zip_Log.txt
SET SEVENZIPPATH=C:\ProgramData\chocolatey\bin\7za.exe
SET ADMSCONSOLEPATH=C:\Program Files\Autodesk\ADMS Professional 2017\ADMS Console\Connectivity.ADMSConsole.exe
SET NUMDAYSBACKUPTOKEEP=-30
echo changing to working folder
cd "C:\Users\alex.fielder\Dropbox\Graitec\Vault Backup"
echo removing existing backup directories if there are any present
for /f %%i in ('dir /a:d /b Vault*') do rd /s /q %%i
echo performing vault backup from Vault Professional 2017
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
wmic service where "caption like 'Sophos%%' and Startmode='Disabled'" call ChangeStartmode Automatic
wmic service where "caption like 'Sophos%%'" call Startservice
echo finished!