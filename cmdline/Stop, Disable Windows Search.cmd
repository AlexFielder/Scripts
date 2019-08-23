wmic service where "caption like 'Windows Search'" call Stopservice
wmic service where "caption like 'Windows Search' and  Startmode<>'Disabled'" call ChangeStartmode Disabled