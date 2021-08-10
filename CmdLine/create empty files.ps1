 # thanks https://pio.nz/2019/02/22/210/ for the core code. 
 # found https://vmscribble.com 
 $amount = Read-Host "How many 1GB files filled of random data do you want?" 
 $folder = Read-Host "Enter the full folder path ex. c:tempjunk" 
 $file = Read-Host "Enter the file name" 
 $ext = Read-Host "Enter the file extension" Read-Host " 
 $amount $file.#.$ext files will be created in $folder Hit enter to proceed" 
 1..$amount | % { $out = new-object byte[] 1073741824; (new-object Random).NextBytes($out); [IO.File]::WriteAllBytes("$folder$file.$_.$ext", $out) }