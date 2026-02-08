#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter()][string[]]$DkimSelectors = @(),
    [Parameter()][string]$Resolver = "1.1.1.1"
)

Write-Host "AUTHORIZED USE ONLY - Email DNS posture checks."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "dig"

function Get-TxtRecord {
    param([string]$Name)
    $output = & dig @$Resolver $Name TXT +short 2>$null
    return $output
}

$spf = Get-TxtRecord -Name $Domain | Where-Object { $_ -match "v=spf1" }
$dmarc = Get-TxtRecord -Name "_dmarc.$Domain" | Where-Object { $_ -match "v=DMARC1" }
$dkimResults = @()
foreach ($selector in $DkimSelectors) {
    $record = Get-TxtRecord -Name "$selector._domainkey.$Domain"
    $dkimResults += [ordered]@{ selector = $selector; present = [bool]$record; record = $record }
}

$result = [ordered]@{
    domain = $Domain
    spfPresent = [bool]$spf
    spfRecord = $spf
    dmarcPresent = [bool]$dmarc
    dmarcRecord = $dmarc
    dkim = $dkimResults
}

Export-Results -Data $result -Path "out/email_dns_posture.json" -Format json
