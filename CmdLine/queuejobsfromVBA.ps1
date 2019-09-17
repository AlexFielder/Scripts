<#
.SYNOPSIS
Takes a given variable and uses a Powershell Start-ThreadJob for demonstration purposes
.DESCRIPTION
Because Excel is crap at processing multiple files at once, we should be able to queue up a number of 
jobs in batches (or perhaps one file at a time?)
.PARAMETER JobNum
The Job # 
.PARAMETER PauseDuration
#>

[CmdletBinding()]
Param(
    [String] $JobNum,
    [int] $PauseDuration = 5
)

