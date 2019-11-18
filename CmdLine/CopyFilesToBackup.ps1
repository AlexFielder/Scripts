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
.PARAMETER CreateFoldersOnly
Default is false.
.PARAMETER Header
Default is: ('INFO','srcfilename', 'srcHash','destfilename','destHash', 'ConisioDocID', 'ConisioVersion', 'ConisioIdentifier', 'LatestRevisionNo','error','errorDestination')
This can be added to/amended by passing a value; otherwise we use the default ^
.EXAMPLE
to run using defaults just call this file:
.\CopyFilesToBackup
to run using anything else use this syntax:
.\CopyFilesToBackup -filelist C:\path\to\list\of\files\to\copy.txt -NumCopyThreads 20 -LogName C:\temp\backup.log -CopyMethod Runspace
.\CopyFilesToBackup -FileList .\copytest.csv -NumCopyThreads 30 -Verbose
.\CopyFilesToBackup.ps1 -FileList '\\servername\path\to\csv\headersmustbeinHeaderabove.csv' -NumConcurrentJobs 40 -JobName 'UseAUniqueName' -FilesPerBatch 250 -LogName '\\servername\path\to\log\file.log' -VerifyOnly $true -SkipFolderCreation $true -CreateFoldersOnly $false
.NOTES
#>

[CmdletBinding()] 
Param( 
    [String] $FileList = "C:\temp\Osiris_copytest.csv", #C:\temp\copytest.csv", CopyFilesToBackup.ps1 -FileList C:\temp\Osiris_copytest.csv -CreateFoldersOnly $true
    [int] $NumConcurrentJobs =25,
    [String] $JobName = "BatchCopyJob",
    [int] $FilesPerBatch = 1000,
    [String] $LogName,
    [Boolean] $DryRun = $false, #$true, #
    [int] $DryRunNum = 100,
    [Boolean] $VerifyOnly = $false,
    [String] $Delim = '|',
    [Boolean] $SkipFolderCreation = $false, #$true, #
    [Boolean] $CreateFoldersOnly = $false,
    [String[]] $Header = ('INFO','srcfilename', 'srcHash','destfilename','destHash', 'ConisioDocID', 'ConisioVersion', 'ConisioIdentifier', 'LatestRevisionNo','error','errorDestination')
)
#Requires -RunAsAdministrator
<# disabling Windows Defender settings#>
Write-Host "Turning off Windows Defender 'RealtimeMonitoring' because it REALLY hampers performance!"
if (-not ((Get-MpPreference | Format-List DisableRealtimeMonitoring) -eq 1)) {
    Set-MpPreference -DisableRealtimeMonitoring 1
}

<# writing out warnings to the user otherwise we end up in an infinite loop #>
Write-Host 'Killing any processes that might interfere with log writing i.e. Notepad++' -ForegroundColor Red
Write-host 'Also disabling Windows search service as this can also interfere with the writing/copying of files'
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

$SearchService = Get-Service -Name 'WSearch'
if ($SearchService.Status -eq 'Running') {
    $SearchService | Stop-Service -Force
}
$SearchService | Set-Service -StartupType Disable

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
$files = Import-Csv -path $FileList -Delimiter $Delim | Select-Object $Header #SrcFileName, DestFileName #$files = Import-Csv -path $FileList -Delimiter $Delim -Header $Header #| Select-Object SrcFileName, DestFileName
Write-Host 'CSV Data loaded...'

Write-Host "reformatting list of $Header"
[String] $FormattedHeaders = ""

for ($i = 0; $i -lt $Header.Length; $i++) {
    if ($FormattedHeaders -eq "") {
        $FormattedHeaders = "["+ $Header[$i] + "]$Delim"
    } else {
        if($i -eq $Header.Length -1) {
            $FormattedHeaders = "$FormattedHeaders"+ $Header[$i]
        } else {
            $FormattedHeaders = "$FormattedHeaders"+ $Header[$i] + "$Delim"
        }
    }
}
Write-Host "reformatted headers looks like: $FormatterHeaders"

