#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RulesPath,
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [Parameter()][switch]$Recursive = $true
)

Write-Host "AUTHORIZED USE ONLY - YARA scan."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "yara"

$args = @()
if ($Recursive) { $args += "-r" }
$args += @($RulesPath, $TargetPath)

$output = & yara @args 2>$null
$matches = foreach ($line in $output) {
    $parts = $line -split "\s+"
    if ($parts.Length -ge 2) {
        [ordered]@{ rule = $parts[0]; file = $parts[1] }
    }
}

Export-Results -Data $matches -Path "out/yara_matches.json" -Format json
