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
    .PARAMETER FileList
        Default is "" and only used if you have a list of files to create
    .PARAMETER NumConcurrentJobs
        default is 25 (but can be 100 if you want to stress the machine to maximum!)
    .PARAMETER FilesPerBatch
        default is 1000 this can be tweaked if performance becomes an issue because the Threading will HAMMER any network you run it on.
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
    [String] $FileList = "",
    [int] $NumConcurrentJobs =25,
    [int] $FilesPerBatch = 1000
) 

[int] $fileCount = 0

#create and start a stopwatch object to measure how long it all takes.
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
if ($FileList -eq "") {
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
    Pop-Location
} else {
    Write-host "Writing provided file: $FileList using Start-ThreadJob to create $NumConcurrentJobs Jobs"
    Write-Host 'Loading CSV data into memory...'
    $files = Import-Csv -path $FileList | Select-Object SrcFileName
    # write-host 'Creating '+$files.Length+' files'
    $scriptBlockBatchFiles = {
        param(
            [PSCustomObject]$filesInBatch,
            [String]$LogFilename,
            [int64]$minfilesize,
            [int64]$maxfilesize
        )

        function CreateBatchOfFiles {
            param([String]$LogFilename, [PSCustomObject]$FileColl, [int64]$minfilesize, [int64]$maxfilesize)
            foreach ($f in $fileColl) {
                $mutex = New-object -typename 'Threading.Mutex' -ArgumentList $false, 'MyInterProcMutex'
                $mutex.WaitOne() | Out-Null
                [System.IO.Fileinfo]$DestinationFilePath = $f.SrcFileName
                [String]$SourceDir = $DestinationFilePath.DirectoryName
                try {
                    if(!(test-path "$SourceDir")){
                        New-Item -ItemType Directory -Path "$SourceDir" | Out-Null
                    }
                    $path = $f.SrcFileName
                } catch {
                    $message = "failed create folder @ $SourceDir, error $($_.Exception.Message)" 
                    Throw $message
                }
                $filesize = Get-Random -Minimum $minfilesize -Maximum ($minfilesize * 2)
                $data = new-object byte[] $filesize
                (new-object Random).NextBytes($data)
                try {
                    if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($path)))) {
                        [IO.File]::WriteAllBytes([Management.Automation.WildcardPattern]::Escape($path), $data) | Out-Null
                    }
                } catch {
                    $message = "failed to write data to $path, error $($_.Exception.Message)" 
                    Throw $message
                }
                $mutex.ReleaseMutex() | Out-Null
            }
        }

        CreateBatchOfFiles -LogFileName $LogFileName -FileColl $filesInBatch -minfilesize $minfilesize -maxfilesize $maxfilesize

    }

    $i = 0
    $j = $FilesPerBatch - 1
    $batch = 1

    $LogName = ""

    Write-host 'Creating jobs for file creation...'
    $jobs = while ($i -lt $files.Count) {
        $fileBatch = $files[$i..$j]
        #Could add logging here, but do we really need it?
        $jobName = "FileCreate$batch"
        Start-ThreadJob -Name $jobName -ArgumentList $fileBatch, $LogName, $minfilesize, $maxfilesize -ScriptBlock $scriptBlockBatchFiles  -ThrottleLimit $NumConcurrentJobs
        $batch = $batch + 1
        $i = $j + 1
        $j += $filesPerBatch
        if ($i -gt $files.Count) {$i = $files.Count}
        if ($j -gt $files.Count) {$j = $files.Count}
    }
    Write-Host "Waiting for $($jobs.Count) jobs to complete..."
    Receive-Job -Job $jobs -Wait -AutoRemoveJob
    # ForEach ($f in $files) {
    #     [System.IO.Fileinfo]$DestinationFilePath = $f.SrcFileName
    #     [String]$SourceDir = $DestinationFilePath.DirectoryName
    #     try {
    #         if(!(test-path "$SourceDir")){
    #             New-Item -ItemType Directory -Path "$SourceDir"
    #         }
    #         $path = $f.SrcFileName
    #     } catch {
    #         $message = "failed create folder @ $SourceDir, error $($_.Exception.Message)" 
    #         Throw $message
    #     }
    #     $filesize = Get-Random -Minimum $minfilesize -Maximum ($minfilesize * 2)
    #     $data = new-object byte[] $filesize
    #     (new-object Random).NextBytes($data)
    #     try {
    #         if (-not (Test-path([Management.Automation.WildcardPattern]::Escape($path)))) {
    #             [IO.File]::WriteAllBytes([Management.Automation.WildcardPattern]::Escape($path), $data)
    #         }
    #     } catch {
    #         $message = "failed to write data to $path, error $($_.Exception.Message)" 
    #         Throw $message
    #     }
    # }
}


# how long did it all take?
$stopwatch.stop()
$stopwatch
Write-Output "Total new fileCount = " + $files.Count
