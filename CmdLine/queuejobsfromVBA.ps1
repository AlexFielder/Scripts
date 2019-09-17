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
    [int] $NumConcurrentJobs = 25,
    [int] $PauseDuration = 5
)

$scriptBlock = {
    param(
        [int] $JobPauseDuration
    )

    function createPauseJob {
        param(
            [int] $ThisPause)
            if( -not ($ThisPause -eq 0)) {
                Start-Sleep -Seconds $ThisPause
            } else {
                write-host "No pause interval provided, exiting."
                Break
            }
    }
    createPauseJob -ThisPause $JobPauseDuration
}



if ( -not ($JobNum = "")) {
    Start-ThreadJob -Name $JobNum -ArgumentList $PauseDuration -ScriptBlock $scriptBlock  -ThrottleLimit $NumConcurrentJobs
} else {
    write-host "No pause interval provided, exiting."
    Break
}