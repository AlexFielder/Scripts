IF NOT EXIST "C:\Autodesk\AutodeskVaultRemoteContentDownload\" (
	MKDIR "C:\Autodesk\AutodeskVaultRemoteContentDownload\"
	)
cd C:\Autodesk\AutodeskVaultRemoteContentDownload\
REM curl -O https://download.autodesk.com/akn/2023/inventor_remote_content/custom.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventoransi.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventordin.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorfeature.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorgost.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventoridf.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventoriso.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorjisgb.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventormoldmetricsub.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorother.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorparker.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorroutedsystems.exe -O https://download.autodesk.com/akn/2023/inventor_remote_content/inventorsheetmetal.exe --ssl-no-revoke

curl -O https://up1.autodesk.com/2024/INVPROSA/D144AFD5-9C50-3C8D-9076-48844DAE6CFF//InventorFeature.exe -O https://up1.autodesk.com/2024/INVPROSA/4CE6D45C-40F4-34DB-B6E5-6E15D4A1AFF1//InventorANSI.exe -O https://up1.autodesk.com/2024/INVPROSA/8162A2D2-1944-3DDB-B1F2-7E3065EC4479//AI2024_Inventor_Mold_Meusburger_remote.exe -O https://up1.autodesk.com/2024/INVPROSA/29C2A19A-D13D-3B02-8473-4EC6EE1BAA00//InventorDIN.exe -O https://up1.autodesk.com/2024/INVPROSA/403BA882-52A6-3D99-8292-F0D7BE0ACB14//AI2024_Inventor_Mold_Metric_remote.exe -O https://up1.autodesk.com/2024/INVPROSA/6BB87BA0-O5E4-3346-8CB5-5E92D611B4FA//InventorOther.exe -O https://up1.autodesk.com/2024/INVPROSA/868538A5-B9FD-312F-B2D9-7DEDE59546F7//InventorISO.exe -O https://up1.autodesk.com/2024/INVPROSA/51332564-F066-3969-9B4F-8901939493DC//InventorJISGB.exe -O https://up1.autodesk.com/2024/INVPROSA/E5F13C3A-5D7E-3EE1-96FA-CB715574AF5A//AI2024_Inventor_Mold_Imperial_remote.exe -O https://up1.autodesk.com/2024/INVPROSA/7F521738-6A2B-3B10-8557-C642FBF085D9//InventorSheetMetal.exe -O https://up1.autodesk.com/2024/INVPROSA/F86D9A94-83F2-322A-9479-DD57156154BB//InventorCustom.exe -O https://up1.autodesk.com/2024/INVPROSA/D72FF535-3BD6-3290-9AAC-B3DAC09C7E95//InventorGOST.exe -O https://up1.autodesk.com/2024/INVPROSA/16A50E05-51D0-3660-8207-9D48555AEC88//InventorParker.exe -O https://up1.autodesk.com/2024/INVPROSA/D7F06F93-O654-3B5A-8BC6-392DB120B116//InventorIDF.exe -O https://up1.autodesk.com/2024/INVPROSA/34BDCB42-3F7A-3E1F-A449-7FFDA72A6DDC//InventorRoutedSystems.exe -O https://up1.autodesk.com/2024/INVPROSA/AF7E712C-D8F5-3BA1-8106-1C90DAFAE611//InventorMoldMetricSub.exe --ssl-no-revoke

REM for /r "C:\Autodesk\AutodeskVaultRemoteContentDownload\" %%a in (*.exe) do start "" "%%~fa -s -d 'C:\Autodesk\Contentlibrary2024\'"
Forfiles /p .\ /c "cmd /c @path -s^ -d^ 'C:\Autodesk\Contentlibrary2024\'"



