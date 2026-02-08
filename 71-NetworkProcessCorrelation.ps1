#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][int[]]$FlagUnexpectedPorts = @(22, 80, 443),
    [Parameter()][string]$OutFile = "out/socket_process_map.json"
)

Write-Host "AUTHORIZED USE ONLY - Socket/process correlation."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "ss"

$output = & ss -tunap 2>$null
$results = @()
foreach ($line in $output | Select-Object -Skip 1) {
    $parts = $line -split "\s+"
    if ($parts.Length -lt 6) { continue }
    $local = $parts[4]
    $pidInfo = $parts[-1]
    $pid = $null
    $process = $null
    if ($pidInfo -match "pid=(\d+),\"([^\"]+)\"") {
        $pid = $Matches[1]
        $process = $Matches[2]
    }
    $port = $local.Split(":")[-1]
    $unexpected = $FlagUnexpectedPorts.Count -gt 0 -and ($FlagUnexpectedPorts -notcontains [int]$port)
    $results += [ordered]@{
        protocol = $parts[0]
        local = $local
        port = $port
        pid = $pid
        process = $process
        unexpected = $unexpected
    }
}

Export-Results -Data $results -Path $OutFile -Format json
