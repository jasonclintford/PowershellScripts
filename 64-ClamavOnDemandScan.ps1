#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [Parameter()][switch]$Recursive = $true,
    [Parameter()][ValidateRange(1, 500)][int]$MaxFileSizeMb = 50
)

Write-Host "AUTHORIZED USE ONLY - ClamAV scan."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "clamscan"

$args = @("--max-filesize=$($MaxFileSizeMb)M")
if ($Recursive) { $args += "-r" }
$args += $TargetPath
$output = & clamscan @args 2>$null

$detections = @()
$summary = @{}
foreach ($line in $output) {
    if ($line -match "^(.+): (.+) FOUND") {
        $detections += [ordered]@{ file = $Matches[1]; detection = $Matches[2] }
    }
    if ($line -match "^(Infected files|Scanned files|Errors):\s+(\d+)") {
        $summary[$Matches[1]] = [int]$Matches[2]
    }
}

$result = [ordered]@{ summary = $summary; detections = $detections }
Export-Results -Data $result -Path "out/clamav_scan.json" -Format json
