#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string[]]$Resolvers,
    [Parameter()][string[]]$RecordTypes = @("A", "AAAA", "CNAME", "MX", "TXT")
)

Write-Host "AUTHORIZED USE ONLY - DNS comparison."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "dig"

$results = @()
foreach ($type in $RecordTypes) {
    $resolverResults = @()
    foreach ($resolver in $Resolvers) {
        $output = & dig @$resolver $Domain $type +short 2>$null
        $resolverResults += [ordered]@{ resolver = $resolver; answers = @($output) }
    }
    $unique = ($resolverResults.answers | ForEach-Object { $_ }) | Sort-Object -Unique
    $consistent = $unique.Count -le 1
    $results += [ordered]@{
        recordType = $type
        consistent = $consistent
        resolvers = $resolverResults
    }
}

Export-Results -Data $results -Path "out/dns_compare.json" -Format json
