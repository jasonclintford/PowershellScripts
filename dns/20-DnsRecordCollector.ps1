#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Domains,
    [Parameter()][string]$Resolver = "1.1.1.1"
)

Write-Host "AUTHORIZED USE ONLY - DNS inventory."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "dig"

$recordTypes = @("A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA")
$results = foreach ($domain in $Domains) {
    $records = @()
    foreach ($type in $recordTypes) {
        $output = & dig @$Resolver $domain $type +nocmd +noall +answer +comments 2>$null
        if ($output -match "status: (\w+)") {
            $status = $Matches[1]
        } else {
            $status = "NOERROR"
        }
        foreach ($line in $output | Where-Object { $_ -match "\s+IN\s+" }) {
            $parts = $line -split "\s+"
            $records += [ordered]@{
                domain = $domain
                type = $type
                ttl = [int]$parts[1]
                value = ($parts[4..($parts.Length - 1)] -join " ")
                resolver = $Resolver
                status = $status
            }
        }
        if (-not ($records | Where-Object { $_.type -eq $type })) {
            $records += [ordered]@{ domain = $domain; type = $type; ttl = $null; value = $null; resolver = $Resolver; status = $status }
        }
    }
    [ordered]@{ domain = $domain; records = $records }
}

Export-Results -Data $results -Path "out/dns_records.json" -Format json
