<#
.SYNOPSIS
<Brief description>
For examples type:
Get-Help .\<filename>.ps1 -examples
.DESCRIPTION
Copys files from one path to another
.PARAMETER FileList
e.g. C:\path\to\list\of\files\to\copy.txt
.PARAMETER NumConcurrentJobs
default is 25 (but can be 100 if you want to stress the machine to maximum!)
.PARAMETER FilesPerBatch
default is 1000 this can be tweaked if performance becomes an issue because the Threading will HAMMER any network you run it on.
.PARAMETER LogName
Desired log file output. Must include full or relative (.\blah) path. If blank, location of FileList is used.
.PARAMETER DryRun
Boolean value denoting whether we're testing this thing or not. (Default is $false)
.PARAMETER DryRunNum
The number of files to Dry Run. (Default is 100)
.PARAMETER VerifyOnly
Will check both the source and destination files exist and return a hash for each if so.
.PARAMETER Delim
Default is Pipe '|' because some files can have ',' in their name!
.PARAMETER SkipFolderCreation
Default is false.
.EXAMPLE
to run using defaults just call this file:
.\CopyFilesToBackup
to run using anything else use this syntax:
.\CopyFilesToBackup -filelist C:\path\to\list\of\files\to\copy.txt -NumCopyThreads 20 -LogName C:\temp\backup.log -CopyMethod Runspace
.\CopyFilesToBackup -FileList .\copytest.csv -NumCopyThreads 30 -Verbose
.NOTES
#>

[CmdletBinding()] 
Param( 
    [String] $FileList = "C:\temp\Osiris_copytest.csv", #C:\temp\copytest.csv", CopyFilesToBackup.ps1 -FileList C:\temp\Osiris_copytest.csv -CreateFoldersOnly $true
    [int] $NumConcurrentJobs =25,
    [String] $JobName = "BatchCopyJob",
    [int] $FilesPerBatch = 1000,
    [String] $LogName,
    [Boolean] $DryRun = $false, #$true,
    [int] $DryRunNum = 100,
    [Boolean] $VerifyOnly = $false,
    [String] $Delim = '|',
    [Boolean] $SkipFolderCreation = $false
)
<# storing and then disabling important Windows Defender settings  - not sure if this will work on customer machines so needs testing with -DryRun setting #>
Write-Host 'Storing Windows Defender settings so we can turn them back on afterwards'
if (-not ((Get-MpPreference | Format-List DisableRealtimeMonitoring) -eq 1)) {
    Set-MpPreference -DisableRealtimeMonitoring 1
}

<# writing out warnings to the user otherwise we end up in an infinite loop #>
Write-Host 'Killing any processes that might interfere with log writing i.e. Notepad++' -ForegroundColor Red
Write-Host 'If you DO NOT pass a path for a log file, please ensure the folder: '$FileList' csv is located in has no existing *.log files' -ForegroundColor Red -BackgroundColor Yellow
Write-Host 'Failure to heed the above warning will result in PowerShell getting stuck in an infinite loop as the concatenated log will concatenate itself to itself' -ForegroundColor Red -BackgroundColor Yellow
<# Copied from here: https://stackoverflow.com/a/20886446/572634 #>
Function pause ($message)
{
    # Check if running VsCode  #Powershell ISE
    if ($psEditor) #($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host -NoNewLine "$message";
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
}

pause('Press any key to continue...')

<# Copied from here: https://stackoverflow.com/a/28482050/572634 #>
# get Notepad++ process
$Notepadplusplus = Get-Process Notepad++ -ErrorAction SilentlyContinue
if ($Notepadplusplus) {
  # try gracefully first
  $Notepadplusplus.CloseMainWindow()
  # kill after five seconds
  Start-Sleep 5
  if (!$Notepadplusplus.HasExited) {
    $Notepadplusplus | Stop-Process -Force
  }
}
Remove-Variable Notepadplusplus

