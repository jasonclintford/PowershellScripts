#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$IocFile,
    [Parameter(Mandatory = $true)][string[]]$Paths,
    [Parameter()][ValidateRange(0, 20)][int]$ContextLines = 2,
    [Parameter()][ValidateRange(1, 10000)][int]$MaxMatches = 2000
)

Write-Host "AUTHORIZED USE ONLY - IOC string scan."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "rg"

if (-not (Test-Path $IocFile)) { throw "IOC file not found: $IocFile" }
$iocs = Get-Content $IocFile | Where-Object { $_ -and $_ -notmatch '^\s*#' }

$matches = @()
foreach ($ioc in $iocs) {
    $rgOutput = & rg -n -C $ContextLines $ioc $Paths 2>$null
    foreach ($line in $rgOutput) {
        if ($line -match "^(.*?):(\d+):(.*)$") {
            $matches += [ordered]@{
                ioc = $ioc
                file = $Matches[1]
                line = [int]$Matches[2]
                snippet = $Matches[3]
                matchType = "regex"
            }
            if ($matches.Count -ge $MaxMatches) { break }
        }
    }
    if ($matches.Count -ge $MaxMatches) { break }
}

Export-Results -Data $matches -Path "out/ioc_matches.json" -Format json
