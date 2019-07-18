[CmdletBinding()] 
Param( 
    [String] $InputCsv = "",
    [String] $OutputCsv = ""
)

Class fileToVerify {
    [String]$FileName
    [bool]$FileExists = $false
}
if (Test-path($InputCsv)) 
{
    $filesToCheck = New-Object "System.Collections.Generic.List[fileToVerify]"

    $csv = Import-Csv $InputCsv

    foreach($item in $csv)
    {
        $file = New-Object fileToVerify
        $file.FileName = $item.FileName
        # $file.FileExists = $false
        $filesToCheck.add($file)
    }
    # Write-Output $filesToCheck.Count
    $CheckedFiles = New-Object "System.Collections.Generic.List[fileToVerify]"
    foreach($file in $filesToCheck) {
        Write-Host $file.FileName
        if (Test-Path($file.FileName))
        {
            $file.$FileExists = $true
        }
        else {
            $file.$FileExists = $false
        }
        $CheckedFiles.add($file)
    }
    Write-Output $CheckedFiles.Count
}


