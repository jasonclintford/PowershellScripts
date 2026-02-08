#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Cidr,
    [Parameter()][string]$Resolver = "1.1.1.1",
    [Parameter()][ValidateRange(1, 1024)][int]$Concurrency = 200
)

Write-Host "AUTHORIZED USE ONLY - Authorised networks only."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force
Assert-CommandExists -Name "dig"

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
    $output = & dig @$using:Resolver -x $ip +short 2>$null
    $status = $output ? "NOERROR" : "NXDOMAIN"
    [ordered]@{
        ip = $ip
        ptr = @($output)
        status = $status
        resolver = $using:Resolver
    }
}

Export-Results -Data $results -Path "out/reverse_dns.json" -Format json
