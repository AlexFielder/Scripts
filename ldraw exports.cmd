start /b "D:\Dropbox\Scripts\ldraw keys.exe"
c:
cd\
cd ldraw\parts
for /f %%i in ('dir /s /b *.dat') do ldview %%i -ExportFile=%%~nfi.stl