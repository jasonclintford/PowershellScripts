#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet("Image", "Filesystem")][string]$Mode,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter()][string[]]$Severity = @("CRITICAL", "HIGH", "MEDIUM")
)

Write-Host "AUTHORIZED USE ONLY - Trivy scan."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "trivy"

$rawOut = "out/trivy_raw.json"
$severityArg = $Severity -join ","
if ($Mode -eq "Image") {
    & trivy image --quiet --format json --severity $severityArg --output $rawOut $Target | Out-Null
} else {
    & trivy filesystem --quiet --format json --severity $severityArg --output $rawOut $Target | Out-Null
}

$raw = Get-Content $rawOut | ConvertFrom-Json
$summary = $raw.Results | ForEach-Object {
    [ordered]@{ target = $_.Target; vulnerabilities = ($_.Vulnerabilities | Measure-Object).Count }
}

Export-Results -Data $summary -Path "out/trivy_findings.json" -Format json
