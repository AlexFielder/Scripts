[CmdletBinding()] 
Param( 
    [String] $InputCsv = "",
    [String] $OutputCsv = ""
)

Class fileToVerify {
    [String]$FileName
    [Boolean]$FileExists
}

$filesToCheck = New-Object "System.Collections.Generic.List[fileToVerify]"

$csv = Import-Csv $InputCsv

foreach($item in $csv)
{
    $file = New-Object fileToVerify
    $file.FileName = $item.FileName
    $file.FileExists = $item.FileExists
    $filesToCheck.add($file)
}


