#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Domains,
    [Parameter()][string]$Resolver = "1.1.1.1"
)

Write-Host "AUTHORIZED USE ONLY - Review-only misconfig detection."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "dig"

$results = foreach ($domain in $Domains) {
    $cname = & dig @$Resolver $domain CNAME +short 2>$null
    $candidate = $false
    $targetStatus = "NONE"
    if ($cname) {
        $target = $cname.TrimEnd('.')
        $targetAnswer = & dig @$Resolver $target A +short 2>$null
        if (-not $targetAnswer) {
            $candidate = $true
            $targetStatus = "NXDOMAIN"
        } else {
            $targetStatus = "RESOLVED"
        }
    }
    [ordered]@{
        domain = $domain
        cname = $cname
        danglingCandidate = $candidate
        targetStatus = $targetStatus
        resolver = $Resolver
    }
}

Export-Results -Data $results -Path "out/dangling_dns.json" -Format json
