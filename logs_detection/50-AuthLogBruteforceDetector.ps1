#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$AuthLogPath = "/var/log/auth.log",
    [Parameter()][ValidateRange(1, 120)][int]$WindowMinutes = 15,
    [Parameter()][ValidateRange(1, 1000)][int]$Threshold = 10
)

Write-Host "AUTHORIZED USE ONLY - Log analysis."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

if (-not (Test-Path $AuthLogPath)) {
    throw "Auth log not found: $AuthLogPath"
}

$cutoff = (Get-Date).AddMinutes(-$WindowMinutes)
$events = @()
Get-Content $AuthLogPath | Select-String -Pattern "Failed password" | ForEach-Object {
    $line = $_.Line
    $timestamp = $line.Substring(0, 15)
    $parsed = Get-Date $timestamp -ErrorAction SilentlyContinue
    if ($parsed -and $parsed -lt $cutoff) { return }
    if ($line -match "Failed password for (invalid user )?(\S+) from (\S+)") {
        $events += [ordered]@{ time = $parsed; user = $Matches[2]; ip = $Matches[3] }
    }
}

$byIp = $events | Group-Object ip | Where-Object { $_.Count -ge $Threshold } | ForEach-Object {
    [ordered]@{ ip = $_.Name; count = $_.Count }
}
$byUser = $events | Group-Object user | Where-Object { $_.Count -ge $Threshold } | ForEach-Object {
    [ordered]@{ user = $_.Name; count = $_.Count }
}

$result = [ordered]@{
    windowMinutes = $WindowMinutes
    threshold = $Threshold
    offendersByIp = $byIp
    offendersByUser = $byUser
    totalEvents = $events.Count
}

Export-Results -Data $result -Path "out/auth_bruteforce.json" -Format json
