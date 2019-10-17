<#
    .SYNOPSIS
    (mostly) pinched from here: https://gallery.technet.microsoft.com/scriptcenter/Generate-random-binary-3e891264
    usage within vscode is done like this:
    .DESCRIPTION
        This function will generate a bunch of test files we can use for verification testing
    .PARAMETER TargetPath
        The path to write to
    .PARAMETER MinFileSize
        The smallest filesize required e.g. 1KB
    .PARAMETER MaxFileSize
        The largest filesize required e.g. 1GB
    .PARAMETER TotalSize
        The total amount of data required e.g. 10GB
    .PARAMETER TimeRangeHours
        The time in the past you want files to be "created" e.g. 24
    .PARAMETER FileNameSeed
        Default is 0123456789 but can be anything you want; except special characters
    .PARAMETER NumProjects
        Default is 50 which creates 50 project folders
    .EXAMPLE
        $topfolder = "C:\temp\CustomerName-dummy-data"
        New-Item -Path $topfolder -ItemType Directory
        & .\Generate-Random-Files.ps1 -Targetpath $topfolder -minfilesize 1KB -maxfilesize 1MB -totalsize 1GB -timerangehours 319740
        or like this:
        & .\Generate-Random-Files.ps1 -Targetpath $topfolder -minfilesize 100MB -maxfilesize 100MB -totalsize 10GB -timerangehours 0
        & .\Generate-Random-Files.ps1 -Targetpath $topfolder -minfilesize 1KB -maxfilesize 1GB -totalsize 10GB -timerangehours 24
        & .\Generate-Random-Files.ps1 -Targetpath $topfolder -minfilesize 1KB -maxfilesize 1MB -totalsize 1GB -timerangehours 48
#>

[CmdletBinding()] 
Param( 
    [String] $TargetPath = $((Get-Location).Path), 
    [int64] $minfilesize = 1KB, 
    [int64] $maxfilesize = 10MB, 
    [int64] $totalsize = 100MB, 
    [int] $timerangehours = 24, 
    [string] $filenameseed = "0123456789", #!£$%^&*¬",
    [int] $numProjects = 50,
    [String] $FileList = ""
) 

[int] $fileCount = 0

#create and start a stopwatch object to measure how long it all takes.
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

#dummy extension list
$Extlist='.dwf','.dwg','.dxf','.pdf','.docx','.xlsx','.zip','.rvt','.dog','.dgn','.txt'

#
# convert to absolute path as required by WriteAllBytes, and check existence of the directory.
#
if (-not (Split-Path -IsAbsolute $TargetPath))
{
    $TargetPath = Join-Path (Get-Location).Path $TargetPath
}
if (-not (Test-Path -Path $TargetPath -PathType Container ))
{
    throw "TargetPath '$TargetPath' does not exist or is not a directory"
}

$currentsize = [int64]0
$currentime = Get-Date
Push-Location $TargetPath
if ($FileList -eq "") {
    #$missionList = New-Object "System.Collections.Generic.List[mission]"
    $randomProjectNumList = New-Object  "System.Collections.Generic.List[string]"
    $randomProjectNum = new-Object int32
    ForEach ($number in 1..$numProjects) {
        $randomProjectNum = Get-Random -Minimum 1 -Maximum (999999 - $numProjects)
        $paddedProjectNum = ([string]($randomProjectNum)).PadLeft(4,'0')
        $randomProjectNumList.add($paddedProjectNum)
    }

    while ($currentsize -lt $totalsize)
    {
        ForEach ($projectNumber in $randomProjectNumList)
        {
            #$projectNumber = Get-Random -Minimum 0 -Maximum (9999 - $numProjects)
            #$paddedProjectNum = ([string]($number + $projectNumber)).PadLeft(4,'0')
            $newPath = "$TargetPath\$projectNumber"
            if(!(test-path "$newPath")){
                New-Item -ItemType Directory -Path "$newPath"
            }
            Set-Location -Path "$newPath"
            #
            # generate a random file size. Do the smart thing if min==max. Do not exceed the specified total size.
            #
            if ($minfilesize -lt $maxfilesize)
            {
                $filesize = Get-Random -Minimum $minfilesize -Maximum $maxfilesize
            } else {
                $filesize = $maxfilesize
            }
            if ($currentsize + $filesize -gt $totalsize) {
                $filesize = $totalsize - $currentsize
            }
            $currentsize += $filesize

            #
            # use a very fast .NET random generator
            #
            $data = new-object byte[] $filesize
            (new-object Random).NextBytes($data)

            #
            # generate a random file name by shuffling the input filename seed.
            #
            $filename = ($filenameseed.ToCharArray() | Get-Random -Count ($filenameseed.Length)) -join ''
            $Ext = Get-Random -InputObject $Extlist
            $path = Join-Path $newPath "$($projectNumber + "-" + $filename)$Ext"
            # $path = Join-Path $TargetPath "$($filename)$Ext"

            #
            # write the binary data, and randomize the timestamps as required.
            #
            try
            {
                [IO.File]::WriteAllBytes([Management.Automation.WildcardPattern]::Escape($path), $data)
                if ($timerangehours -gt 0)
                {
                    $timestamp = $currentime.AddHours(-1 * (Get-Random -Minimum 0 -Maximum $timerangehours))
                } else {
                    $timestamp = $currentime
                }
                $fileobject = Get-Item -Path $path
                $fileobject.CreationTime = $timestamp
                $fileobject.LastWriteTime = $timestamp
        
                # show what we did.
                [pscustomobject] @{
                    filename = $path
                    timestamp = $timestamp
                    datasize = $filesize
                }
                $fileCount += 1
            } catch {
                $message = "failed to write data to $path, error $($_.Exception.Message)" 
                Throw $message 
            }
        }
    }
} else {
    
}
Pop-Location

# how long did it all take?
$stopwatch.stop()
$stopwatch
Write-Output "Total new fileCount = " + $fileCount
