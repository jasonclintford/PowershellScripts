#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$Path = ".",
    [Parameter()][string[]]$Severity = @("Error", "Warning"),
    [Parameter()][string]$SarifOut = "out/pssa.sarif"
)

Write-Host "AUTHORIZED USE ONLY - This script is intended for approved environments."

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    throw "PSScriptAnalyzer is required."
}

Import-Module PSScriptAnalyzer -ErrorAction Stop

$results = Invoke-ScriptAnalyzer -Path $Path -Severity $Severity -Recurse

if ($SarifOut) {
    $sarif = ConvertTo-ScriptAnalyzerSarif -InputObject $results
    $dir = Split-Path -Parent $SarifOut
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $sarif | Set-Content -Path $SarifOut
}

$summary = $results | Group-Object Severity | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Count }
if ($summary) {
    $summary | ForEach-Object { Write-Output $_ }
}

if ($results | Where-Object Severity -eq "Error") {
    exit 1
}
