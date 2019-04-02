Function ExportChocoInstaller($file)
{
	echo $file
	choco list -lo -r -y | % { "choco install " + $_.Replace("|", " -version ") + " -y" } > $file
}

if ($args.Length -eq 0)
{
	echo "Usage: ExportChocoInstaller <directory>"
}
else
{
	ExportChocoInstaller($args[0])
}

