#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Urls,
    [Parameter()][ValidateRange(1, 120)][int]$TimeoutSec = 10,
    [Parameter()][string]$UserAgent = "PS-SecAudit/1.0"
)

Write-Host "AUTHORIZED USE ONLY - HTTP header baseline."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$headerChecks = @("Strict-Transport-Security", "Content-Security-Policy", "X-Frame-Options", "X-Content-Type-Options", "Referrer-Policy")

$results = foreach ($url in $Urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -UserAgent $UserAgent -TimeoutSec $TimeoutSec -MaximumRedirection 10 -SkipHttpErrorCheck
        $headers = @{}
        foreach ($key in $response.Headers.Keys) { $headers[$key] = $response.Headers[$key] }
        $findings = foreach ($header in $headerChecks) {
            if (-not $headers.ContainsKey($header)) {
                "Missing $header"
            }
        }
        [ordered]@{
            url = $url
            finalUrl = $response.BaseResponse.ResponseUri.AbsoluteUri
            statusCode = $response.StatusCode
            headers = $headers
            findings = @($findings)
        }
    } catch {
        [ordered]@{ url = $url; error = $_.Exception.Message }
    }
}

Export-Results -Data $results -Path "out/http_headers.json" -Format json
