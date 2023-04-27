#Requires -RunAsAdministrator

function getDropBoxFolderPath {
    $dropboxFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath '\Dropbox\info.json'
    if (Test-Path $dropboxFolder) {
        $json = Get-Content $dropboxFolder | ConvertFrom-Json
        return $json.personal.path
    } else {
        Write-Host "Dropbox is not installed on this machine"
        return $null
    }
}

try {
    $dropboxPath = getDropBoxFolderPath
    Write-Host "Dropbox path: $dropboxPath"
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
$dropboxPath = getDropBoxFolderPath
$VAULTBACKUPPATH = "$($dropboxPath)\ManAndMachine\VaultBackup\$($env:COMPUTERNAME)\"
$LOGFILEPATH = "$($dropboxPath)\ManAndMachine\$($env:COMPUTERNAME)_Vault_Backup.txt"
$SEVENZIPLOGFILEPATH = "$($dropboxPath)\ManAndMachine\$($env:COMPUTERNAME)_Zip_Log.txt"
$SEVENZIPPATH = "C:\ProgramData\chocolatey\bin\7z.exe"
$RemoveOldBackups = $true
# $ADMSCONSOLEPATH = "C:\Program Files\Autodesk\Vault Server 2023\ADMS Console\Connectivity.ADMSConsole.exe"
# Get the installation path for the ADMS Console
$ADMSCONSOLEPATH = Get-ChildItem -Path "${env:ProgramFiles}\Autodesk" -Recurse -Filter "Connectivity.ADMSConsole.exe" | Select-Object -First 1 -ExpandProperty FullName

# Extract the year from the installation path
$ADMSCONSOLEYEAR = [regex]::Match($ADMSCONSOLEPATH, "Vault Server (\d{4})").Groups[1].Value

# If the ADMS Console is installed, start it
if (-not $ADMSCONSOLEPATH) {
    Write-Warning "ADMS Console $($ADMSCONSOLEYEAR) is not installed"
    return
}

$NUMDAYSBACKUPTOKEEP = "-60"
$MINMEMVALUE = "2000000"
$MINDRIVESPACE = "10000000"

Write-Host "checking free disk space on C:"
$freeSpace = (Get-PSDrive -Name C).Free
if ($freeSpace -lt $MINDRIVESPACE) {
    Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')): low space on C:, exiting" >> $LOGFILEPATH
    exit /b 1
} else {
    Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')): sufficient space on C:, continuing" >> $LOGFILEPATH
}

<# disabling Windows Defender settings#>
Write-Host "Turning off Windows Defender 'RealtimeMonitoring' because it REALLY hampers performance!" >> $LOGFILEPATH
if (-not ((Get-MpPreference | Format-List DisableRealtimeMonitoring) -eq 1)) {
    Set-MpPreference -DisableRealtimeMonitoring 1
}

Write-Host "Turning off Windows Search Service"
$SearchService = Get-Service -Name 'WSearch'
if ($SearchService.Status -eq 'Running') {
    $SearchService | Stop-Service -Force
}
$SearchService | Set-Service -StartupType Disable

Write-Host "pausing Dropbox, Searchindexer, Everything using the sysinternals tool PSSuspend!" >> $LOGFILEPATH
pssuspend.exe dropbox
pssuspend.exe searchindexer
pssuspend.exe everything64
pssuspend.exe onedrive

Write-Host "Attempting to determine installed AntiVirus software" >> $LOGFILEPATH

function Get-AntivirusProcessName {
    $antivirusSoftware = @(
        'McAfee',
        'Symantec',
        'Avast',
        'AVG',
        'Kaspersky',
        'Trend Micro',
        'Bitdefender',
        'ESET',
        'Norton',
        'Sophos',
        'Windows Defender',
        'Malwarebytes',
        'F-Secure',
        'Webroot'
    )
    
    foreach ($software in $antivirusSoftware) {
        $processName = Get-Process -Name $software -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName
        if ($processName) {
            return $processName
        }
    }
}

$antivirusProcessName = Get-AntivirusProcessName
if ($antivirusProcessName) {
    Write-Host "Antivirus software detected. Pausing $antivirusProcessName using PSSuspend" >> $LOGFILEPATH
    pssuspend.exe $antivirusProcessName
} else {
    Write-Host "No antivirus software detected, continuing" >> $LOGFILEPATH
}


Write-Host "THIS WILL STOP THE WEB SERVER AND 'CYCLE' THE SQL SERVER" >> $LOGFILEPATH

IISReset.exe /STOP
Stop-Service 'MSSQL$AUTODESKVAULT'
Start-Service 'MSSQL$AUTODESKVAULT'
IISReset.exe /RESTART

Write-Host "changing to working folder: $VAULTBACKUPPATH"
if (-not (Test-Path $VAULTBACKUPPATH)) {
    Write-Host "creating backup directory"
    New-Item -Path $VAULTBACKUPPATH -ItemType Directory
}

Set-Location $VAULTBACKUPPATH

Write-Host "removing existing backup directories if there are any present" >> $LOGFILEPATH
Get-ChildItem -Path $VAULTBACKUPPATH -Directory -Filter Vault* | Remove-Item -Recurse -Force
Write-Host "performing vault backup from Vault Professional $($ADMSCONSOLEYEAR)" >> $LOGFILEPATH
# -WA is short for Windows Authentication - does not work with Vault basic!
# NO DOMAIN means the -WA option doesn't work.
# call "$ADMSCONSOLEPATH" -Obackup -B"$VAULTBACKUPPATH" -WA -VAL -DBSC -S -L"$LOGFILEPATH"
Start-Process -FilePath $ADMSCONSOLEPATH -ArgumentList "-Obackup", "-B$VAULTBACKUPPATH", "-VUAdministrator", "-VAL", "-DBSC", "-S", "-L$LOGFILEPATH" -Wait

Write-Host "Zip and verify the backup using 7zip" >> $LOGFILEPATH

$VaultBackupFolderToZip = ""

if (Test-Path $SEVENZIPPATH) {
    Write-Host "Beginning zip and verification using 7zip $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" >> $SEVENZIPLOGFILEPATH

    Get-ChildItem -Directory -Filter "Vault*" | ForEach-Object {
        $VaultBackupFolderToZip = $_.Name
        Write-Host "Creating a .7z archive of latest backup using the 7zip command line." >> $LOGFILEPATH
        Start-Process -FilePath $SEVENZIPPATH -ArgumentList "a", "-t7z", "$($VaultBackupFolderToZip).7z", "$($VaultBackupFolderToZip)", "-mmt", "-mx1" -Wait
        Write-Host "Testing the archive - results can be found in the Vault backup log file!" >> $LOGFILEPATH
        Start-Process -FilePath $SEVENZIPPATH -ArgumentList "t", "$($VaultBackupFolderToZip).7z", "-mmt", "-r" -Wait >> $SEVENZIPLOGFILEPATH
    }
    Write-Host "Completed zip and verification using 7zip $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" >> $SEVENZIPLOGFILEPATH
}

If (Test-Path "$($VaultBackupFolderToZip).7z") {
    Write-Host "Removing the unzipped backup directory to prevent Dropbox syncing it to the cloud" >> $LOGFILEPATH
    Get-ChildItem -Directory -Filter "Vault*" | Remove-Item -Recurse -Force
} else {
    Write-Host "no .7z file found, using Windows built-in compression" >> $LOGFILEPATH
    Get-ChildItem -Directory -Filter "Vault*" | ForEach-Object {
        Write-Host "Compressing the backup directory using Windows built-in compression" >> $LOGFILEPATH
        Compress-Archive -Path "$($VaultBackupFolderToZip)" -DestinationPath "$($VaultBackupFolderToZip).zip" -Force
    }
}

if ($RemoveOldBackups) {
    Write-Host "Removing backups older than $NUMDAYSBACKUPTOKEEP days to prevent Dropbox space getting eaten up unnecessarily." >> $LOGFILEPATH
    Get-ChildItem -Path $VAULTBACKUPPATH -Recurse -File -Include *.* | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays($NUMDAYSBACKUPTOKEEP) } | Remove-Item -Force
}
Write-Host "resuming Dropbox, Searchindexer, Everything and Sophos" >> $LOGFILEPATH
pssuspend -r dropbox
pssuspend -r searchindexer
pssuspend -r everything64
pssuspend -r onedrive

if ($antivirusProcessName) {
    Write-Host "Antivirus software detected. Resuming $antivirusProcessName using PSSuspend" >> $LOGFILEPATH
    pssuspend.exe -r $antivirusProcessName
}

Write-Host 'Re-enabling Windows Defender Setting(s) if we modified them' >> $LOGFILEPATH
if (-not ((Get-MpPreference | Format-List DisableRealtimeMonitoring) -eq 0)) {
    Set-MpPreference -DisableRealtimeMonitoring 0
}
Write-host 'Re-enabling Windows Search Service if we disabled it' >> $LOGFILEPATH
$SearchService | Set-Service -StartupType Automatic
$SearchService | Start-Service

Write-Host "Vault backup and zip process complete!" >> $LOGFILEPATH