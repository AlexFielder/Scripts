
Install-Module -name SQLserver

$document = [xml](Get-Content -path "C:\temp\test_backup\VaultBackup_2022_06_09_11_23_09\BackupContents.xml")

$file = "C:\temp\BackupContents.xml"

$backupContents = New-Object BackupContents

$backupContents.KnowledgeVaults = new-object System.Collections.Generic.List[Vault]

# <BackupContents BackupDate="09 June 2022 11:23:09" SchemaVersion="28.0.3" KVM="KnowledgeVaultMaster">
#   <KnowledgeVaults>
#     <Vault Name="Vault001" Filestore="C:\ProgramData\Autodesk\VaultServer\FileStore\Vault001" />
#     <Vault Name="Ibstock" Filestore="C:\ProgramData\Autodesk\VaultServer\FileStore\Ibstock" />
#     <Vault Name="Vault01" Filestore="C:\ProgramData\Autodesk\VaultServer\FileStore\Vault01" />
#   </KnowledgeVaults>
#   <KnowledgeLibraries>
#     <Library Name="My Library" />
#     <Library Name="AI2022_8020" />
#     <Library Name="AI2022_Timber" />
#     <Library Name="AI2022_Torx Screw" />
#     <Library Name="AI2022_Custom" />
#     <Library Name="AI2022_Inventor IDF" />
#     <Library Name="AI2023_My Library" />
#     <Library Name="AI2023_8020" />
#     <Library Name="AI2023_Timber" />
#     <Library Name="AI2023_Torx Screw" />
#     <Library Name="AI2023_Custom Content" />
#     <Library Name="AI2023_Inventor IDF" />
#   </KnowledgeLibraries>
#   <Products>
#     <Product Name="Autodesk.Productstream" Version="28.0.83.0" />
#     <Product Name="Autodesk.Vault" Version="28.0.83.0" />
#     <Product Name="Autodesk.VaultCollaboration" Version="28.0.83.0" />
#     <Product Name="Autodesk.VaultPro" Version="28.0.83.0" />
#   </Products>
#   <BackupState>
#     <PreStateID />
#     <PostStateID>0fca8845-a500-484c-945a-95edb2a788ab</PostStateID>
#   </BackupState>
# </BackupContents>

# class BackupContents {
#     # [XmlArray["KnowledgeVaults"], XmlArrayItem[GetType(Vault), ElementName:="Vault"]]
#     [System.Collections.Generic.List[Vault]]$KnowledgeVaults = $null
#     # [XmlArray["KnowledgeLibraries"], XmlArrayItem[GetType(Library), ElementName:="Library"]]
#     [System.Collections.Generic.List[Library]]$KnowledgeLibraries = $null
#     # [XmlArray["Products"], XmlArrayItem[GetType(Product), ElementName:="Product"]]
#     [System.Collections.Generic.List[Product]]$Products = $null
#     [XmlElement("BackupState")]
#     [BackupState]$BackupState = $null
# }
# class Vault {
#     [XmlAttribute]$Name = $null
#     [XmlAttribute]$Filestore = $null
# }
# class Library {
#     [XmlAttribute]$Name = $null
# }
# class Product {
#     [XmlAttribute]$Name = $null
#     [XmlAttribute]$Version = $null
# }