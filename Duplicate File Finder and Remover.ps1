<# 
.SYNOPSIS 
  Finds and removes file duplicates 
 
.DESCRIPTION 
  Single ps.1 to find and delete file duplicates in a selected folder 
 
 
.INPUTS 
 None 
 
.OUTPUTS 
  Gridview 
 
.NOTES 
  Version:        1.0 
  Author:        Winston McMiller 
  Creation Date:  October 13, 2016 
  Purpose/Change: Initial script development 
   
#> 
 
 
Function Get-FolderName 
{ 
Add-Type -AssemblyName System.Windows.Forms 
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog 
[void]$FolderBrowser.ShowDialog() 
$FolderBrowser.SelectedPath 
} 
 
 
##Set your path 
 
$mypath = Get-FolderName 
 
##Remove unique record by size (different size = different hash) 
$RUBySize = Get-ChildItem -path $mypath -Recurse -Include "*.jpg","*.bmp","*.jpeg","*.png","*.avi","*.mov","*.mpg","*.mpeg","*.mp4","*.mkv" | ? {( ! $_.ISPScontainer)} | Group Length | ? {$_.Count -gt 1} | Select -Expand Group | Select FullName, Length 
 
##Remove unique record by hash (generates SHA-1 hash and removes unique records) 
$RUByHash = foreach ($i in $RUBySize) {Get-FileHash -Path $i.Fullname -Algorithm SHA1} 
 
##Throw output with duplicity files 
 
#Filter empty folders and output an dialog box 
If ($RUByHash.count -eq 0) { 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")  
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  
 
$objForm = New-Object System.Windows.Forms.Form  
$objForm.Text = "No Duplicates found" 
$objForm.Size = New-Object System.Drawing.Size(300,100)  
$objForm.StartPosition = "CenterScreen" 
$objForm.KeyPreview = $True 
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")  
    {$x=$objTextBox.Text;$objForm.Close()}}) 
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")  
    {$objForm.Close()}}) 
 
$OKButton = New-Object System.Windows.Forms.Button 
$OKButton.Location = New-Object System.Drawing.Size(120,10) 
$OKButton.Size = New-Object System.Drawing.Size(40,30) 
$OKButton.Text = "OK" 
$OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()}) 
$objForm.Controls.Add($OKButton) 
 
$objForm.Topmost = $True 
$objForm.Add_Shown({$objForm.Activate()}) 
[void] $objForm.ShowDialog() 
} 
 
 
#Handle file dupicates 
If ($RUByHash.count -gt 0) { 
 
# Gather File stats 
$Title1= $RUByHash.count| Out-String 
$Savings = ($RUBySize |select -Skip 1 | Measure-Object -property length -sum).Sum 
 
#Output GridView display 
$RUByHash|Out-GridView  -Title "$Title1 Duplicate Files with a potential  savings of $Savings bytes" -PassThru 
 
#Delete or not delete duplicate files 
$RUByHash|select -Skip 1|Remove-Item -Confirm 
}