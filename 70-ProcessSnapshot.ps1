#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$OutFile = "out/process_snapshot.json"
)

Write-Host "AUTHORIZED USE ONLY - Process snapshot."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "ps"

$lines = & ps -eo pid,ppid,user,%cpu,%mem,lstart,args --no-headers
$results = foreach ($line in $lines) {
    $parts = $line -split "\s+", 9
    [ordered]@{
        pid = [int]$parts[0]
        ppid = [int]$parts[1]
        user = $parts[2]
        cpu = $parts[3]
        mem = $parts[4]
        start = ($parts[5..8] -join " ")
        cmdline = $parts[8]
    }
}

Export-Results -Data $results -Path $OutFile -Format json
