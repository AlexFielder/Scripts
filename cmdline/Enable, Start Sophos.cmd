wmic service where "caption like 'Sophos%%' and Startmode='Disabled'" call ChangeStartmode Automatic
wmic service where "caption like 'Sophos%%'" call Startservice
