#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string[]]$SysctlKeys = @("kernel.kptr_restrict", "kernel.dmesg_restrict", "net.ipv4.conf.all.rp_filter", "net.ipv4.ip_forward")
)

Write-Host "AUTHORIZED USE ONLY - Kernel posture."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "lsmod"
Assert-CommandExists -Name "sysctl"

$modules = & lsmod 2>$null | Select-Object -Skip 1 | ForEach-Object { ($_ -split "\s+")[0] }
$sysctl = @{}
foreach ($key in $SysctlKeys) {
    $value = & sysctl -n $key 2>$null
    $sysctl[$key] = $value
}

$result = [ordered]@{ modules = $modules; sysctl = $sysctl }
Export-Results -Data $result -Path "out/kernel_posture.json" -Format json
