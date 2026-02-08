#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][ValidateRange(1, 365)][int]$RecentDays = 7,
    [Parameter()][switch]$IncludeUserHomes = $true
)

Write-Host "AUTHORIZED USE ONLY - Persistence hunt."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "find"

$recentCutoff = (Get-Date).AddDays(-$RecentDays)
$findings = [ordered]@{}

$cronPaths = @("/etc/cron.d", "/etc/cron.daily", "/etc/cron.weekly", "/etc/cron.monthly")
$findings.cron = @()
foreach ($path in $cronPaths) {
    if (Test-Path $path) {
        $findings.cron += Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $recentCutoff } | Select-Object -ExpandProperty FullName
    }
}

$findings.systemd = @()
$unitFiles = @("/etc/systemd/system", "/lib/systemd/system")
foreach ($path in $unitFiles) {
    if (Test-Path $path) {
        $findings.systemd += Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $recentCutoff } | Select-Object -ExpandProperty FullName
    }
}

$findings.profiles = @()
$profileFiles = @("/etc/profile", "/etc/profile.d", "/etc/bash.bashrc")
foreach ($path in $profileFiles) {
    if (Test-Path $path) {
        $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
        $findings.profiles += $items | Where-Object { $_.LastWriteTime -gt $recentCutoff } | Select-Object -ExpandProperty FullName
    }
}

$findings.sshKeys = @()
if ($IncludeUserHomes) {
    $homes = Get-Content /etc/passwd | ForEach-Object { ($_ -split ":")[5] } | Where-Object { $_ -and (Test-Path $_) }
    foreach ($home in $homes) {
        $sshDir = Join-Path $home ".ssh"
        if (Test-Path $sshDir) {
            $findings.sshKeys += Get-ChildItem -Path $sshDir -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $recentCutoff } | Select-Object -ExpandProperty FullName
        }
    }
}

Export-Results -Data $findings -Path "out/persistence_findings.json" -Format json
