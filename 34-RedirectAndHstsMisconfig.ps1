#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Urls,
    [Parameter()][ValidateRange(1, 20)][int]$MaxRedirects = 10
)

Write-Host "AUTHORIZED USE ONLY - Redirect and HSTS checks."
Import-Module "./00-CommonFunctions.psm1" -Force

$results = foreach ($url in $Urls) {
    $chain = @()
    $current = $url
    $downgrade = $false
    $loop = $false
    for ($i = 0; $i -lt $MaxRedirects; $i++) {
        $response = Invoke-WebRequest -Uri $current -Method Get -MaximumRedirection 0 -SkipHttpErrorCheck
        $chain += [ordered]@{ url = $current; status = $response.StatusCode }
        if ($response.StatusCode -ge 300 -and $response.StatusCode -lt 400 -and $response.Headers["Location"]) {
            $next = $response.Headers["Location"]
            if ($next -notmatch "^https?://") { $next = (New-Object System.Uri([System.Uri]$current, $next)).AbsoluteUri }
            if ($current.StartsWith("https://") -and $next.StartsWith("http://")) { $downgrade = $true }
            if ($chain.url -contains $next) { $loop = $true; break }
            $current = $next
        } else {
            break
        }
    }
    [ordered]@{
        startUrl = $url
        chain = $chain
        finalUrl = $current
        downgrade = $downgrade
        redirectLoop = $loop
        hstsPresent = ($chain | Select-Object -Last 1).status -eq 200
    }
}

Export-Results -Data $results -Path "out/redirect_hsts_findings.json" -Format json
