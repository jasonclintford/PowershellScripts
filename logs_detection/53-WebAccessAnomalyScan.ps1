#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LogPath,
    [Parameter()][ValidateRange(1, 200)][int]$TopN = 25,
    [Parameter()][string[]]$SuspiciousPathPatterns = @("/admin", "/wp-admin", "/.env", "/phpmyadmin")
)

Write-Host "AUTHORIZED USE ONLY - Web access log analysis."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

if (-not (Test-Path $LogPath)) { throw "Log not found: $LogPath" }

$ipCounts = @{}
$pathCounts = @{}
$statusCounts = @{}
$uaCounts = @{}
$suspiciousMatches = @()

Get-Content $LogPath | ForEach-Object {
    $line = $_
    if ($line -match '^(\S+)\s+\S+\s+\S+\s+\[[^\]]+\]\s+"\S+\s+(\S+)\s+[^\"]+"\s+(\d{3})\s+\S+\s+"[^"]*"\s+"([^"]*)"') {
        $ip = $Matches[1]
        $path = $Matches[2]
        $status = $Matches[3]
        $ua = $Matches[4]
        $ipCounts[$ip] = 1 + ($ipCounts[$ip] | ForEach-Object { $_ })
        $pathCounts[$path] = 1 + ($pathCounts[$path] | ForEach-Object { $_ })
        $statusCounts[$status] = 1 + ($statusCounts[$status] | ForEach-Object { $_ })
        $uaCounts[$ua] = 1 + ($uaCounts[$ua] | ForEach-Object { $_ })
        foreach ($pattern in $SuspiciousPathPatterns) {
            if ($path -like "*$pattern*") {
                $suspiciousMatches += [ordered]@{ path = $path; ip = $ip; pattern = $pattern }
            }
        }
    }
}

function Get-Top {
    param($hash)
    $hash.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $TopN | ForEach-Object { [ordered]@{ key = $_.Key; count = $_.Value } }
}

$result = [ordered]@{
    topIps = Get-Top $ipCounts
    topPaths = Get-Top $pathCounts
    topStatusCodes = Get-Top $statusCounts
    topUserAgents = Get-Top $uaCounts
    suspiciousPaths = $suspiciousMatches
}

Export-Results -Data $result -Path "out/web_access_anomalies.json" -Format json
