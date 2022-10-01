#Install SDK "C:\Program Files\Autodesk\Vault Professional 2021\SDK\setup.exe"
#Copy the DLL AdskLicensingSDK_3.dll into C:\Windows\System32\WindowsPowerShell\v1.0 (variable $PSHOME) to avoid license exception.
Write-Host "copying to $($PSHOME)"
Copy-Item "C:\Program Files\Autodesk\Autodesk Vault 2020 SDK\bin\x64\AdskLicensingSDK_2.dll" -Destination $PSHOME
# [System.Reflection.Assembly]::LoadFrom("C:\Program Files\Autodesk\Autodesk Vault 2020 SDK\bin\x64\Autodesk.Connectivity.WebServices.dll")
[System.Reflection.Assembly]::LoadFrom("C:\Program Files\Autodesk\Autodesk Vault 2020 SDK\bin\x64\Autodesk.DataManagement.Client.Framework.dll")
[System.Reflection.Assembly]::LoadFrom("C:\Program Files\Autodesk\Autodesk Vault 2020 SDK\bin\x64\Autodesk.DataManagement.Client.Framework.Vault.dll")

#	Vault Server Name :
$server="localhost"
#	Vault Database :
$vaultName="vault01"
#	Vault UserName :
$username ="Administrator"
#	Vault password :
$passw = ""
#	Read-only license or not :?
$readonly = $true

$vault = New-Object Autodesk.DataManagement.Client.Framework.Vault
# $mServer = New-Object Autodesk.Connectivity.WebServices.ServerIdentities
# $mServer.DataServer = $server
# $mServer.FileServer = $server

#new in 2019 API: licensing agent enum "Client" "Server" or "None" (=readonly access). 2017 and 2018 required local client installed and licensed
# $licenseAgent = [Autodesk.Connectivity.WebServices.LicensingAgent]::None

# $cred = New-Object Autodesk.Connectivity.WebServicesTools.UserPasswordCredentials($serverID, $VaultName, $UserName, $password, $licenseAgent)
# $login = New-Object -type Autodesk.Connectivity.WebservicesTools.UserPasswordCredentials($mServer.DataServer,$vaultName,$username,$passw,$licenseAgent)
# $vault = New-Object -type Autodesk.Connectivity.WebServicesTools.WebServiceManager($login)
$authFlags = new-object Autodesk.DataManagement.Client.Framework.Vault.Currency.Connections.AuthenticationFlags
$results = New-Object $vault.Library.ConnectionManager.Login($server, $vaultName, $username, $passw, $authflags::None, $null)

[Vault.Currency.Connections.Connection] $Conn = $null
if ($results.Success)
{
    $Conn = $Results.Connection
    #Samples to test if it's ok (get all Vault Users and send back the first founded user)
    $adminSvc = $Conn.AdminService
    $allUsers = $adminSvc.GetAllUsers()
    $firstuser = $allUsers[1].Name
    Write-Output $firstuser 
}


