#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][switch]$IncludePackages = $true,
    [Parameter()][switch]$IncludeUsers = $true
)

Write-Host "AUTHORIZED USE ONLY - System inventory."
Import-Module "./00-CommonFunctions.psm1" -Force

$osRelease = Get-Content /etc/os-release -ErrorAction SilentlyContinue | ConvertFrom-StringData
$inventory = [ordered]@{
    os = $osRelease.NAME
    version = $osRelease.VERSION
    kernel = (& uname -r)
    cpu = (Get-Content /proc/cpuinfo | Select-String -Pattern "model name" | Select-Object -First 1).ToString()
    memoryKb = (Get-Content /proc/meminfo | Select-String -Pattern "MemTotal" | ForEach-Object { $_.ToString().Split(":")[1].Trim() })
    mounts = (& mount) -join "\n"
}

if ($IncludeUsers) {
    $inventory.users = & getent passwd | ForEach-Object { $_.Split(":")[0] }
    $inventory.groups = & getent group | ForEach-Object { $_.Split(":")[0] }
}

if ($IncludePackages) {
    $inventory.packages = & dpkg -l | Select-String -Pattern "^ii" | ForEach-Object { ($_ -split "\s+")[1] }
}

Export-Results -Data $inventory -Path "out/system_inventory.json" -Format json