Write-Host 'Creating log file if it does not exist...'

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
function createLog {
    param([String]$ThisLog, [string] $FileListPath, [int] $JobNum, [Ref]$LogDirectory, [Ref]$LognameBaseName, [string]$FileNameSeed) 
    if ($ThisLog -eq "") {
        if ($null -eq $LogDirectory) { $LogDirectory = "" }
        if ($null -eq $LognameBaseName) { $LognameBaseName = "" }
        [System.IO.Fileinfo]$CsvPath = $FileListPath
        $LogDirectory.Value = $CsvPath.DirectoryName
        $LognameBaseName.Value = $CsvPath.BaseName
        if ($JobNum -eq 0) {
            if ($FileNameSeed -eq "") {
                $ThisLog = $LogDirectory.Value + "\" + $LognameBaseName.Value + ".log"
            } else {
                $ThisLog = $LogDirectory.Value + "\" + $FileNameSeed + ".txt"
            }
        } else {
            if ($FileNameSeed -eq "") {
                $ThisLog = $LogDirectory.Value + "\" + $LognameBaseName.Value + "-$JobNum.log"
            } else {
                $ThisLog = $LogDirectory.Value + "\" + $FileNameSeed + "-$JobNum.txt"
            }
        }
        if (-not (CreateFile($ThisLog)) ) { 
            write-host "Unable to create log, exiting now!"
            Break
        }
    }
    else {
        if (-not (CreateFile($ThisLog)) ) { 
            write-host "Unable to create log, exiting now!"
            Break
        }
    }
    return $ThisLog
}

Write-Host 'Loading CSV data into memory...'

$files = Import-Csv -path $FileList -Delimiter $Delim | Select-Object SrcFileName, DestFileName

Write-Host 'CSV Data loaded...'
if (-not($SkipFolderCreation)) {
    Write-Host 'Collecting unique Directory Names...'

    $allFolders = New-Object "System.Collections.Generic.List[PSCustomObject]"

    ForEach ($f in $files) {
        [System.IO.Fileinfo]$DestinationFilePath = $f.DestFileName
        [String]$DestinationDir = $DestinationFilePath.DirectoryName
        $allFolders.add($DestinationDir)
    }

    $folders = $allFolders | get-unique

    Write-Host 'Creating Directories...'

    $LogName = createLog -ThisLog $LogName -FileListPath $FileList ([Ref]$LogDirectory) ([Ref]$LognameBaseName) -FileNameSeed "AllFolders"
    Add-Content -Path $LogName -Value "[INFO]$Delim[Folder]$Delim[FolderCreated]"

    foreach($DestinationDir in $folders) {
        $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
        $mutex.WaitOne() | Out-Null
        if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
            new-item -Path $DestinationDir -ItemType Directory | Out-Null #-Verbose
            $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"

            if (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir))) {
                Add-Content -Path $LogName -Value "$DateTime$Delim$DestinationDir$Delim$true"
            } else {
                Add-Content -Path $LogName -Value "$DateTime$Delim$DestinationDir$Delim$false"
            }
        } else {
            $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
            Add-Content -Path $LogName -Value "$DateTime$Delim$DestinationDir$Delim$true"
        }
        $mutex.ReleaseMutex() | Out-Null
    }

    Write-Host 'Finished Creating Directories and logging to '$LogName
} else {
    Write-Host 'Skipped folder creation as requested'
}


$scriptBlock = {
    param(
        [PSCustomObject]$filesInBatch, 
        [String]$LogFileName,
        [Boolean]$VerifyOnly,
        [String]$Delim)
        function ProcessFileAndHashToLog {
            param( [String]$LogFileName, [PSCustomObject]$FileColl, [Boolean] $VerifyOnly, [String] $Delim)
            foreach ($f in $FileColl) {
                $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
                [string] $srcHash = ""
                [string] $destHash = ""
                [string] $SrcInfo = ""
                [string] $DestInfo = ""
                if (Test-path([Management.Automation.WildcardPattern]::Escape($f.srcFileName))) {
                    if (-not $VerifyOnly) {
                        if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName)))) {
                            copy-item -path $f.srcFileName -Destination $f.DestFileName | Out-Null #-Verbose
                        }
                    }
                    $srcHash = (Get-FileHash -Path $f.srcFileName -Algorithm SHA1).Hash # SHA1).Hash | Out-Null #could also use MD5 here but it needs testingif (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) {
                    $SrcInfo = $f.srcFileName + $Delim + $srcHash
                } else {
                    $SrcInfo = $f.srcFileName + $Delim + "not found."
                }
                

                if (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) {
                    $destHash = (Get-FileHash -Path $f.destFileName -Algorithm SHA1).Hash # SHA1).Hash | Out-Null #could also use MD5 here but it needs testing
                    $DestInfo = $f.destFileName + $Delim + $destHash
                } else {
                    $DestInfo = $f.destFileName + $Delim + "not found at location."
                }
                # if (-not ($null -eq $destHash) -and -not ($null -eq $srcHash)) {
                $info = $SrcInfo + $Delim + $DestInfo
                # } else {
                    
                # }
                $mutex.WaitOne() | Out-Null
                $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
                if ($DryRun) { Write-Host 'Writing to log file: '$LogFileName'...' }
                Add-Content -Path $LogFileName -Value "$DateTime$Delim$Info"
                $mutex.ReleaseMutex() | Out-Null
            }
        }
        ProcessFileAndHashToLog -LogFileName $LogFileName -FileColl $filesInBatch -VerifyOnly $VerifyOnly -Delim $Delim
}

