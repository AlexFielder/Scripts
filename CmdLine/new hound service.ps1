$serviceName = "Hound"

if (Get-Service $serviceName -ErrorAction SilentlyContinue)
{
    remove-service -name $serviceName
}
else
{
    "service does not exists"
}

"installing service"

$secpasswd = ConvertTo-SecureString "PenJournalPhoto0" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential (".\$env:UserName", $secpasswd)
$binaryPath = "$ENV:UserProfile\go\bin\runHoundd.exe"
New-Service -name $serviceName -binaryPathName $binaryPath -displayName $serviceName -startupType Automatic -credential $mycreds -description "This service runs the hound code searching service"

"installation completed"