wmic service where "caption like 'WinDefend%%' and Startmode='Disabled'" call ChangeStartmode Automatic
wmic service where "caption like 'WinDefend%%'" call Startservice
