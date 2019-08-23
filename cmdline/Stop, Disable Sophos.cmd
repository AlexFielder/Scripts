wmic service where "caption like 'Sophos%%'" call Stopservice 
wmic service where "caption like 'Sophos%%' and  Startmode<>'Disabled'" call ChangeStartmode Disabled