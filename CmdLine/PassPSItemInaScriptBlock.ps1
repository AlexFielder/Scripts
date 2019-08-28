<#
.SYNOPSIS
Copied from this thread: https://stackoverflow.com/questions/52975186/how-to-pass-psitem-in-a-scriptblock
.DESCRIPTION
Allows the user to pass a Scriptblock into a Runspace-powered foreach loop.
.PARAMETER Scriptblock
the script we're passing in
.PARAMETER Poolsize
the number of runspaces we want to use
.PARAMETER PipelineObject
¯\_(ツ)_/¯
#>

function ForEachParallel {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)] [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory=$false)] [int] $PoolSize = 20,
        [Parameter(ValueFromPipeline)] $PipelineObject
    )

    Begin {
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $poolSize)
        $RunspacePool.Open()
        $Runspaces = @()
    }

    Process {
        $PSInstance = [powershell]::Create().
            AddCommand('Set-Variable').AddParameter('Name', '_').AddParameter('Value', $PipelineObject).
            AddCommand('Set-Variable').AddParameter('Name', 'ErrorActionPreference').AddParameter('Value', 'Stop').
            AddScript($ScriptBlock)

        $PSInstance.RunspacePool = $RunspacePool

        $Runspaces += New-Object PSObject -Property @{
            Instance = $PSInstance
            IAResult = $PSInstance.BeginInvoke()
            Argument = $PipelineObject
        }
    }

    End {
        while($True) {
            $completedRunspaces = @($Runspaces | where {$_.IAResult.IsCompleted})

            $completedRunspaces | foreach {
                Write-Output $_.Instance.EndInvoke($_.IAResult)
                $_.Instance.Dispose()
            }

            if($completedRunspaces.Count -eq $Runspaces.Count) {
                break
            }

            $Runspaces = @($Runspaces | where { $completedRunspaces -notcontains $_ })
            Start-Sleep -Milliseconds 250
        }

        $RunspacePool.Close()
        $RunspacePool.Dispose()
    }
}