Get-ChildItem -Path d:\ -Recurse |`
ForEach-Object{
    if (!($_.PSIsContainer)) {
$Item = $_
$Type = $_.Extension
$Path = $_.FullName
$Folder = $_.PSIsContainer
$Age = $_.CreationTime

$Path | Select-Object `
    @{n="Name";e={$Item}},`
    @{n="Created";e={$Age}},`
    @{n="destfilename";e={$Path}},`
    @{n="Extension";e={if($Folder){"Folder"}else{$Type}}}`
}}| convertto-csv -NoTypeInformation -Delimiter '|' | ForEach-Object { $_ -replace '"', ""} | out-file d:\results.csv -Force -Encoding UTF8