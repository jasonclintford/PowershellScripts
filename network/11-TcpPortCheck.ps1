#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Targets,
    [Parameter(Mandatory = $true)][int[]]$Ports,
    [Parameter()][ValidateRange(1, 1024)][int]$Concurrency = 200,
    [Parameter()][ValidateRange(100, 10000)][int]$TimeoutMs = 1500
)

Write-Host "AUTHORIZED USE ONLY - Authorised networks only."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$targetList = @()
if (Test-Path $Targets) {
    $targetList = Get-Content $Targets | Where-Object { $_ -and $_ -notmatch '^\s*#' }
} else {
    $targetList = $Targets.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

$inputPairs = foreach ($t in $targetList) {
    foreach ($p in $Ports) {
        [ordered]@{ target = $t; port = $p }
    }
}

$results = Invoke-Parallel -InputObject $inputPairs -ThrottleLimit $Concurrency -ScriptBlock {
    param($pair)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "filtered"
    try {
        $reply = Test-Connection -TargetName $pair.target -TcpPort $pair.port -TimeoutSeconds ([math]::Ceiling($using:TimeoutMs / 1000)) -ErrorAction SilentlyContinue
        $status = $reply ? "open" : "closed"
    } catch {
        $status = "filtered"
    }
    $stopwatch.Stop()
    [ordered]@{
        host = $pair.target
        port = $pair.port
        status = $status
        latencyMs = $stopwatch.ElapsedMilliseconds
    }
}

Export-Results -Data $results -Path "out/tcp_port_check.json" -Format json
