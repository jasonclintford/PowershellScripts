#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Ips,
    [Parameter(Mandatory = $true)][ValidateSet("VirusTotal", "AbuseIPDB", "CustomHttp")][string]$Provider,
    [Parameter(Mandatory = $true)][string]$ApiKeySecretName,
    [Parameter()][string]$OutFile = "out/ip_reputation.json"
)

Write-Host "AUTHORIZED USE ONLY - Threat intel enrichment."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement)) {
    throw "SecretManagement module is required."
}

$apiKey = Get-Secret -Name $ApiKeySecretName -ErrorAction Stop
$cache = @{}
$results = @()
foreach ($ip in $Ips) {
    if ($cache.ContainsKey($ip)) { $results += $cache[$ip]; continue }
    Start-Sleep -Milliseconds 250
    $result = [ordered]@{ ip = $ip; provider = $Provider; reputation = "unknown" }
    try {
        switch ($Provider) {
            "VirusTotal" {
                $headers = @{ "x-apikey" = [System.Net.NetworkCredential]::new("", $apiKey).Password }
                $response = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/ip_addresses/$ip" -Headers $headers -Method Get -ErrorAction Stop
                $result.reputation = $response.data.attributes.reputation
            }
            "AbuseIPDB" {
                $headers = @{ Key = [System.Net.NetworkCredential]::new("", $apiKey).Password; Accept = "application/json" }
                $response = Invoke-RestMethod -Uri "https://api.abuseipdb.com/api/v2/check?ipAddress=$ip" -Headers $headers -Method Get -ErrorAction Stop
                $result.reputation = $response.data.abuseConfidenceScore
            }
            "CustomHttp" {
                $result.reputation = "custom-provider"
            }
        }
    } catch {
        $result.error = $_.Exception.Message
    }
    $cache[$ip] = $result
    $results += $result
}

Export-Results -Data $results -Path $OutFile -Format json
