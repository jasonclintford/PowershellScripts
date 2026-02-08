#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Inputs,
    [Parameter()][string[]]$RedactionPatterns = @("AKIA[0-9A-Z]{16}", "-----BEGIN PRIVATE KEY-----", "Bearer\\s+[A-Za-z0-9\\-\\._~\\+\\/]+=*"),
    [Parameter()][ValidateRange(1000, 50000000)][int]$MaxFileBytes = 5000000,
    [Parameter()][string]$OutZip = "out/sanitised_export.zip"
)

Write-Host "AUTHORIZED USE ONLY - Safe export."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "zip"

$tempDir = Join-Path (Get-Location) "out/sanitised"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$manifest = @()
foreach ($input in $Inputs) {
    if (-not (Test-Path $input)) { continue }
    $dest = Join-Path $tempDir ([IO.Path]::GetFileName($input))
    $content = Get-Content $input -Raw -ErrorAction SilentlyContinue
    if ($content.Length -gt $MaxFileBytes) { $content = $content.Substring(0, $MaxFileBytes) }
    foreach ($pattern in $RedactionPatterns) {
        $content = [regex]::Replace($content, $pattern, "[REDACTED]")
    }
    $content | Set-Content -Path $dest
    $manifest += [ordered]@{ source = $input; sanitized = $dest; truncated = ($content.Length -ge $MaxFileBytes) }
}

$zipDir = Split-Path -Parent $OutZip
if ($zipDir -and -not (Test-Path $zipDir)) { New-Item -ItemType Directory -Path $zipDir -Force | Out-Null }
& zip -r $OutZip $tempDir | Out-Null

Export-Results -Data $manifest -Path "out/sanitised_export_manifest.json" -Format json
