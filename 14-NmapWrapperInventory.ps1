#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Targets,
    [Parameter()][ValidateRange(1, 65535)][int]$TopPorts = 1000,
    [Parameter()][switch]$ServiceDetect = $true,
    [Parameter()][ValidateRange(1, 10000)][int]$RateLimit = 100
)

Write-Host "AUTHORIZED USE ONLY - Authorised targets only."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "nmap"

$targetList = @()
if (Test-Path $Targets) {
    $targetList = Get-Content $Targets | Where-Object { $_ -and $_ -notmatch '^\s*#' }
} else {
    $targetList = $Targets.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

$rawXml = "out/nmap_raw.xml"
$arguments = @("-oX", $rawXml, "--top-ports", $TopPorts, "-sT", "-Pn", "--min-rate", $RateLimit)
if ($ServiceDetect) { $arguments += "-sV" }
$arguments += $targetList
& nmap @arguments | Out-Null

[xml]$xml = Get-Content $rawXml
$results = foreach ($host in $xml.nmaprun.host) {
    $hostAddress = ($host.address | Select-Object -First 1).addr
    $ports = foreach ($port in $host.ports.port) {
        [ordered]@{
            port = [int]$port.portid
            protocol = $port.protocol
            state = $port.state.state
            service = $port.service.name
            product = $port.service.product
        }
    }
    [ordered]@{ host = $hostAddress; ports = $ports }
}

Export-Results -Data $results -Path "out/nmap_inventory.json" -Format json
