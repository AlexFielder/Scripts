@ECHO OFF

ECHO Setting up variables...

SET "LOGFILEPATH=C:\Users\alex.fielder\Dropbox\Graitec\GRA0387AF_Vault_Backup.txt"
SET "MINMEMVALUE=2000000"
SET "MINDRIVESPACE=10000000"

ECHO Testing available system resources

ECHO Checking free system memory
SET "FPM=sufficient system memory, continuing"
FOR /F "USEBACKQ EOL=F" %%A IN (`WMIC OS WHERE^
 "FreePhysicalMemory < '%MINMEMVALUE%'" GET FreePhysicalMemory 2^>NUL`
) DO FOR %%B IN (%%A) DO SET "FPM=%%B"
IF NOT "%FPM%"=="sufficient system memory, continuing" (
    SET "FPM=low available system memory, exiting")
ECHO "%DATE% %TIME%: %FPM%">>"%LOGFILEPATH%"

ECHO Checking free system drive space
SET "SFP=sufficient space on %SystemDrive%, continuing"
FOR /F "USEBACKQ EOL=F" %%A IN (`WMIC LOGICALDISK WHERE^
     "DeviceID = '%SystemDrive%' AND FreeSpace < '%MINDRIVESPACE%'"^
     GET FreeSpace 2^>NUL`) DO FOR %%B IN (%%A) DO SET "SFP=%%B"
IF NOT "%SFP%"=="sufficient space on %SystemDrive%, continuing" (
    SET "SFP=low space on %SystemDrive%, exiting")
ECHO "%DATE% %TIME%: %SFP%">>"%LOGFILEPATH%"

PAUSE