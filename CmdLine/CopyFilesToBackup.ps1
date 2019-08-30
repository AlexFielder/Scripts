<#
.SYNOPSIS
<Brief description>
For examples type:
Get-Help .\<filename>.ps1 -examples
.DESCRIPTION
Copys files from one path to another
.PARAMETER FileList
e.g. C:\path\to\list\of\files\to\copy.txt
.PARAMETER NumCopyThreads
default is 8 (but can be 100 if you want to stress the machine to maximum!)
.PARAMETER FilesPerBatch
default is 1000 this can be tweaked if performance becomes an issue because the Threading will HAMMER any network you run it on.
.PARAMETER LogName
Desired log file output. Must include full or relative (.\blah) path. If blank, location of FileList is used.
.PARAMETER DryRun
Boolean value denoting whether we're testing this thing or not. (Default is $false)
.PARAMETER DryRunNum
The number of files to Dry Run. (Default is 100)
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
    [String] $FileList = "C:\temp\copytest.csv", 
    [int] $NumCopyThreads =75,
    [String] $JobName,
    [int] $FilesPerBatch = 1000,
    [String] $LogName,
    [Boolean] $DryRun = $false, #$true,
    [int] $DryRunNum = 100
) 



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

if ($LogName -eq "") {
    [System.IO.Fileinfo]$CsvPath = $FileList
    [String]$LogDirectory = $CsvPath.DirectoryName
    [string]$LognameBaseName = $CsvPath.BaseName
    $LogName = $LogDirectory + "\" + $LognameBaseName + ".log"
    if (-not (CreateFile($LogName)) ) { 
        write-host "Unable to create log, exiting now!"
        Break
    }
}
else {
    if (-not (CreateFile($LogName)) ) { 
        write-host "Unable to create log, exiting now!"
        Break
    }
}

Add-Content -Path $LogName -Value "[INFO],[Src Filename],[Src Hash],[Dest Filename],[Dest Hash]"

Write-Host 'Loading CSV data into memory...'

$files = Import-Csv $FileList | Select-Object SrcFileName, DestFileName

Write-Host 'CSV Data loaded...'

# function ProcessFileAndHashToLog {
#     param( [String]$LogFileName, [PSCustomObject]$FileColl)
#     foreach ($f in $FileColl) {
#         $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
#         [System.IO.Fileinfo]$DestinationFilePath = $f.DestFileName
#         [String]$DestinationDir = $DestinationFilePath.DirectoryName
#         if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
#             new-item -Path $DestinationDir -ItemType Directory | Out-Null #-Verbose
#         }
#         copy-item -path $f.srcFileName -Destination $f.DestFileName | Out-Null #-Verbose
        
#         $srcHash = (Get-FileHash -Path $f.srcFileName -Algorithm SHA1).Hash #| Out-Null #could also use MD5 here but it needs testing
#         if (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) {
#             $destHash = (Get-FileHash -Path $f.destFileName -Algorithm SHA1).Hash #| Out-Null #could also use MD5 here but it needs testing
#         } else {
#             $destHash = $f.destFileName + " not found at location."
#         }
#         if (-not ($null -eq $destHash) -and -not ($null -eq $srcHash)) {
#             $info = $f.srcFileName + "," + $srcHash + "," + $f.destFileName + "," + $destHash
#         }
#         $mutex.WaitOne() | Out-Null
#         $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
#         Add-Content -Path $LogFileName -Value "$DateTime,$Info"
#         $mutex.ReleaseMutex() | Out-Null
#     }
# }


$scriptBlock = {
    param(
        [PSCustomObject]$filesInBatch, 
        [String]$LogFileName)
        function ProcessFileAndHashToLog {
            param( [String]$LogFileName, [PSCustomObject]$FileColl)
            foreach ($f in $FileColl) {
                $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
                [System.IO.Fileinfo]$DestinationFilePath = $f.DestFileName
                [String]$DestinationDir = $DestinationFilePath.DirectoryName
                if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
                    new-item -Path $DestinationDir -ItemType Directory | Out-Null #-Verbose
                }
                copy-item -path $f.srcFileName -Destination $f.DestFileName | Out-Null #-Verbose
                
                $srcHash = (Get-FileHash -Path $f.srcFileName -Algorithm SHA1).Hash #| Out-Null #could also use MD5 here but it needs testing
                if (Test-path([Management.Automation.WildcardPattern]::Escape($f.destFileName))) {
                    $destHash = (Get-FileHash -Path $f.destFileName -Algorithm SHA1).Hash #| Out-Null #could also use MD5 here but it needs testing
                } else {
                    $destHash = $f.destFileName + " not found at location."
                }
                if (-not ($null -eq $destHash) -and -not ($null -eq $srcHash)) {
                    $info = $f.srcFileName + "," + $srcHash + "," + $f.destFileName + "," + $destHash
                }
                $mutex.WaitOne() | Out-Null
                $DateTime = Get-date -Format "yyyy-MM-dd HH:mm:ss:fff"
                Write-Host 'Writing to log file: '$LogFileName'...'
                Add-Content -Path $LogFileName -Value "$DateTime,$Info"
                $mutex.ReleaseMutex() | Out-Null
            }
        }
        ProcessFileAndHashToLog -LogFileName $LogFileName -FileColl $filesInBatch
}

$i = 0
$j = $filesPerBatch - 1
$batch = 1
Write-Host 'Creating jobs...'
if (-not ($DryRun)) {
    $jobs = while ($i -lt $files.Count) {
        $fileBatch = $files[$i..$j]
        Start-ThreadJob -Name $jobName -ThrottleLimit $NumCopyThreads -ArgumentList $fileBatch, $LogName -ScriptBlock $scriptBlock
        $batch += 1
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
    & $scriptBlock -filesInBatch $DummyFileBatch -LogFileName $LogName
    Write-Host 'That wasn''t so bad was it..?'
}

Write-Host "Total time lapsed: $([datetime]::UtcNow - $dtStart)"