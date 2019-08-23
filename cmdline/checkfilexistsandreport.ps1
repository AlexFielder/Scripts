<#
    .SYNOPSIS
        Simple cmdlet to verify files exist againts passed list
    .DESCRIPTION
        This function will write a CSV output containing three columns: Filename, FileExists, dateChecked
    .PARAMETER InputCsv
        the path to the csv file to check
    .EXAMPLE
        run from same folder as script is placed: .\checkfilexistsandreport.ps1 -inputcsv "c:\path\to\test.csv"

#>

[CmdletBinding()]
param (
    [String]$InputCsv = ""
)

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

    New-Item -Path $path -Name $file -ItemType File
}

if (Test-path($InputCsv)) 
{
    [System.IO.Fileinfo]$csvfile = Get-Item -path $InputCsv
    #the -Encoding line below would work if Powershell was the same version everywhere!
    $csv = Get-Content $InputCsv # $csv = Get-Content -Encoding "utf8BOM" $InputCsv #Import-Csv $InputCsv
    Write-output "Loading csv into memory"
    $sw = New-Object System.IO.StreamWriter $OutputCsv
    $sw.WriteLine("Filename|FileExists|DateChecked")
    [int32]$MissingFiles = 0
    [int32]$FileCount = 0
    foreach($item in $csv)
    {
        $file = New-Object fileToVerify
        $file.FileName = $item
        if([System.IO.File]::Exists($file.FileName))
        {
            $file.FileExists = "true"
        }
        # if(Test-Path -LiteralPath $file.FileName)
        # {
        #     $file.FileExists = "true"
        # }
        else {
            #Escaped character test:
            Write-Debug "Testing path using alternate method because special characters"
            if(Test-path([Management.Automation.WildcardPattern]::Escape($file.FileName))) 
            {
                $file.FileExists = "true"
            }
            else 
            {
                $file.FileExists = "false"
                $MissingFiles += 1    
            }
            
        }
        $FileCount += 1
        $file.dateChecked = (Get-Date).ToString('yyyy-MM-dd hh:mm:ss tt')
        $sw.WriteLine($file.FileName + "|" + $file.FileExists + "|" + $file.dateChecked)
    }
    $sw.Close()
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




