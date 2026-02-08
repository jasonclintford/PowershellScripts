#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Hosts,
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $true)][string[]]$Commands,
    [Parameter()][ValidateRange(1, 200)][int]$Concurrency = 20,
    [Parameter()][string]$KeyPath = ""
)

Write-Host "AUTHORIZED USE ONLY - Remote command fanout."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "ssh"

$results = Invoke-Parallel -InputObject $Hosts -ThrottleLimit $Concurrency -ScriptBlock {
    param($host)
    $sessionOptions = @{ HostName = $host; UserName = $using:User }
    if ($using:KeyPath) { $sessionOptions.KeyFilePath = $using:KeyPath }
    $hostResults = @()
    foreach ($cmd in $using:Commands) {
        try {
            $output = Invoke-Command @sessionOptions -ScriptBlock { param($c) bash -c $c } -ArgumentList $cmd -ErrorAction Stop
            $hostResults += [ordered]@{ command = $cmd; stdout = $output; stderr = $null; exitCode = 0 }
        } catch {
            $hostResults += [ordered]@{ command = $cmd; stdout = $null; stderr = $_.Exception.Message; exitCode = 1 }
        }
    }
    [ordered]@{ host = $host; results = $hostResults }
}

Export-Results -Data $results -Path "out/remote_fanout.json" -Format json
