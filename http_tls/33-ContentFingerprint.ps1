#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$BaseUrls,
    [Parameter()][string[]]$Paths = @("/"),
    [Parameter()][string]$HashAlgorithm = "SHA256",
    [Parameter()][string]$BaselineFile = ""
)

Write-Host "AUTHORIZED USE ONLY - Content fingerprinting."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$baseline = @{}
if ($BaselineFile -and (Test-Path $BaselineFile)) {
    $baselineData = Get-Content $BaselineFile | ConvertFrom-Json
    foreach ($entry in $baselineData) { $baseline[$entry.url] = $entry.hash }
}

$results = foreach ($base in $BaseUrls) {
    foreach ($path in $Paths) {
        $url = ($base.TrimEnd("/") + $path)
        try {
            $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 15 -SkipHttpErrorCheck
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($response.Content)
            $hash = [BitConverter]::ToString([System.Security.Cryptography.HashAlgorithm]::Create($HashAlgorithm).ComputeHash($bytes)).Replace("-", "")
            $previous = $baseline[$url]
            [ordered]@{
                url = $url
                status = $response.StatusCode
                contentLength = $response.RawContentLength
                contentType = $response.Headers["Content-Type"]
                hash = $hash
                changed = $previous -and $previous -ne $hash
            }
        } catch {
            [ordered]@{ url = $url; error = $_.Exception.Message }
        }
    }
}

Export-Results -Data $results -Path "out/content_fingerprints.json" -Format json
