#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Hosts,
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $true)][string]$PolicyFile
)

Write-Host "AUTHORIZED USE ONLY - Remote config drift."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "ssh"

if (-not (Test-Path $PolicyFile)) { throw "Policy file not found: $PolicyFile" }
$policy = Get-Content $PolicyFile | ConvertFrom-Json

$results = foreach ($host in $Hosts) {
    $drift = @()
    $sshd = & ssh "$User@$host" "sshd -T" 2>$null
    if ($policy.sshd) {
        foreach ($key in $policy.sshd.PSObject.Properties.Name) {
            $expected = $policy.sshd.$key
            $actual = ($sshd | Select-String -Pattern "^$key\s+").ToString().Split(" ")[1]
            if ($actual -ne $expected) { $drift += [ordered]@{ area = "sshd"; key = $key; expected = $expected; actual = $actual; remediation = "Update sshd_config" } }
        }
    }
    if ($policy.firewall) {
        $ufw = & ssh "$User@$host" "ufw status" 2>$null
        if ($ufw -notmatch $policy.firewall.status) {
            $drift += [ordered]@{ area = "firewall"; key = "status"; expected = $policy.firewall.status; actual = $ufw; remediation = "Enable firewall" }
        }
    }
    if ($policy.packages) {
        foreach ($pkg in $policy.packages.PSObject.Properties.Name) {
            $min = $policy.packages.$pkg
            $version = & ssh "$User@$host" "dpkg -s $pkg | grep Version" 2>$null
            $actual = $version -replace "Version:\s+", ""
            if ($actual -and $actual -lt $min) {
                $drift += [ordered]@{ area = "package"; key = $pkg; expected = $min; actual = $actual; remediation = "Upgrade package" }
            }
        }
    }
    [ordered]@{ host = $host; drift = $drift }
}

Export-Results -Data $results -Path "out/config_drift.json" -Format json
