$SQLInstance = "localhost\SQLEXPRESS"
$DBName = "Conisio_013"
# article suggests getting the date like this: 
# '$Date = Get-Date -format yyyy-MM-dd'
# which is fine if today's date was used.
# what actually works however is this:
$Date = "2019-05-21"
# working shared folder path:
$SharedFolder = "C:\Temp"
# -autorelocatefile is added to the following because the backup was made in a "non-standard" file path based on the customer's SQL Server installation such as this: "C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\DATA\LogName.LDF"
Restore-SqlDatabase -serverinstance $SQLInstance -Database "$DbName" -RestoreAction Database -BackupFile "$($SharedFolder)\013_12-06-2019.bak" -verbose -autorelocatefile