#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$OutFile = "out/container_risks.json"
)

Write-Host "AUTHORIZED USE ONLY - Container escape surface check."
Import-Module "./00-CommonFunctions.psm1" -Force

$dockerSock = Test-Path "/var/run/docker.sock"
$mounts = Get-Content /proc/mounts | ForEach-Object { $_.Split(" ")[1] }
$hostMounts = $mounts | Where-Object { $_ -like "/host*" -or $_ -like "/mnt*" }

$result = [ordered]@{
    dockerSocketPresent = $dockerSock
    hostMounts = $hostMounts
    privilegedIndicators = @()
}

if (Test-Path "/proc/1/environ") {
    $envData = Get-Content /proc/1/environ -Raw
    if ($envData -match "container=") {
        $result.privilegedIndicators += "container-env-present"
    }
}

Export-Results -Data $result -Path $OutFile -Format json
