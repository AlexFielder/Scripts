function CheckFileExistsAndReport {
    [CmdletBinding()]
    param (
        [String]$InputCsv = ""
    )
    if (Test-path($InputCsv)) 
    {
        $filesToCheck = New-Object "System.Collections.Generic.List[fileToVerify]"
        [System.IO.Fileinfo]$csvfile = Get-Item -path $InputCsv
        $csv = Import-Csv $InputCsv

        foreach($item in $csv)
        {
            $file = New-Object fileToVerify
            $file.FileName = $item.FileName
            # $file.FileExists = $false
            $filesToCheck.add($file)
        }
        Write-output "files to check= "$filesToCheck.Count
        $CheckedFiles = New-Object "System.Collections.Generic.List[fileToVerify]"
        [int32]$MissingFiles = 0
        foreach($file in $filesToCheck) {
            # Write-Host $file.FileName
            # 'MapiEnabled' = If($item.MapiEnabled.Trim() -eq 'TRUE'){$True} Else{$False}
            if(Test-Path($file.FileName))
            {
                $file.FileExists = "true"
            }
            else {
                $file.FileExists = "false"
                $MissingFiles += 1
            }
            # $file.FileExists = if (Test-Path($file.FileName)) {"true"} Else {"false"}
            # if ($file.FileExists = "false") {$MissingFiles += 1}
            # if (Test-Path($file.FileName))
            # {
            #     $file.$FileExists = $true
            # }
            # else {
            #     $file.$FileExists = $false
            # }
            $CheckedFiles.add($file)
        }
        Write-output "checked files="$CheckedFiles.Count
        Write-output "missing files="$MissingFiles
        [String]$OutputCsv = $csvfile.DirectoryName+"\output.csv"

        MakeCSV($CheckedFiles, $OutputCsv)
        # Export-Csv -path $OutputCsv -Delimiter "," -InputObject $CheckedFiles -NoTypeInformation
    }
}

 
Class fileToVerify {
    [String]$FileName
    [String]$FileExists = "false"
}


Function MakeCSV($ListObjects,$namefile){
    $Listobjects | ForEach-Object{
        [fileToVerify]@{
            FileName = $_.FileName
            FileExists = $_.FileExists
        } | Export-Csv -Path "Output-$NameFile.csv" -NoTypeInformation -Append -Delimiter ","
    }
}

