# Define the paths to the files
$webConfigPath = 'C:\Program Files\Autodesk\Vault Server 2024\Server\Web\Services\web.config'
$inetsrvApphostConfigPath = 'C:\Windows\System32\inetsrv\Config\applicationHost.config'
$ADMSConsoleWebConfigPath = 'C:\Program Files\Autodesk\Vault Server 2024\ADMS Console\web.config'
$VaultServerWebConfigPath = 'C:\Program Files\Autodesk\Vault Server 2024\Server\Web\Services\web.config'
$connectivityConfigPath = 'C:\Program Files\Autodesk\Vault Server 2024\ADMS Console\Connectivity.ADMSConsole.exe.Config'
$SiteConfigurationPath = 'C:\ProgramData\Autodesk\VaultServer\Configuration\SiteConfiguration.xml'
$ApplicationInfoPath = 'C:\Users\Administrator\AppData\Roaming\Autodesk\Autodesk Data Management Server Console 2024\ApplicationInfo.xml'

$ADMSConsoleLogPath = 'C:\ProgramData\Autodesk\VaultServer\FileStore\'


# Define a helper function to check a file
function Read-FileToConsole($filePath) {
    if (-not (Test-Path -Path $filePath)) {
        Write-Output "File not found: $filePath"
        return
    }

    Write-Output "File found: $filePath"

    # Check the permissions on the file
    $acl = Get-Acl -Path $filePath

    foreach ($access in $acl.Access) {
        Write-Output "Access for $($access.IdentityReference):"
        Write-Output "  Access: $($access.FileSystemRights)"
        Write-Output "  Control Type: $($access.AccessControlType)"
    }

    # Print the contents of the file
    Write-Output "File contents:"
    Get-Content -Path $filePath | Write-Output
    Write-Output "Finished reading file: $($filePath)"
}

# Get the system short date
function Get-ShortDateFormat {
    $format = (Get-Culture).DateTimeFormat.ShortDatePattern
    $format = $format -replace 'd+', '\d{1,2}'    # Day
    $format = $format -replace 'M+', '\d{1,2}'    # Month
    $format = $format -replace 'y+', '\d{2,4}'    # Year
    return "^$format"
}

# Check the web.config file
Read-FileToConsole -filePath $webConfigPath

# Check the ADMS Console web.config file
Read-FileToConsole -filePath $ADMSConsoleWebConfigPath

# Check the SiteConfiguration.xml file
Read-FileToConsole -filePath $SiteConfigurationPath

# Check the ApplicationInfo.xml file
Read-FileToConsole -filePath $ApplicationInfoPath

# Check the Vault server web.config file
Read-FileToConsole -filePath $VaultServerWebConfigPath

# Check the Connectivity.ADMSConsole.exe.Config file
Read-FileToConsole -filePath $connectivityConfigPath

# Check the inetsrv applicationhost config file
Read-FileToConsole -filePath $inetsrvApphostConfigPath

# Check the ADMS Console log path for the latest log file
$latestLog = Get-ChildItem -Path $ADMSConsoleLogPath -Filter "ADMSConsoleLog*.txt" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

if (-not $latestLog) {
    Write-Output "No log files found in $ADMSConsoleLogPath"
} else {
    Write-Output "Latest log file: $($latestLog.FullName)"

    # Read the file content
    $content = Get-Content $latestLog.FullName -Raw

    # works but requires exclusive access to any file..?
    #$count = [Linq.Enumerable]::Count([System.IO.File]::ReadLines($latestLog.FullName))

    $count = 0
    $readCount = 1000
    Get-Content -Path $latestLog.FullName -ReadCount $readCount |% { $count += $_.Count }

    # Build the regex
    $regex = (Get-ShortDateFormat) + "(.*?--->.*?--->.*$)"

    # Use Select-String to find the matches
    $Allmatches = $latestLog | Select-String -Pattern $regex -AllMatches
    # $lastmatch = $latestLog | Select-String -Pattern $regex | Select-Object -Last 1

    # Get the line number of the last match
    $lastMatchLineNumber = $Allmatches[-1].LineNumber

    # Get the count of lines after the last error
    $lineCountToEndAfterLastMatch = $count - $lastMatchLineNumber

    # Get the line number of the last match
    #$lastMatchLineNumber = $matches.Matches | Select-Object -ExpandProperty LineNumber | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    $linesAfterLastMatch = Select-String -Path $latestLog -Pattern $regex -Context 0,$lineCountToEndAfterLastMatch | Select-Object -Last 1


    # Get all lines from the last match to the end of the file
    #$linesAfterLastMatch = $latestLog[$lastMatchLineNumber..($count - 1)]
    # $linesAfterLastMatch = Select-String $content -Pattern "$($matches[-1])" -Context 0,$lineCountToEndAfterLastMatch

    # Output the lines after the last match
    # $linesAfterLastMatch

    # If a match is found, print it and all the lines after it
    if ($null -ne $linesAfterLastMatch) {
        Write-Output ($linesAfterLastMatch -replace "`r", "")
    } else {
        Write-Output "No matching error message found in the log file."
    }
}

# Check the IIS configuration
if (-not (Get-Module -ListAvailable -Name IISAdministration)) {
    Write-Output "The IISAdministration module is not available. This module is required to check the IIS configuration. installing now."
    Install-Module -Name IISAdministration -Scope CurrentUser -Force
    Import-Module -Name IISAdministration
} else {
    Import-Module -Name IISAdministration
}

# Check the state of the IIS service
$service = Get-Service W3SVC
Write-Output ("IIS Service state: " + $service.Status)

# Get and print the list of IIS sites
Get-IISSite | Format-List | Write-Output

# Get and print the IIS application pools
Get-IISAppPool | Format-List | Write-Output