# 
<#
.SYNOPSIS
Creates a .zip file of the given directory and removes specific subfolders
from the archive.
.DESCRIPTION
This script creates a .zip file of the given directory and removes specific
subfolders from the archive.
.EXAMPLE
CreateZipForUload.ps1 -Folder "C:\Temp\MyFolder" -FoldersToRemove "_V|Oldversions|nppBackup" -FilesToRemove "*.bak" -Output "C:\Temp\MyFolder.zip"
.PARAMETER Folder
The folder to create the .zip file from.
.PARAMETER FoldersToRemove
The subfolders to remove from the archive. Pipe (|) delimited.
.PARAMETER FilesToRemove
The files to remove from the archive (*.ext). Pipe (|) delimited.
.PARAMETER Output
The output file name.
.PARAMETER ForceOverwrite
If true, the output file will be overwritten if it exists.
.PARAMETER Delim
Default is '|' but can be overidden.
.PARAMETER TempPath
The path to the temporary folder. Default is C:\Temp.
.EXITCODE
0 - Success
1 - Error
.SEEALSO
CreateZipForUpload.ps1
.NOTES
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Folder = 'C:\Users\alex.fielder\OneDrive\Inventor\Designs\Vista Engineering\Configurator\Template',
    [Parameter(Mandatory=$false, Position=1)]
    [string]$FoldersToRemove = '_V|Oldversions|nppBackup',
    [Parameter(Mandatory=$false, Position=2)]
    [string]$FilesToRemove = '*.bak',
    [Parameter(Mandatory=$false, Position=3)]
    [string]$Output = 'C:\Users\alex.fielder\OneDrive\Inventor\Designs\Vista Engineering\Configurator',
    [Parameter(Mandatory=$false, Position=4)]
    [Boolean]$ForceOverwrite = $true,
    [String] $Delim = '|',
    [String]$TempPath = 'C:\Temp'
)
#Requires -RunAsAdministrator

function CreateFile([string]$filepath) {
    if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($filepath)))) {
        new-item -Path $filepath -ItemType File
    }
    if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($filepath)))) {
        return $false
    } else {
        return $true
    }
}

$dtStart = [datetime]::UtcNow
[String] $LogDirectory = ""
[String] $LognameBaseName = ""
$LogName = ""
$7ZipPath = "C:\ProgramData\chocolatey\bin\7z.exe"

function CreateLog {
    param([String]$ThisLog, 
            [string] $FolderPath, 
            [Ref]$LogDirectory, 
            [Ref]$LognameBaseName, 
            [string]$FileNameSeed)
    if ($ThisLog -eq "") {
        if ($null -eq $LogDirectory) { $LogDirectory = "" }
        if ($null -eq $LognameBaseName) { $LognameBaseName = "" }
        [System.IO.FileInfo]$LogPath = $FolderPath
        $LogDirectory.Value = $LogPath.DirectoryName
        $LognameBaseName.Value = $LogPath.BaseName
        if ($FileNameSeed -eq "") {
            $ThisLog = $LogDirectory.Value + "\" + $LognameBaseName.Value + ".log"
        } else {
            $ThisLog = $LogDirectory.Value + "\" + $FileNameSeed + ".txt"
        }
        if (-not (CreateFile($ThisLog)) ) { 
            write-host "Unable to create log, exiting now!"
            Break
        }
    } else {
        if (-not (CreateFile($ThisLog)) ) { 
            write-host "Unable to create log, exiting now!"
            Break
        }
    }
    return $ThisLog
}


function GetFolderList([System.IO.DirectoryInfo]$dir, [string]$SearchPattern) {
    [System.Collections.Generic.List[System.IO.DirectoryInfo]]$FolderList = (Get-ChildItem -Path $dir -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Select-Object | Where-Object {$_.FullName -match $SearchPattern})
    return $FolderList
}

# basic steps are
# 1. copy the folder to a temp folder: C:\Temp\MyFolder
# 2. remove the folders in $FoldersToRemove
# 3. remove the files in $FilesToRemove
# 4. zip the temp folder to $Output
# 5. delete the temp folder

[System.IO.FileInfo]$TempFolder = $Folder
$TempPath = $TempPath + "\" + $TempFolder.Name

if([System.IO.Directory]::Exists($TempPath)) {
    write-host "Temp folder already exists, deleting it now!"
    [System.IO.Directory]::Delete($TempPath, $true)
}

Write-Host 'Creating log file if it does not exist...'
$LogName = CreateLog -ThisLog $LogName -FolderPath $TempPath ([Ref]$LogDirectory) ([Ref]$LognameBaseName) -FileNameSeed $LogNameSeed

[System.IO.DirectoryInfo]$TempFolderPath = New-Object -TypeName System.IO.DirectoryInfo($TempPath)

Write-Host "Begin copying $($Folder) to $($Output)..."

Copy-Item -Path $Folder -Destination $TempPath -Recurse -Force
[System.Collections.Generic.List[System.IO.DirectoryInfo]]$FoldersToRemoveFromTempPath = GetFolderList -dir $TempFolderPath -SearchPattern $FoldersToRemove

ForEach-Object -InputObject $FoldersToRemoveFromTempPath -Process {
    Add-Content $LogName "Removing folder: $($_.FullName)"
    Remove-Item -Path $_.FullName -Recurse -Force
}

# add the remaining folder structure to Template-YYYY-MM-DD.zip
# write today's date in YYYY-MM-DD format
$Date = [datetime]::UtcNow
$Date = $Date.ToString("yyyy-MM-dd")
$Output = $Output + "\" + $TempFolder.Name + "-$($Date)-automated.zip"

Set-Alias 7zip $7zipPath
# install 7zip if it is not installed
if (Get-Module -ListAvailable -Name 7Zip4PowerShell) {
    Write-Host "Module exists"
} 
else {
    Write-Host "Module does not exist, installing..."
    Install-Module -Name 7Zip4PowerShell -Verbose
}

# & "C:\Program Files\7-Zip\7z.exe" -mx=9 a "c:\BackupFolder\backup.zip" "c:\BackupFrom\backMeUp.txt" 
Write-Host "Creating zip file $($Output)..."
Compress-7Zip -ArchiveFileName $Output -Path $TempFolderPath.FullName -CompressionLevel Fast
# 7Zip -tzip -r -mx=9 -o$($Output) $($TempPath) | Out-File $LogName
