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
    [int] $NumCopyThreads = 8,
    [String] $LogName
) 

# $stopwatch = [Diagnostics.Stopwatch]::StartNew()

$filesToCopy = New-Object "System.Collections.Generic.List[PSCustomObject]"
$csv = Import-Csv $FileList

foreach($item in $csv)
{
    $fileToCopy = [PSCustomObject]@{
        SrcFileName = $item.SrcFileName
        DestFileName = $item.DestFileName
    }
    $filesToCopy.add($fileToCopy)
}

# [int32]$FileCount = 0

function copyFileInfo ([PSCustomObject]$file) {
    [System.IO.FileInfo]$CopyFile = $file.SrcFileName
    if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($file.DestFileName)))) {
        $CopyFile.CopyTo($file.DestFileName, $true)
    }
}

function isDivisible([int32]$numfiles, [int32]$divisor) {
    if ($numfiles % $divisor -eq 0) {
        return $true
    }
    else {
        return $false
    }
}

$filesPerBatch = 1000

$files = Import-Csv $FileList | Select-Object SrcFileName, DestFileName

$i = 0
$j = $filesPerBatch - 1
$batch = 1

Write-Host 'Creating jobs...'
$dtStart = [datetime]::UtcNow

$jobs = while ($i -lt $files.Count) {
    $fileBatch = $files[$i..$j]

    $jobName = "Batch$batch"
    Start-ThreadJob -Name $jobName -ThrottleLimit $NumCopyThreads -ScriptBlock {
        param($files)
        foreach ($file in $filesInBatch) {
            [System.IO.Fileinfo]$DestinationFilePath = $file.DestFileName
            [String]$DestinationDir = $DestinationFilePath.DirectoryName
            if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
                new-item -Path $DestinationDir -ItemType Directory #-Verbose
            }
            copy-item -path $file.srcFileName -Destination $file.destFilename
        }
    } -ArgumentList ($fileBatch)

    $batch += 1
    $i = $j + 1
    $j += $filesPerBatch

    if ($i -gt $files.Count) {$i = $files.Count}
    if ($j -gt $files.Count) {$j = $files.Count}
}

Write-Host "Waiting for $($jobs.Count) jobs to complete..."

Receive-Job -Job $jobs -Wait -AutoRemoveJob
Write-Host "Total time lapsed: $([datetime]::UtcNow - $dtStart)"

# Clean up the temp. file
Remove-Item $FileList

<# This works but is INCREDIBLY SLOW because it creates a thread per file
# Create sample CSV file with 10 rows.
# $FileList = Join-Path ([IO.Path]::GetTempPath()) "tmp.$PID.csv"
# @'
# Foo,SrcFileName,DestFileName,Bar
# 1,c:\tmp\a,\\server\share\a,baz
# 2,c:\tmp\b,\\server\share\b,baz
# 3,c:\tmp\c,\\server\share\c,baz
# 4,c:\tmp\d,\\server\share\d,baz
# 5,c:\tmp\e,\\server\share\e,baz
# 6,c:\tmp\f,\\server\share\f,baz
# 7,c:\tmp\g,\\server\share\g,baz
# 8,c:\tmp\h,\\server\share\h,baz
# 9,c:\tmp\i,\\server\share\i,baz
# 10,c:\tmp\j,\\server\share\j,baz
# '@ | Set-Content $FileList

# How many threads at most to run concurrently.
# $NumCopyThreads = 8

Write-Host 'Creating jobs...'
$dtStart = [datetime]::UtcNow

# Import the CSV data and transform it to [pscustomobject] instances
# with only .SrcFileName and .DestFileName properties - they take
# the place of your original [fileToCopy] instances.
$jobs = Import-Csv $FileList | Select-Object SrcFileName, DestFileName | 
  ForEach-Object {
    # Start the thread job for the file pair at hand.
    Start-ThreadJob -ThrottleLimit $NumCopyThreads -ArgumentList $_ { 
        param($f) 
        [System.IO.Fileinfo]$DestinationFilePath = $f.DestFileName
        [String]$DestinationDir = $DestinationFilePath.DirectoryName
        if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
            new-item -Path $DestinationDir -ItemType Directory #-Verbose
        }
        copy-item -path $f.srcFileName -Destination $f.destFilename
        "Copied $($f.SrcFileName) to $($f.DestFileName)"
    }
  }

Write-Host "Waiting for $($jobs.Count) jobs to complete..."

# Synchronously wait for all jobs (threads) to finish and output their results
# *as they become available*, then remove the jobs.
# NOTE: Output will typically NOT be in input order.
Receive-Job -Job $jobs -Wait -AutoRemoveJob
Write-Host "Total time lapsed: $([datetime]::UtcNow - $dtStart)"

# Clean up the temp. file
Remove-Item $FileList
#>

<# works but can be runspaced? #>
# if($CopyMethod -eq "sync") {
#     foreach ($file in $files){ #ToCopy) {
#         $FileCount += 1
#         copyFileInfo($file)
#         <# would probably work if we weren't using a workflow #>
#         if (isDivisible($FileCount, 1000) -eq $true) {
#             write-host "Number of files: " + $FileCount
#         }
#     }
# }
<# Runspaces version #>
# if ($CopyMethod -eq "Runspace") {
    # $Runspacepool = [runspacefactory]::CreateRunspacePool(1,$NumCopyThreads)
    # $Runspacepool.Open()

    # $Runspaces = foreach ($file in $filesToCopy) {
    #     $PSInstance = [powershell]::Create().AddScript({
    #         param($destFilename, $srcFileName)
    #         [System.IO.Fileinfo]$DestinationFilePath = $DestFileName
    #         [String]$DestinationDir = $DestinationFilePath.DirectoryName
    #         if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
    #             new-item -Path $DestinationDir -ItemType Directory #-Verbose
    #         }
    #         # [System.IO.FileInfo]$CopyFile = $srcFileName
    #         if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($destFileName)))) {
    #             copy-item -path $srcFileName -Destination $destFilename
    #             # $CopyFile.CopyTo($destFileName, $true)
    #         }
    #     }).AddParameter('srcFileName', $file.SrcFileName).
    #     AddParameter('destFileName', $file.DestFileName)
    #     #Adding Powershell instance to RunspacePool
    #     $PSInstance.RunspacePool = $Runspacepool

    #     New-Object psobject -Property @{
    #         instance = $PSInstance
    #         IAResult = $PSInstance.BeginInvoke()
    #         Argument = $file
    #     }
    # }

    # while($Runspaces |Where-Object{-not $_.IAResult.IsCompleted}) {
    #     Start-Sleep -Milliseconds 5
    # }

    # $Results = $Runspaces | ForEach-Object {
    #     $Output = $_.Instance.EndInvoke($_.IAResult)
    #     New-Object psobject -Property @{
    #         File = $file
    #         FileCopied = $Output
    #     }
    # }

    # $Results | Format-Table
    <#Excel report#>
    # $xlfile = "$env:Temp\testData.xlsx"
    # $Results | Export-Excel $xlfile -WorkSheetname Exported -AutoSize -TableName Report -StartRow 2 -Show
    # Close-ExcelPackage $excel -Show
# }

# $stopwatch.stop()

# # show what we did.
# [pscustomobject] @{
#     csv_output = $OutputCsv
#     total_files = $FileCount
#     time_taken = $stopwatch.elapsed
# }