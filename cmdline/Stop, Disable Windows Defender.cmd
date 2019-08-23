wmic service where "caption like 'WinDefend%%'" call Stopservice
wmic service where "caption like 'WinDefend%%' and  Startmode<>'Disabled'" call ChangeStartmode Disabled