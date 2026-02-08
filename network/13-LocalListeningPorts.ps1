#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][switch]$IncludeUdp = $true,
    [Parameter()][switch]$IncludeTcp = $true
)

Write-Host "AUTHORIZED USE ONLY - Local inventory."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "ss"

$protocols = @()
if ($IncludeTcp) { $protocols += "tcp" }
if ($IncludeUdp) { $protocols += "udp" }

$results = @()
foreach ($proto in $protocols) {
    $output = & ss -lntup "( sport != 0 )" 2>$null
    foreach ($line in $output | Select-Object -Skip 1) {
        if ($line -notmatch "^$proto") { continue }
        $parts = $line -split "\s+"
        $local = $parts[4]
        $pidInfo = ($parts | Select-Object -Last 1)
        $pid = $null
        $process = $null
        if ($pidInfo -match "pid=(\d+),\"([^\"]+)\"") {
            $pid = $Matches[1]
            $process = $Matches[2]
        }
        $addrParts = $local.Split(":")
        $port = $addrParts[-1]
        $address = ($addrParts[0..($addrParts.Length - 2)] -join ":")
        $results += [ordered]@{
            protocol = $proto
            localAddress = $address
            port = $port
            pid = $pid
            process = $process
        }
    }
}

Export-Results -Data $results -Path "out/listening_ports.json" -Format json
