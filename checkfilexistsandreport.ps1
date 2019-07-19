[CmdletBinding()]
param (
    [String]$InputCsv = ""
)

#create and start a stopwatch object to measure how long it all takes.
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

if (Test-path($InputCsv)) 
{
    # $CheckedFiles = New-Object "System.Collections.Generic.List[fileToVerify]"
    [System.IO.Fileinfo]$csvfile = Get-Item -path $InputCsv
    
    [String]$OutputCsv = $csvfile.DirectoryName+"\output.csv"


    # if (!(Test-Path $OutputCsv))
    # {
    #     New-Item -path $OutputCsv -type "file"
    # }
    # else {
    #     # Remove-Item -Path $OutputCsv
    #     New-Item -path $OutputCsv -type "file"
    # }
    
    $csv = Import-Csv $InputCsv
    Write-output "Loading csv into memory"
    [int32]$MissingFiles = 0
    [int32]$FileCount = 0
    foreach($item in $csv)
    {
        $file = New-Object fileToVerify
        $file.FileName = $item.FileName
        if(Test-Path($file.FileName))
        {
            $file.FileExists = "true"
        }
        else {
            $file.FileExists = "false"
            $MissingFiles += 1
        }
        $FileCount += 1
        $file.dateChecked = (Get-Date).ToString('yyyy-MM-dd hh:mm:ss tt')
        $file | Export-Csv $OutputCsv -NoTypeInformation -Append
        # $CheckedFiles.add($file)
    }
    
    # $CheckedFiles | Export-Csv $OutputCsv -NoTypeInformation
}

# how long did it all take?
$stopwatch.stop()
# $stopwatch

# show what we did.
[pscustomobject] @{
    csv_output = $OutputCsv
    total_files = $FileCount
    missing_files = $MissingFiles
    time_taken = $stopwatch.elapsed
}

Class fileToVerify {
    [String]$FileName = ""
    [String]$FileExists = "" #= "false"
    [String]$dateChecked = ""
}




