#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Cidr,
    [Parameter()][ValidateRange(1, 1024)][int]$Concurrency = 200,
    [Parameter()][ValidateRange(100, 10000)][int]$TimeoutMs = 1000
)

Write-Host "AUTHORIZED USE ONLY - Authorised networks only."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

function Convert-CidrToIps {
    param([string]$CidrInput)
    $parts = $CidrInput.Split("/")
    $base = $parts[0]
    $prefix = [int]$parts[1]
    $bytes = [System.Net.IPAddress]::Parse($base).GetAddressBytes()
    [array]::Reverse($bytes)
    $ipInt = [BitConverter]::ToUInt32($bytes, 0)
    $mask = [uint32]0xffffffff << (32 - $prefix)
    $network = $ipInt -band $mask
    $broadcast = $network + ([uint32]0xffffffff - $mask)
    $ips = for ($i = $network; $i -le $broadcast; $i++) {
        $b = [BitConverter]::GetBytes($i)
        [array]::Reverse($b)
        ([System.Net.IPAddress]::new($b)).ToString()
    }
    return $ips
}

$targets = Convert-CidrToIps -CidrInput $Cidr

$results = Invoke-Parallel -InputObject $targets -ThrottleLimit $Concurrency -ScriptBlock {
    param($ip)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "unknown"
    try {
        $reply = Test-Connection -TargetName $ip -Count 1 -TimeoutSeconds ([math]::Ceiling($using:TimeoutMs / 1000)) -ErrorAction SilentlyContinue
        if ($reply) {
            $status = "alive"
        } else {
            $status = "dead"
        }
    } catch {
        $status = "unknown"
    }
    $stopwatch.Stop()
    [ordered]@{
        ip = $ip
        status = $status
        latencyMs = $stopwatch.ElapsedMilliseconds
    }
}

Export-Results -Data $results -Path "out/reachability.json" -Format json
$counts = $results | Group-Object status | ForEach-Object { "$($_.Name)=$($_.Count)" }
Write-Output ($counts -join ", ")
