::This command script helps to automate the process of resetting Autodesk 2020 licensing.
::Written by Travis Nave, Expert Elite for Autodesk Forums (c) 2019
::v1.3a

@ECHO OFF
SETLOCAL enabledelayedexpansion
:TOP
CLS
COLOR 18

ECHO.
ECHO               PLEASE READ AND UNDERSTAND BEFORE CONTINUING!
ECHO.
ECHO This tool is designed to help automate the process of resetting the default 
ECHO licensing of the Autodesk 2020 product line.  Since the process is more 
ECHO involved than in previous releases, this tool will help reset the licensing
ECHO using the command switches necessary to do so.  You do not have to bother 
ECHO with memorization of commands or the location of the executable.
ECHO.
ECHO This script is a work in progress and may need to be updated as new products
ECHO or service packs are released. Please use at your own risk.
ECHO.
OPENFILES >nul 2>&1
IF %ErrorLevel% EQU 0 ( ECHO You are running as Administrator. ) ELSE ( ECHO Please close and run as Administrator. )

:LIST
ECHO.
ECHO -------------------------------------------------------------------------------
ECHO %USERNAME%, Please choose a selection to make changes on %COMPUTERNAME%:
ECHO.
ECHO  1. LIST Licensed Products	3. Set ADSKFLEX_LICENSE_FILE 
ECHO  2. RESET LGS Licensing		4. Set FLEXLM_TIMEOUT
ECHO					5. Open adskflex*.data file location
ECHO  Q. Quit			H. Help
ECHO.

SET /P CHOICE=Please choose option [1-5, H, Q] %
IF "%CHOICE%"=="1" (
	"%CommonProgramFiles(x86)%\Autodesk Shared\AdskLicensing\Current\helper\AdskLicensingInstHelper.exe" list
	GOTO CHOICE
)

IF "%CHOICE%"=="2" (
	ECHO.
	ECHO Note:  Hit ^<ENTER^> to accept the default value given in the example.
	ECHO.
	SET /P PRODKEY=Input the Product Key [Ex. 001L1]: %
	SET /P PRODVER=Input the Product Version [Ex. 2020.0.0.F]: %
	ECHO.
	IF "!PRODKEY!"=="" SET PRODKEY=001L1
	IF "!PRODVER!"=="" SET PRODVER=2020.0.0.F
	ECHO You entered product key !PRODKEY! and Version !PRODVER!
	ECHO.
	SET /P VERIFY=WARNING, THIS WILL RESET YOUR LICENSE? [Y or N] %
	IF /I "!VERIFY!"=="y" GOTO COMMIT
	IF %ERRORLEVEL% NEQ 0 GOTO LIST
	ECHO Cancelled.
	GOTO LIST
)

IF "%CHOICE%"=="3" (
	SET /P ADSKFLEX=Input Server Info [Ex. @SERVERNAME or 27000@SERVERNAME]: %
	setx ADSKFLEX_LICENSE_FILE "!ADSKFLEX!" /M
	GOTO CHOICE
)

IF "%CHOICE%"=="4" (
	SET /P FLEXLM=Input Timeout [Ex. 1000000]: %
	setx FLEXLM_TIMEOUT "!FLEXLM!" /M
	GOTO CHOICE
)

IF "%CHOICE%"=="5" (
	IF EXIST "%PROGRAMDATA%\Flexnet" (
	START %PROGRAMDATA%\Flexnet
	) ELSE (
  	ECHO Folder location does not exist.
	)
	GOTO CHOICE
)

IF /I "%CHOICE%"=="H" (
	ECHO.
	ECHO 1. LIST Licensed Products - This will list the Autodesk 2020 products
	ECHO That are installed on %COMPUTERNAME%.  Use this to determine the
	ECHO "def_prod_key" and the "def_prod_version" that will be used for option 2.
	ECHO.
	ECHO 2. RESET LGS Licensing - This will ask you for the Product key and the Product
	ECHO version found by using the Option 1 list.  Default values are for AutoCAD 2020.
	ECHO If you make a typo here, it will error out when trying to reset the license.
	ECHO This will also open the LICPATH.LIC file location if you are using NLM.
	ECHO.
	ECHO 3. Set ADSKFLEX_LICENSE_FILE - This will allow you to set the System
	ECHO Environment Variable for your Autodesk Network License Manager Server.
	ECHO.
	ECHO 4. Set FLEXLM_TIMEOUT - This will allow you to set the System Environment
	ECHO Variable for the amount of time to poll the NLM.  1000000 = 1 second.
	ECHO.
	ECHO 5. Open Adskflex*.data file location - This will open the location for the
	ECHO stand-alone registered license files. 
	GOTO CHOICE
)

IF /I "%CHOICE%"=="Q" GOTO END
IF %ERRORLEVEL% NEQ 0 GOTO LIST
ECHO That is not a valid choice.
GOTO LIST

:CHOICE
ECHO.
SET /P NOWWHAT=You can choose to go Back [B] or Quit [Q]: %
IF /I "%NOWWHAT%"=="B" GOTO LIST
IF /I "%NOWWHAT%"=="Q" GOTO END
IF %ERRORLEVEL% NEQ 0 GOTO LIST
ECHO That is not a valid choice.
GOTO LIST

:COMMIT
ECHO.
ECHO If there is no error between the brackets, then the process was successful:
ECHO [
"%CommonProgramFiles(x86)%\Autodesk Shared\AdskLicensing\Current\helper\AdskLicensingInstHelper.exe" change --prod_key %PRODKEY% --prod_ver %PRODVER% --lic_method "" --lic_server_type "" --lic_servers ""
ECHO ]
ECHO.

IF EXIST "%PROGRAMDATA%\Autodesk\AdskLicensingService\!PRODKEY!_!PRODVER!" (
	START %PROGRAMDATA%\Autodesk\AdskLicensingService\!PRODKEY!_!PRODVER!
)
SET /P REPEAT=Would you like to reset another licensed product? [Y or N] %
IF /I "%REPEAT%"=="Y" GOTO LIST
IF %ERRORLEVEL% NEQ 0 GOTO LIST

:END
ECHO.
ECHO -------------------------------------------------------------------------------
ECHO.
ECHO                              PROCESS HAS COMPLETED! 
ECHO.
ECHO -------------------------------------------------------------------------------
ECHO.
ECHO To exit please
PAUSE
ENDLOCAL
eventcreate /t information /id 20 /L application /so "Autodesk Licensing" /d "The Autodesk Licensing Tool Was Run."
EXIT
@EXIT
