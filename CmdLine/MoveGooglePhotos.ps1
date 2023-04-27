get-childitem "D:\Google\drive\Other computers\My Computer\My Pictures\*" -Filter *.wmv -recurse | ForEach-Object{
    $TargetPath = $_.DirectoryName -replace ("Google","ExtractedPhotosFiles")
    If (!(Test-Path $TargetPath)) {
        mkdir $TargetPath | out-null
    }
    $_ | Move-Item -Destination $TargetPath
}