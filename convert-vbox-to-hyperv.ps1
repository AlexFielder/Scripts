$vboxDisk = Resolve-Path ".\output-virtualbox-iso\*.vmdk"
$hyperVDir = ".\hyper-v-output\Virtual Hard Disks"
$hyperVDisk = Join-Path $hyperVDir 'disk.vhd'
$vbox = "$env:programfiles\oracle\VirtualBox\VBoxManage.exe"
.$vbox clonehd $vboxDisk $hyperVDisk --format vhd