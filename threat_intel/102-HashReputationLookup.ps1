#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Hashes,
    [Parameter(Mandatory = $true)][ValidateSet("VirusTotal", "MalwareBazaar", "CustomHttp")][string]$Provider,
    [Parameter()][string]$ApiKeySecretName = "",
    [Parameter()][string]$OutFile = "out/hash_reputation.json"
)

Write-Host "AUTHORIZED USE ONLY - Hash reputation."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$apiKey = $null
if ($ApiKeySecretName) { $apiKey = Get-Secret -Name $ApiKeySecretName -ErrorAction SilentlyContinue }
$cache = @{}
$results = @()
foreach ($hash in $Hashes) {
    if ($hash -notmatch "^[A-Fa-f0-9]{64}$") {
        $results += [ordered]@{ hash = $hash; error = "Invalid SHA256" }
        continue
    }
    if ($cache.ContainsKey($hash)) { $results += $cache[$hash]; continue }
    Start-Sleep -Milliseconds 250
    $result = [ordered]@{ hash = $hash; provider = $Provider; reputation = "unknown" }
    try {
        switch ($Provider) {
            "VirusTotal" {
                $headers = @{ "x-apikey" = [System.Net.NetworkCredential]::new("", $apiKey).Password }
                $response = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/files/$hash" -Headers $headers -Method Get -ErrorAction Stop
                $result.reputation = $response.data.attributes.last_analysis_stats
            }
            "MalwareBazaar" {
                $response = Invoke-RestMethod -Uri "https://mb-api.abuse.ch/api/v1/" -Method Post -Body @{ query = "get_info"; hash = $hash } -ErrorAction Stop
                $result.reputation = $response.query_status
            }
            "CustomHttp" { $result.reputation = "custom-provider" }
        }
    } catch {
        $result.error = $_.Exception.Message
    }
    $cache[$hash] = $result
    $results += $result
}

Export-Results -Data $results -Path $OutFile -Format json
