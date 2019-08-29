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
.PARAMETER LogName
default is output.csv located in the same path as the Filelist
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
    [String] $LogName
) 

$filesPerBatch = 100

$files = Import-Csv $FileList | Select-Object SrcFileName, DestFileName

$i = 0
$j = $filesPerBatch - 1
$batch = 1

Write-Host 'Creating jobs...'
$dtStart = [datetime]::UtcNow

$jobs = while ($i -lt $files.Count) {
    $fileBatch = $files[$i..$j]

    $jobName = "Batch$batch"
    Start-ThreadJob -Name $jobName -ThrottleLimit $NumCopyThreads -ArgumentList (,$fileBatch) -ScriptBlock {
        param($filesInBatch)
        foreach ($f in $filesInBatch) {
            [System.IO.Fileinfo]$DestinationFilePath = $f.DestFileName
            [String]$DestinationDir = $DestinationFilePath.DirectoryName
            if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
                new-item -Path $DestinationDir -ItemType Directory -Verbose
            }
            copy-item -path $f.srcFileName -Destination $f.DestFileName -Verbose
        }
    } 

    $batch += 1
    $i = $j + 1
    $j += $filesPerBatch

    if ($i -gt $files.Count) {$i = $files.Count}
    if ($j -gt $files.Count) {$j = $files.Count}
}

Write-Host "Waiting for $($jobs.Count) jobs to complete..."

Receive-Job -Job $jobs -Wait -AutoRemoveJob
Write-Host "Total time lapsed: $([datetime]::UtcNow - $dtStart)"