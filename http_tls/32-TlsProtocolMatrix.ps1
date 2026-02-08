#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Targets,
    [Parameter()][string[]]$Protocols = @("tls1", "tls1_1", "tls1_2", "tls1_3")
)

Write-Host "AUTHORIZED USE ONLY - TLS protocol matrix."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "openssl"

$results = foreach ($target in $Targets) {
    $host, $port = $target.Split(":")
    if (-not $port) { $port = "443" }
    $protocolResults = foreach ($protocol in $Protocols) {
        $output = & timeout 6 openssl s_client -connect "$host`:$port" -servername $host -$protocol < /dev/null 2>$null
        $success = $output -match "Protocol"
        $negotiated = ($output | Select-String -Pattern "Protocol" | Select-Object -First 1).ToString()
        [ordered]@{ protocol = $protocol; success = [bool]$success; details = $negotiated }
    }
    [ordered]@{ target = $target; protocols = $protocolResults }
}

Export-Results -Data $results -Path "out/tls_protocol_matrix.json" -Format json
