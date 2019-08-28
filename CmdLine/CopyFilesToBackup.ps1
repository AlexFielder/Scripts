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

$stopwatch = [Diagnostics.Stopwatch]::StartNew()

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

[int32]$FileCount = 0

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
    $Runspacepool = [runspacefactory]::CreateRunspacePool(1,$NumCopyThreads)
    $Runspacepool.Open()

    $Runspaces = foreach ($file in $filesToCopy) {
        $PSInstance = [powershell]::Create().AddScript({
            param($destFilename, $srcFileName)
            [System.IO.Fileinfo]$DestinationFilePath = $DestFileName
            [String]$DestinationDir = $DestinationFilePath.DirectoryName
            if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($DestinationDir)))) {
                new-item -Path $DestinationDir -ItemType Directory #-Verbose
            }
            # [System.IO.FileInfo]$CopyFile = $srcFileName
            if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($destFileName)))) {
                copy-item -path $srcFileName -Destination $destFilename
                # $CopyFile.CopyTo($destFileName, $true)
            }
        }).AddParameter('srcFileName', $file.SrcFileName).
        AddParameter('destFileName', $file.DestFileName)
        #Adding Powershell instance to RunspacePool
        $PSInstance.RunspacePool = $Runspacepool

        New-Object psobject -Property @{
            instance = $PSInstance
            IAResult = $PSInstance.BeginInvoke()
            Argument = $file
        }
    }

    while($Runspaces |Where-Object{-not $_.IAResult.IsCompleted}) {
        Start-Sleep -Milliseconds 5
    }

    $Results = $Runspaces | ForEach-Object {
        $Output = $_.Instance.EndInvoke($_.IAResult)
        New-Object psobject -Property @{
            File = $file
            FileCopied = $Output
        }
    }

    $Results | Format-Table
    <#Excel report#>
    # $xlfile = "$env:Temp\testData.xlsx"
    # $Results | Export-Excel $xlfile -WorkSheetname Exported -AutoSize -TableName Report -StartRow 2 -Show
    # Close-ExcelPackage $excel -Show
# }

$stopwatch.stop()

# show what we did.
[pscustomobject] @{
    csv_output = $OutputCsv
    total_files = $FileCount
    time_taken = $stopwatch.elapsed
}