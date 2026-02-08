#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][ValidateSet("auto", "ufw", "nft", "iptables")][string]$Prefer = "auto"
)

Write-Host "AUTHORIZED USE ONLY - Firewall status audit."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

function Get-UfwStatus {
    if (-not (Get-Command ufw -ErrorAction SilentlyContinue)) { return [ordered]@{ available = $false } }
    $status = & ufw status verbose 2>$null
    return [ordered]@{ available = $true; raw = $status }
}

function Get-NftStatus {
    if (-not (Get-Command nft -ErrorAction SilentlyContinue)) { return [ordered]@{ available = $false } }
    $status = & nft list ruleset 2>$null
    return [ordered]@{ available = $true; raw = $status }
}

function Get-IptablesStatus {
    if (-not (Get-Command iptables -ErrorAction SilentlyContinue)) { return [ordered]@{ available = $false } }
    $status = & iptables -S 2>$null
    return [ordered]@{ available = $true; raw = $status }
}

$result = [ordered]@{ prefer = $Prefer }
if ($Prefer -eq "ufw") { $result.ufw = Get-UfwStatus }
elseif ($Prefer -eq "nft") { $result.nft = Get-NftStatus }
elseif ($Prefer -eq "iptables") { $result.iptables = Get-IptablesStatus }
else {
    $result.ufw = Get-UfwStatus
    $result.nft = Get-NftStatus
    $result.iptables = Get-IptablesStatus
}

Export-Results -Data $result -Path "out/firewall_status.json" -Format json
