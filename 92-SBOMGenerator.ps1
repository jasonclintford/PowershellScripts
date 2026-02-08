#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet("Image", "Directory")][string]$Mode,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter()][ValidateSet("cyclonedx-json", "spdx-json")][string]$Format = "cyclonedx-json"
)

Write-Host "AUTHORIZED USE ONLY - SBOM generation."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "syft"

$outFile = "out/sbom.json"
if ($Mode -eq "Image") {
    & syft $Target -o $Format > $outFile
} else {
    & syft "dir:$Target" -o $Format > $outFile
}
