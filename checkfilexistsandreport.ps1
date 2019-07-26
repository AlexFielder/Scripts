<#
    .SYNOPSIS
        Simple cmdlet to verify files exist againts passed list
    .DESCRIPTION
        This function will write a CSV output containing three columns: Filename, FileExists, dateChecked
    .PARAMETER InputCsv
        the path to the csv file to check
    .EXAMPLE
        run from same folder as script is placed: .\checkfilexistsandreport.ps1 -inputcsv "c:\path\to\test.csv" -MaxJobs 3 -UseMutex $true

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true,
                   Position = 0)]
    [String]$InputCsv = "",
    [Parameter(Mandatory = $true,
                   Position = 1)]
    [Int32]$MaxJobs
)
Import-Module PoshRSJob;
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

[System.IO.Fileinfo]$csvfile = Get-Item -path $InputCsv
$path = $csvfile.DirectoryName
[String]$OutputCsv = $path+"\output.csv"
$baseName = "output"

$files = Get-ChildItem -Path ("{0}\{1}*" -f $path, $baseName)

if ($files) {
    "Existing log (csv) files found"
    #Create custom column by removing the F and making it a integer, so only a number is returned
    $numbers = $files | Select-Object @{Name="Number";Expression={[int]$_.BaseName.Replace($baseName, "")}}
    "Found {0} existing files" -f $files.Count
    #Take the number, sort descending, get the first value and then increment by 1
    $max = ($numbers | Sort-Object -Property Number -Descending | Select-Object -First 1 -ExpandProperty Number) + 1
    "The next number is {0}" -f $max
    #Use padding to pad zeros up to 5 characters
    $file = "output{0}.csv" -f $max.ToString().PadLeft(5,'0')
    "Incrementing {0} to generate file {1}" -f $max, $file
    $OutputCsv = $path+"\"+$file
    New-Item -Path $OutputCsv -ItemType File

}
else {
    $file = ("{0}{1}.csv" -f $baseName, "1".ToString().PadLeft(5,'0'))
    "Creating first file {0}" -f $file

    New-Item -Path $OutputCsv -ItemType File
}

if (Test-path($InputCsv))
{
    [System.IO.Fileinfo]$csvfile = Get-Item -path $InputCsv
    $csv = Import-Csv $InputCsv
    Write-output "Loading csv into memory"
    $sw = New-Object System.IO.StreamWriter($OutputCsv,$true)
    $sw.WriteLine("Filename, FileExists, DateChecked")
    [int32]$MissingFiles = 0
    [int32]$FileCount = 0
    
    $S = 1..20
    $S|Start-RSJob -Name $S -Throttle $MaxJobs -ArgumentList $OutputCsv -ScriptBlock {
        $verifyFiles = $using:csv
        foreach($fileToCheck in $verifyFiles) {
            System.Threading.Mutex $mutex = New-Object System.Threading.Mutex
            $file = New-Object -type PSObject @{
                Name = $fileToCheck
                FileExists = Test-Path($fileToCheck)
                dateChecked = (Get-Date).ToString('yyyy-MM-dd hh:mm:ss tt')
            }
            $mutex.WaitOne()#|Out-Null
            try {
                using-object (System.IO.StreamWriter $sw = new-object System.IO.StreamWriter($OutputCsv, $true)) {  
                    $sw.WriteLine($file.Name + "," + $file.FileExists + "," + $file.dateChecked)
                }
            }
            catch 
            {
                Write-Output _$.Exception.message
            }
            $mutex.ReleaseMutex()#|Out-Null
        }
    }#|Out-Null
    get-rsjob | Wait-RSJob -showprogress | Receive-RSJob
}


$stopwatch.stop()

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




