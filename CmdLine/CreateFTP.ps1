#Install IIS Feature
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

#Install FTP feature
Install-WindowsFeature -Name Web-Ftp-Server -IncludeAllSubFeature -IncludeManagementTools -Verbose

#Importing Web administration module
Import-Module WebAdministration -Verbose

#Creating new FTP site
$SiteName = "Demo FTP Site"
$RootFolderpath = "C:\DemoFTPRoot"
$PortNumber = 21
$FTPUserGroupName = "Demo FTP Users Group"
$FTPUserName = "FtpUser"
$FTPPassword = ConvertTo-SecureString "p@ssw0rd" -AsPlainText -Force

#create self-signed certificate
New-SelfSignedCertificate -FriendlyName "selfsigned-localhost" -CertStoreLocation cert:\localmachine\my -DnsName localhost

if (!(Test-Path $RootFolderpath)) {
    # if the folder doesn't exist
    New-Item -Path $RootFolderpath -ItemType Directory # create the folder
}

New-WebFtpSite -Name $SiteName -PhysicalPath $RootFolderpath -Port $PortNumber -Verbose -Force 

#Creating the local Windows group
if (!(Get-LocalGroup $FTPUserGroupName  -ErrorAction SilentlyContinue)) {
    #if the group doesn't exist
    New-LocalGroup -Name $FTPUserGroupName `
        -Description "Members of this group can connect to FTP server" #create the group
}

# Creating an FTP user
If (!(Get-LocalUser $FTPUserName -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $FTPUserName -Password $FTPPassword `
        -Description "User account to access FTP server" `
        -UserMayNotChangePassword
} 

# Add the created FTP user to the group Demo FTP Users Group
Add-LocalGroupMember -Name $FTPUserGroupName -Member $FTPUserName -ErrorAction SilentlyContinue

# Enabling basic authentication on the FTP site
$param = @{
    Path    = 'IIS:\Sites\Demo FTP Site'
    Name    = 'ftpserver.security.authentication.basicauthentication.enabled'
    Value   = $true 
    Verbose = $True
}
Set-ItemProperty @param

# Adding authorization rule to allow FTP users 
# in the FTP group to access the FTP site
$param = @{
    PSPath   = 'IIS:\'
    Location = $SiteName 
    Filter   = '/system.ftpserver/security/authorization'
    Value    = @{ accesstype = 'Allow'; roles = $FTPUserGroupName; permissions = 1 } 
}

Add-WebConfiguration @param

# Changing SSL policy of the FTP site
'ftpServer.security.ssl.controlChannelPolicy', 'ftpServer.security.ssl.dataChannelPolicy' | 
ForEach-Object {
    Set-ItemProperty -Path "IIS:\Sites\Demo FTP Site" -Name $_ -Value $false
}

$ACLObject = Get-Acl -Path $RootFolderpath
$ACLObject.SetAccessRule(
    ( # Access rule object
        New-Object System.Security.AccessControl.FileSystemAccessRule(
            $FTPUserGroupName,
            'ReadAndExecute',
            'ContainerInherit,ObjectInherit',
            'None',
            'Allow'
        )
    )
)
Set-Acl -Path $RootFolderpath -AclObject $ACLObject

# Checking the NTFS permissions on the FTP root folder
Get-Acl -Path $RootFolderpath | ForEach-Object Access

# Test FTP Port and FTP access
Test-NetConnection -ComputerName localhost -Port 21

ftp localhost