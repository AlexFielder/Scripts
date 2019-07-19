


[CmdletBinding()]
param (
    [String]$InputCsv = ""
)



#create and start a stopwatch object to measure how long it all takes.
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

if (Test-path($InputCsv)) 
{
    # $CheckedFiles = New-Object "System.Collections.Generic.List[fileToVerify]"
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

    Class fileToVerify {
        [String]$FileName = ""
        [String]$FileExists = "" #= "false"
        [String]$dateChecked = ""
    }
    $csv = Import-Csv $InputCsv
    Write-output "Loading csv into memory"
    [int32]$MissingFiles = 0
    [int32]$FileCount = 0
    
    workflow DoSomeWork {
        param(
        [int]$ThrottleLimit = 5
        )
        foreach -parallel -throttle $ThrottleLimit ($item in $csv)
        {
            [int32]$x = 0
            sequence {
                $obj = New-Object -type PSObject @{
                    Name = $item.FileName
                    FileExists = Test-Path($item.FileName) ? "true" : "false"
                    dateChecked = (Get-Date).ToString('yyyy-MM-dd hh:mm:ss tt')
                }
                Write-Output $obj
                # $obj | Export-Csv -Path "C:\Temp\Results_$x.csv" -Append
                # $obj | Export-Csv $OutputCsv -Append
            }
            $x++
            # $file = New-Object -type fileToVerify
            # $file.FileName = $item.FileName
            # if(Test-Path($file.FileName))
            # {
            #     $file.FileExists = "true"
            # }
            # else {
            #     $file.FileExists = "false"
            #     $MissingFiles += 1
            # }
            # $FileCount += 1
            # $file.dateChecked = (Get-Date).ToString('yyyy-MM-dd hh:mm:ss tt')
            # $file | Export-Csv $OutputCsv -NoTypeInformation -Append
            # $CheckedFiles.add($file)
            # $workflow:ans += $obj
            
        }
        # $ans
    # $CheckedFiles | Export-Csv $OutputCsv -NoTypeInformation
    }
    # DoSomeWork | Export-Csv $OutputCsv -NoTypeInformation -Append
}
# how long did it all take?
$stopwatch.stop()
# $stopwatch

# show what we did.
[pscustomobject] @{
    csv_output = $OutputCsv
    total_files = $FileCount
    missing_files = $MissingFiles
    time_taken = $stopwatch.elapsed
}



