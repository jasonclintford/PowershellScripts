#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Domains,
    [Parameter(Mandatory = $true)][ValidateSet("VirusTotal", "URLhaus", "CustomHttp")][string]$Provider,
    [Parameter()][string]$ApiKeySecretName = "",
    [Parameter()][string]$OutFile = "out/domain_reputation.json"
)

Write-Host "AUTHORIZED USE ONLY - Domain reputation."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$apiKey = $null
if ($ApiKeySecretName) { $apiKey = Get-Secret -Name $ApiKeySecretName -ErrorAction SilentlyContinue }
$cache = @{}
$results = @()
foreach ($domain in $Domains) {
    if ($cache.ContainsKey($domain)) { $results += $cache[$domain]; continue }
    Start-Sleep -Milliseconds 250
    $result = [ordered]@{ domain = $domain; provider = $Provider; reputation = "unknown" }
    try {
        switch ($Provider) {
            "VirusTotal" {
                $headers = @{ "x-apikey" = [System.Net.NetworkCredential]::new("", $apiKey).Password }
                $response = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/domains/$domain" -Headers $headers -Method Get -ErrorAction Stop
                $result.reputation = $response.data.attributes.reputation
            }
            "URLhaus" {
                $response = Invoke-RestMethod -Uri "https://urlhaus-api.abuse.ch/v1/host/" -Method Post -Body @{ host = $domain } -ErrorAction Stop
                $result.reputation = $response.query_status
            }
            "CustomHttp" { $result.reputation = "custom-provider" }
        }
    } catch {
        $result.error = $_.Exception.Message
    }
    $cache[$domain] = $result
    $results += $result
}

Export-Results -Data $results -Path $OutFile -Format json
