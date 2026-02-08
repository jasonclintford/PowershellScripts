#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$AdvisoryFeedPath,
    [Parameter()][string]$OutFile = "out/pkg_cve_matches.json"
)

Write-Host "AUTHORIZED USE ONLY - Package CVE matching."
Import-Module "./00-CommonFunctions.psm1" -Force

if (-not (Test-Path $AdvisoryFeedPath)) { throw "Advisory feed not found: $AdvisoryFeedPath" }
$feed = Get-Content $AdvisoryFeedPath | ConvertFrom-Json
$packages = & dpkg -l | Select-String -Pattern "^ii" | ForEach-Object {
    $parts = $_ -split "\s+"
    [ordered]@{ name = $parts[1]; version = $parts[2] }
}

$matches = @()
foreach ($pkg in $packages) {
    $advisories = $feed | Where-Object { $_.package -eq $pkg.name }
    foreach ($adv in $advisories) {
        $matches += [ordered]@{
            package = $pkg.name
            version = $pkg.version
            advisory = $adv.cve
            confidence = "potential"
            reference = $adv.reference
        }
    }
}

Export-Results -Data $matches -Path $OutFile -Format json
