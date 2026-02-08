#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaselineFile,
    [Parameter(Mandatory = $true)][string[]]$Paths,
    [Parameter()][string]$OutFile = "out/fim_diff.json"
)

Write-Host "AUTHORIZED USE ONLY - File integrity diff."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "find"

if (-not (Test-Path $BaselineFile)) { throw "Baseline file not found: $BaselineFile" }
$baseline = Get-Content $BaselineFile | ConvertFrom-Json
$baselineMap = @{}
foreach ($entry in $baseline) { $baselineMap[$entry.path] = $entry }

$currentFiles = @()
foreach ($path in $Paths) { $currentFiles += & find $path -type f 2>$null }

$added = @()
$removed = @()
$changed = @()
$errors = @()

foreach ($file in $currentFiles) {
    if (-not $baselineMap.ContainsKey($file)) {
        $added += $file
        continue
    }
    try {
        $hash = Get-FileHash -Path $file -Algorithm SHA256 -ErrorAction Stop
        if ($hash.Hash -ne $baselineMap[$file].hash) {
            $changed += $file
        }
    } catch {
        $errors += [ordered]@{ path = $file; error = $_.Exception.Message }
    }
    $baselineMap.Remove($file) | Out-Null
}

$removed = $baselineMap.Keys

$result = [ordered]@{
    summary = [ordered]@{ added = $added.Count; removed = $removed.Count; changed = $changed.Count; errors = $errors.Count }
    added = $added
    removed = $removed
    changed = $changed
    errors = $errors
}

Export-Results -Data $result -Path $OutFile -Format json
