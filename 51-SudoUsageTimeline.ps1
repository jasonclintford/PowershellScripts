#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$AuthLogPath = "/var/log/auth.log",
    [Parameter()][string]$Since = "",
    [Parameter()][string]$Until = ""
)

Write-Host "AUTHORIZED USE ONLY - Sudo timeline."
Import-Module "./00-CommonFunctions.psm1" -Force

if (-not (Test-Path $AuthLogPath)) { throw "Auth log not found: $AuthLogPath" }
$sinceDate = $Since ? (Get-Date $Since) : $null
$untilDate = $Until ? (Get-Date $Until) : $null

$events = @()
Get-Content $AuthLogPath | Select-String -Pattern "sudo:" | ForEach-Object {
    $line = $_.Line
    $timestamp = $line.Substring(0, 15)
    $parsed = Get-Date $timestamp -ErrorAction SilentlyContinue
    if ($sinceDate -and $parsed -lt $sinceDate) { return }
    if ($untilDate -and $parsed -gt $untilDate) { return }
    if ($line -match "sudo: (\S+) : TTY=(\S+) ; PWD=(\S+) ; USER=(\S+) ; COMMAND=(.+)$") {
        $events += [ordered]@{
            time = $parsed
            invokingUser = $Matches[1]
            tty = $Matches[2]
            targetUser = $Matches[4]
            command = $Matches[5]
        }
    }
}

Export-Results -Data $events -Path "out/sudo_timeline.json" -Format json
Export-Results -Data $events -Path "out/sudo_timeline.csv" -Format csv
