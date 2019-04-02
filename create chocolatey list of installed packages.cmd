@echo off
REM setlocal enableDelayedExpansion
SET APPCONFIGPATH=\App config files\Chocolatey (%computername%)\installed-%DATE%.log
for %%? in ("%~dp0..") do set parent=%%~f?
REM echo/%parent% is your parent directory
REM echo/%APPCONFIGPATH% is your output path
IF NOT EXIST "%parent%\App config files\Chocolatey (%computername%)" (MKDIR "%parent%\App config files\Chocolatey (%computername%)")
echo output folder is: "%parent%\App config files\Chocolatey (%computername%)"
REM SET OUTPUT="%parent%\App config files\Chocolatey (%computername%)\installed-%DATE%-%TIME%.log"
echo outputting data to: "%parent%\App config files\Chocolatey (%computername%)\installed-%DATE%-%TIME%.log"
choco list -lo > "%parent%\App config files\Chocolatey (%computername%)\installed-%DATE%-%TIME%.log"
echo outputting reinstall script to: '%parent%\App config files\Chocolatey (%computername%)\install-script-%DATE%-%TIME%.ps1'
powershell -command "& '.\Generate_Choco_Install_script.ps1' '%parent%\App config files\Chocolatey (%computername%)\install-script-%DATE%-%TIME%.ps1'"
