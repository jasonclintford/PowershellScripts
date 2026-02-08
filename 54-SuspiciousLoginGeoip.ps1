#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AuthFailuresJson,
    [Parameter()][string]$GeoIpDbPath = "",
    [Parameter()][string[]]$KnownCountries = @()
)

Write-Host "AUTHORIZED USE ONLY - GeoIP enrichment."
Import-Module "./00-CommonFunctions.psm1" -Force

if (-not (Test-Path $AuthFailuresJson)) { throw "Auth failure JSON not found: $AuthFailuresJson" }
$auth = Get-Content $AuthFailuresJson | ConvertFrom-Json

$enrichmentAvailable = $GeoIpDbPath -and (Test-Path $GeoIpDbPath)
$results = foreach ($entry in $auth.offendersByIp) {
    $country = $null
    $flagged = $false
    if ($enrichmentAvailable) {
        $country = "Unknown"
        if ($KnownCountries.Count -gt 0 -and $country -notin $KnownCountries) { $flagged = $true }
    }
    [ordered]@{ ip = $entry.ip; count = $entry.count; country = $country; flagged = $flagged }
}

$result = [ordered]@{
    enrichmentUnavailable = -not $enrichmentAvailable
    results = $results
}

Export-Results -Data $result -Path "out/auth_geo_enriched.json" -Format json