$i = 0
$j = $filesPerBatch - 1
$batch = 1
$LogName = ""

Write-Host 'Creating jobs...'
if (-not ($DryRun)) {
    $jobs = while ($i -lt $files.Count) {
        $fileBatch = $files[$i..$j]
        $LogName = createLog -ThisLog "" -FileListPath $FileList -JobNum $batch ([Ref]$LogDirectory)
        Add-Content -Path $LogName -Value "[INFO]$Delim[Src Filename]$Delim[Src Hash]$Delim[Dest Filename]$Delim[Dest Hash]"
        Start-ThreadJob -Name $jobName -ArgumentList $fileBatch, $LogName, $VerifyOnly, $Delim -ScriptBlock $scriptBlock  -ThrottleLimit $NumConcurrentJobs

        $batch = $batch + 1
        $i = $j + 1
        $j += $filesPerBatch
        if ($i -gt $files.Count) {$i = $files.Count}
        if ($j -gt $files.Count) {$j = $files.Count}
    }
    Write-Host "Waiting for $($jobs.Count) jobs to complete..."
    Receive-Job -Job $jobs -Wait -AutoRemoveJob
} else {
    Write-Host 'Going in Dry...'
    $DummyFileBatch = $files[$i..$DryRunNum]
    $batch = 1
    $LogName = createLog -ThisLog $LogName -FileListPath $FileList -JobNum $batch ([Ref]$LogDirectory)
    Add-Content -Path $LogName -Value "[INFO]$Delim[Src Filename]$Delim[Src Hash]$Delim[Dest Filename]$Delim[Dest Hash]"
    & $scriptBlock -filesInBatch $DummyFileBatch -LogFileName $LogName -Delim $Delim -VerifyOnly $VerifyOnly
    Write-Host 'That wasn''t so bad was it..?'
}

Write-Host "Concatenating log files into one; One moment please..."
<# copied from here: https://sites.pstcc.edu/elearn/instructional-technology/combine-csv-files-with-windows-10-powershell/ #>
[String] $ConcatenatedLog = createLog -ThisLog "$LogDirectory\Concatenated.txt"
<# this works but Export-Csv wraps everything in speech marks #>
# Get-ChildItem -path $LogDirectory -Filter *.log | Select-Object -ExpandProperty FullName | Import-Csv -Delimiter $Delim | Export-Csv $ConcatenatedLog -NoTypeInformation -Append
<# copied from here originally: https://devblogs.microsoft.com/scripting/remove-unwanted-quotation-marks-from-csv-files-by-using-powershell/ #>
#Original works but is indiscriminate
# Get-ChildItem -path $LogDirectory -Filter *.log | Select-Object -ExpandProperty FullName | Import-Csv -Delimiter '|' | Sort-Object '[INFO]' | convertto-csv -NoTypeInformation -Delimiter $Delim | ForEach-Object { $_ -replace '"', ""} | out-file $ConcatenatedLog -Force -Encoding UTF8
<# this next command ought to work but the 'Where-Object' doesn't work for some reason #>
# Get-ChildItem -path $LogDirectory -Filter *.log | Where-Object {$_.basename -like ‘$LognameBaseName?’} |Select-Object -ExpandProperty FullName | Import-Csv -Delimiter $Delim | Sort-Object '[INFO]' | convertto-csv -NoTypeInformation -Delimiter $Delim | ForEach-Object { $_ -replace '"', ""} | out-file $ConcatenatedLog -Force -Encoding UTF8
Get-ChildItem -path $LogDirectory -Filter *.log | Select-Object -ExpandProperty FullName | Import-Csv -Delimiter $Delim | Sort-Object '[INFO]' | convertto-csv -NoTypeInformation -Delimiter $Delim | ForEach-Object { $_ -replace '"', ""} | out-file $ConcatenatedLog -Force -Encoding UTF8
Write-Host "Concatenated log file = $ConcatenatedLog"

Write-Host 'Re-enabling Windows Defender Setting(s) if we modified them'
if (-not ((Get-MpPreference | Format-List DisableRealtimeMonitoring) -eq 0)) {
    Set-MpPreference -DisableRealtimeMonitoring 0
}
Write-Host "Total time lapsed: $([datetime]::UtcNow - $dtStart)"