if (-not($SkipFolderCreation)) {
    Write-Host 'Collecting unique Directory Names...'

    $allFolders = New-Object "System.Collections.Generic.List[PSCustomObject]"

    ForEach ($f in $files) {
        [System.IO.Fileinfo]$DestinationFilePath = $f.DestFileName
        [String]$DestinationDir = $DestinationFilePath.DirectoryName
        $allFolders.add($DestinationDir)
    }

    $folders = $allFolders | get-unique

    $scriptBlockFolders = {
        param(
            [PSCustomObject]$foldersInBatch,
            [String]$LogFileName,
            [String]$Delim
        )

        function CreateBatchOfFolders {
            param([String]$LogFileName, [PSCustomObject]$FolderColl, [String]$Delim)
            foreach($DestinationDir in $FolderColl) {
                $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
                $mutex.WaitOne() | Out-Null
                if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
                    Try {
                        new-item -Path $DestinationDir -ItemType Directory | Out-Null #-Verbose
                        $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
                    } catch [System.IO.IOException] {
                        Add-Content -Path $LogFileName -Value "Error creating folder: $DestinationDir"
                    } catch {
                        Write-Host "An unknown error occurred:"
                        Write-Host $_.ScriptStackTrace
                    }

                    if (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir))) {
                        Add-Content -Path $LogFileName -Value "$DateTime$Delim$DestinationDir$Delim$true"
                    } else {
                        Add-Content -Path $LogFileName -Value "$DateTime$Delim$DestinationDir$Delim$false"
                    }
                } else {
                    $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
                    Add-Content -Path $LogFileName -Value "$DateTime$Delim$DestinationDir$Delim$true"
                }
                $mutex.ReleaseMutex() | Out-Null
            }
        }
        CreateBatchOfFolders -LogFileName $LogFileName -FolderColl $foldersInBatch -Delim $Delim
    }

    # Write-Host 'Creating Folders...'
    
    $foldersPerBatch = $filesPerBatch
    $i = 0
    $j = $foldersPerBatch - 1
    $batch = 1
    $LogName = ""
    
    Write-Host 'Creating Folder Jobs...'
    if (-not ($DryRun)) {
        $jobs = while ($i -lt $folders.Count) {
            $fileBatch = $folders[$i..$j]
            $LogName = createLog -ThisLog "" -FileListPath $FileList -JobNum $batch ([Ref]$LogDirectory) ([Ref]$LognameBaseName) -FileNameSeed "Folders"
            Add-Content -Path $LogName -Value "[INFO]|[Folder]|[FolderCreated]"
            Start-ThreadJob -Name "Folders-$jobName" -ArgumentList $fileBatch, $LogName, $Delim -ScriptBlock $scriptBlockFolders  -ThrottleLimit $NumConcurrentJobs
    
            $batch = $batch + 1
            $i = $j + 1
            $j += $foldersPerBatch
            if ($i -gt $folders.Count) {$i = $folders.Count}
            if ($j -gt $folders.Count) {$j = $folders.Count}
        }
        Write-Host "Waiting for $($jobs.Count) jobs to complete..."
        Receive-Job -Job $jobs -Wait -AutoRemoveJob
    } else {
        Write-Host 'Going in Dry...'
        $DummyFolderBatch = $folders[$i..$DryRunNum]
        $batch = 1
        $LogName = createLog -ThisLog $LogName -FileListPath $FileList -JobNum $batch ([Ref]$LogDirectory) ([Ref]$LognameBaseName) -FileNameSeed "Folders"
        Add-Content -Path $LogName -Value "[INFO]|[Folder]|[FolderCreated]"
        & $scriptBlockFolders -filesInBatch $DummyFolderBatch -LogFileName $LogName
        Write-Host 'That wasn''t so bad was it..?'
    }

    # $LogName = createLog -ThisLog $LogName -FileListPath $FileList ([Ref]$LogDirectory) ([Ref]$LognameBaseName) -FileNameSeed "AllFolders"
    # Add-Content -Path $LogName -Value "[INFO]$Delim[Folder]$Delim[FolderCreated]"

    # foreach($DestinationDir in $folders) {
    #     $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
    #     $mutex.WaitOne() | Out-Null
    #     if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
    #         new-item -Path $DestinationDir -ItemType Directory | Out-Null #-Verbose
    #         $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"

    #         if (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir))) {
    #             Add-Content -Path $LogName -Value "$DateTime$Delim$DestinationDir$Delim$true"
    #         } else {
    #             Add-Content -Path $LogName -Value "$DateTime$Delim$DestinationDir$Delim$false"
    #         }
    #     } else {
    #         $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
    #         Add-Content -Path $LogName -Value "$DateTime$Delim$DestinationDir$Delim$true"
    #     }
    #     $mutex.ReleaseMutex() | Out-Null
    # }

    Write-Host 'Finished Creating Directories and logging to '$LogName
} else {
    Write-Host 'Skipped folder creation as requested'
}

