#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string[]]$SudoersPaths = @("/etc/sudoers", "/etc/sudoers.d"),
    [Parameter()][switch]$IncludeShadowHints = $false
)

Write-Host "AUTHORIZED USE ONLY - User and sudo audit."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$users = & getent passwd | ForEach-Object {
    $parts = $_.Split(":")
    [ordered]@{ user = $parts[0]; uid = [int]$parts[2]; gid = [int]$parts[3]; home = $parts[5]; shell = $parts[6] }
}

$uidZero = $users | Where-Object { $_.uid -eq 0 -and $_.user -ne "root" }

$sudoEntries = @()
foreach ($path in $SudoersPaths) {
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue | Where-Object { $_ -and $_ -notmatch '^\s*#' }
            $sudoEntries += [ordered]@{ file = $file.FullName; entries = $lines }
        }
    }
}

$result = [ordered]@{
    uidZeroNonRoot = $uidZero
    sudoers = $sudoEntries
}

if ($IncludeShadowHints -and (Test-Path /etc/shadow)) {
    $result.shadowHints = Get-Content /etc/shadow | ForEach-Object { ($_ -split ":")[0] }
}

Export-Results -Data $result -Path "out/user_sudo_audit.json" -Format json
