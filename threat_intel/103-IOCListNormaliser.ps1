#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Inputs,
    [Parameter()][string]$OutFile = "out/iocs_normalised.json"
)

Write-Host "AUTHORIZED USE ONLY - IOC normaliser."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$result = [ordered]@{
    ip = @{}
    domain = @{}
    url = @{}
    hash = @{}
    regex = @{}
    filePath = @{}
}

function Add-Ioc {
    param($type, $value, $source)
    if (-not $result[$type].ContainsKey($value)) { $result[$type][$value] = @() }
    $result[$type][$value] += $source
}

foreach ($input in $Inputs) {
    if (-not (Test-Path $input)) { continue }
    $ext = [IO.Path]::GetExtension($input).ToLower()
    $items = @()
    if ($ext -eq ".json") {
        $items = Get-Content $input | ConvertFrom-Json
    } elseif ($ext -eq ".csv") {
        $items = Import-Csv $input
    } else {
        $items = Get-Content $input | Where-Object { $_ -and $_ -notmatch '^\s*#' }
    }
    foreach ($item in $items) {
        $value = $item
        if ($item.PSObject.Properties[0]) { $value = $item.PSObject.Properties[0].Value }
        if ($value -match "^\d{1,3}(\.\d{1,3}){3}$") { Add-Ioc -type "ip" -value $value -source $input; continue }
        if ($value -match "^[A-Fa-f0-9]{64}$") { Add-Ioc -type "hash" -value $value -source $input; continue }
        if ($value -match "^https?://") { Add-Ioc -type "url" -value $value -source $input; continue }
        if ($value -match "^/.+") { Add-Ioc -type "filePath" -value $value -source $input; continue }
        if ($value -match "[.*+?^${}()|\[\]\\]") { Add-Ioc -type "regex" -value $value -source $input; continue }
        Add-Ioc -type "domain" -value $value -source $input
    }
}

$output = [ordered]@{
    ip = $result.ip.Keys
    domain = $result.domain.Keys
    url = $result.url.Keys
    hash = $result.hash.Keys
    regex = $result.regex.Keys
    filePath = $result.filePath.Keys
}

Export-Results -Data $output -Path $OutFile -Format json
