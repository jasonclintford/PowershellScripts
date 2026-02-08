#!/usr/bin/env pwsh
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$CaseId,
    [Parameter(Mandatory = $true)][string[]]$SourcePaths,
    [Parameter()][string]$OutRoot = "cases"
)

Write-Host "AUTHORIZED USE ONLY - Case folder builder."
Import-Module "./00-CommonFunctions.psm1" -Force

$caseDir = Join-Path $OutRoot $CaseId
$rawDir = Join-Path $caseDir "raw"
$processedDir = Join-Path $caseDir "processed"
$reportsDir = Join-Path $caseDir "reports"

foreach ($dir in @($rawDir, $processedDir, $reportsDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

$index = [ordered]@{ caseId = $CaseId; items = @() }
foreach ($path in $SourcePaths) {
    if (-not (Test-Path $path)) { continue }
    $dest = Join-Path $rawDir ([IO.Path]::GetFileName($path))
    if ($PSCmdlet.ShouldProcess($path, "Copy")) {
        Copy-Item -Path $path -Destination $dest -Force
    }
    $hash = Get-FileHash -Path $dest -Algorithm SHA256
    $index.items += [ordered]@{ source = $path; copied = $dest; sha256 = $hash.Hash }
}

Export-Results -Data $index -Path (Join-Path $caseDir "index.json") -Format json
