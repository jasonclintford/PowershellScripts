#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Targets,
    [Parameter()][ValidateRange(1, 64)][int]$MaxHops = 30
)

Write-Host "AUTHORIZED USE ONLY - Authorised networks only."
Import-Module "./00-CommonFunctions.psm1" -Force

$targetList = @()
if (Test-Path $Targets) {
    $targetList = Get-Content $Targets | Where-Object { $_ -and $_ -notmatch '^\s*#' }
} else {
    $targetList = $Targets.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

$results = foreach ($target in $targetList) {
    $hops = @()
    try {
        $trace = Test-Connection -TargetName $target -Traceroute -MaxHops $MaxHops -ErrorAction SilentlyContinue
        foreach ($hop in $trace) {
            $hops += [ordered]@{ hop = $hop.Hop; address = $hop.Address; latencyMs = $hop.Latency }
        }
    } catch {
        $hops += [ordered]@{ hop = 0; address = "unreachable"; latencyMs = $null }
    }
    [ordered]@{ target = $target; hops = $hops }
}

Export-Results -Data $results -Path "out/traceroute_baseline.json" -Format json
