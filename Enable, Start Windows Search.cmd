wmic service where "caption like 'Windows Search' and Startmode='Disabled'" call ChangeStartmode Automatic
wmic service where "caption like 'Windows Search'" call Startservice
