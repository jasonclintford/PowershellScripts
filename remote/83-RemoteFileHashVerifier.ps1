#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Hosts,
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $true)][string]$Allowlist
)

Write-Host "AUTHORIZED USE ONLY - Remote hash verification."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "ssh"

if (-not (Test-Path $Allowlist)) { throw "Allowlist not found: $Allowlist" }
$allow = Get-Content $Allowlist | ConvertFrom-Json

$results = foreach ($host in $Hosts) {
    $matches = @()
    $mismatches = @()
    $missing = @()
    $permissionDenied = @()
    foreach ($path in $allow.PSObject.Properties.Name) {
        $expected = $allow.$path
        $output = & ssh "$User@$host" "sha256sum $path" 2>&1
        if ($output -match "No such file") { $missing += $path; continue }
        if ($output -match "Permission denied") { $permissionDenied += $path; continue }
        $actual = ($output -split "\s+")[0]
        if ($actual -eq $expected) { $matches += $path } else { $mismatches += [ordered]@{ path = $path; expected = $expected; actual = $actual } }
    }
    [ordered]@{ host = $host; match = $matches; mismatch = $mismatches; missing = $missing; permissionDenied = $permissionDenied }
}

Export-Results -Data $results -Path "out/remote_hash_verify.json" -Format json