if(-not ($CreateFoldersOnly)) {
    $scriptBlock = {
        param(
            [PSCustomObject]$filesInBatch, 
            [String]$LogFileName,
            [Boolean]$VerifyOnly,
            [String]$Delim,
            [String[]]$Header,
            [Boolean]$ForceOverwrite)
            function ProcessFileAndHashToLog {
                param( [String]$LogFileName, [PSCustomObject]$FileColl, [Boolean] $VerifyOnly, [String] $Delim, [String[]]$Header, [Boolean]$ForceOverwrite)
                foreach ($f in $FileColl) {
                    $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
                    [string] $srcHash = ""
                    [string] $destHash = ""
                    [string] $SrcInfo = ""
                    [string] $DestInfo = ""
                    <# Try Catch added from here: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally?view=powershell-6 #>
                    try {
                        $SrcInfo = $f.srcFileName + $Delim
                        $DestInfo = $f.destFileName + $Delim
                        if ((Test-path([Management.Automation.WildcardPattern]::Escape($f.srcFileName))) -and (-not ((Get-Item $f.srcFileName) -is [System.IO.DirectoryInfo]))) {
                            if (-not $VerifyOnly) {
                                if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName)))) {
                                    copy-item -path $f.srcFileName -Destination $f.DestFileName | Out-Null #-Verbose
                                } elseif ((Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) -and $ForceOverwrite) {
                                    copy-item -path $f.srcFileName -Destination $f.DestFileName -Force $true | Out-Null #-Verbose
                                }
                            }
                            $srcHash = (Get-FileHash -LiteralPath $f.srcFileName -Algorithm SHA1).Hash # SHA1).Hash | Out-Null #could also use MD5 here but it needs testingif (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) {
                            $SrcInfo = $SrcInfo + $srcHash
                        } else {
                            $SrcInfo = $SrcInfo + "not found."
                        }
                        

                        if (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) {
                            $destHash = (Get-FileHash -LiteralPath $f.destFileName -Algorithm SHA1).Hash # SHA1).Hash | Out-Null #could also use MD5 here but it needs testing
                            $DestInfo = $DestInfo + $destHash
                        } else {
                            $DestInfo = $DestInfo + "not found at location."
                        }
                        # if (-not ($null -eq $destHash) -and -not ($null -eq $srcHash)) {
                        [String] $FileData = ''
                        foreach ($s in $Header) {
                            if (-not ($s -like 'src*')  -and (-not ($s -like 'dest*')) -and (-not ($s -eq 'INFO')) -and (-not ($s -like 'erro*'))) {
                                if ($FileData -eq "") {
                                    #starts with a delimiter because the last info above doesn't end with one.
                                    $FileData = $Delim, $f."$s"
                                } else {
                                    $FileData = $FileData, $Delim, $f."$s"
                                }
                            }
                        }
                        $info = $SrcInfo + $DestInfo + $FileData
                    } catch [System.IO.IOException] {
                        $info = $SrcInfo + $DestInfo + $FileData + $Delim + "Error reading or copying file: " + $f.srcFileName + $Delim + "To destination: " + $f.destFileName
                    } catch {
                        # Write-Host "An unknown error occurred:"
                        # Write-Host $_.ScriptStackTrace
                        $info = $SrcInfo + $DestInfo + $FileData + $Delim + "Error processing: " + $f.srcFileName + $Delim + "To destination: " + $f.destFileName
                    }
                    $mutex.WaitOne() | Out-Null
                    $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
                    if ($DryRun) { Write-Host 'Writing to log file: '$LogFileName'...' }
                    try {
                        Add-Content -Path $LogFileName -Value "$DateTime$Delim$Info"
                    } catch [System.IO.IOException] {
                        Write-Host "Error writing $DateTime$Delim$Info to log: $LogFileName"
                    } catch {
                        Write-Host "An unknown error occurred writing $DateTime$Delim$Info to log: $LogFileName"
                        Write-Host $_.ScriptStackTrace
                    }
                    $mutex.ReleaseMutex() | Out-Null
                }
            }
            ProcessFileAndHashToLog -LogFileName $LogFileName -FileColl $filesInBatch -VerifyOnly $VerifyOnly -Delim $Delim -Header $Header -ForceOverwrite $ForceOverwrite
    }

    $i = 0
    $j = $filesPerBatch - 1
    $batch = 1
    # $LogName = ""

    Write-Host 'Creating File Copy jobs...'
    if (-not ($DryRun)) {
        $jobs = while ($i -lt $files.Count) {
            $fileBatch = $files[$i..$j]
            $LogName = createLog -ThisLog "" -FileListPath $FileList -JobNum $batch ([Ref]$LogDirectory) ([Ref]$LognameBaseName)
            Add-Content -Path $LogName -Value $FormattedHeaders #"[INFO]$Delim[SrcFilename]$Delim[SrcHash]$Delim[DestFilename]$Delim[DestHash]$Delim[Error]$Delim[ErrorDestination]$Delim[CDocID]$Delim[CVersion]$Delim[CIdentifier]$Delim[LatestRevisionNo]"
            Start-ThreadJob -Name $jobName -ArgumentList $fileBatch, $LogName, $VerifyOnly, $Delim, $Header -ScriptBlock $scriptBlock  -ThrottleLimit $NumConcurrentJobs

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
        $LogName = createLog -ThisLog $LogName -FileListPath $FileList -JobNum $batch ([Ref]$LogDirectory) ([Ref]$LognameBaseName)
        Add-Content -Path $LogName -Value $FormattedHeaders #"[INFO]$Delim[SrcFilename]$Delim[SrcHash]$Delim[DestFilename]$Delim[DestHash]$Delim[Error]$Delim[ErrorDestination]$Delim[CDocID]$Delim[CVersion]$Delim[CIdentifier]$Delim[LatestRevisionNo]"
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
    Write-Host "Converting Concatenated log to Excel, because who doesn't LOVE trawling through many thousands of rows of Excel cells!"
    Import-Csv -Delimiter $Delim -Path $ConcatenatedLog | export-excel -path "$LogDirectory\$LognameBaseName-hashed.xlsx"
} else {
    Write-Host 'Skipped file copy step as requested'
}
Write-Host 'Re-enabling Windows Defender Setting(s) if we modified them'
if (-not ((Get-MpPreference | Format-List DisableRealtimeMonitoring) -eq 0)) {
    Set-MpPreference -DisableRealtimeMonitoring 0
}
Write-host 'Re-enabling Windows Search Service if we disabled it'
$SearchService | Set-Service -StartupType Automatic
$SearchService | Start-Service

Write-Host "Total time lapsed: $([datetime]::UtcNow - $dtStart)"