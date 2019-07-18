[CmdletBinding()] 
Param( 
    [String]$InputCsv = ""
)

Class fileToVerify {
    [String]$FileName
    [String]$FileExists = "false"
}
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
    Write-output "checked files= "$CheckedFiles.Count"\nmissing files="$MissingFiles
    [String]$OutputCsv = $csvfile.DirectoryName+"\output.csv"
    Export-Csv -path $OutputCsv -Delimiter "," -InputObject $CheckedFiles -NoTypeInformation
}


