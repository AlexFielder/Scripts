Function ExportChocoInstaller($file)
{
	Write-Output $file
	choco list -lo -r -y | ForEach-Object { "choco install " + $_.Replace("|", " -version ") + " -y" } > $file
}

if ($args.Length -eq 0)
{
	Write-Output "Usage: ExportChocoInstaller <directory>"
}
else
{
	ExportChocoInstaller($args[0])
}

