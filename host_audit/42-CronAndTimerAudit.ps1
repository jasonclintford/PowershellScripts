#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string[]]$CronRoots = @("/etc/cron.d", "/etc/cron.daily", "/etc/cron.weekly", "/etc/cron.monthly", "/var/spool/cron"),
    [Parameter()][ValidateRange(1, 365)][int]$RecentDays = 7
)

Write-Host "AUTHORIZED USE ONLY - Cron and timer audit."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$cronFindings = @()
$recentCutoff = (Get-Date).AddDays(-$RecentDays)
foreach ($root in $CronRoots) {
    if (-not (Test-Path $root)) { continue }
    foreach ($item in Get-ChildItem -Path $root -Recurse -Force -ErrorAction SilentlyContinue) {
        if ($item.PSIsContainer) { continue }
        $stat = & stat -c "%a %U" $item.FullName 2>$null
        $mode = $stat.Split(" ")[0]
        $owner = $stat.Split(" ")[1]
        $worldWritable = $mode.EndsWith("2") -or $mode.EndsWith("6")
        $recent = $item.LastWriteTime -gt $recentCutoff
        $cronFindings += [ordered]@{
            path = $item.FullName
            owner = $owner
            mode = $mode
            worldWritable = $worldWritable
            recent = $recent
        }
    }
}

$timers = @()
try {
    $timerOutput = & systemctl list-timers --all --no-pager 2>$null
    $timerOutput | Select-Object -Skip 1 | ForEach-Object {
        $line = $_ -replace "\s+", " "
        if ($line -match "^\s*$") { return }
        $parts = $line.Split(" ")
        if ($parts.Length -ge 5) {
            $timers += [ordered]@{ next = $parts[0] + " " + $parts[1]; last = $parts[2] + " " + $parts[3]; unit = $parts[5] }
        }
    }
} catch {
    $timers += [ordered]@{ error = $_.Exception.Message }
}

$result = [ordered]@{ cron = $cronFindings; timers = $timers }
Export-Results -Data $result -Path "out/cron_timers.json" -Format json
