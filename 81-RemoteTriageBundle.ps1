#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Hosts,
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter()][string]$OutDir = "out/triage_bundles",
    [Parameter()][switch]$IncludeLogs = $true
)

Write-Host "AUTHORIZED USE ONLY - Remote triage bundle."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "ssh"
Assert-CommandExists -Name "tar"

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$index = @()
foreach ($host in $Hosts) {
    $remoteDir = "/tmp/triage_$host"
    $remoteTar = "/tmp/triage_$host.tar.gz"
    $logCmd = $IncludeLogs ? "cp /var/log/auth.log $remoteDir/ 2>/dev/null || true" : ""
    $remoteScript = @(
        "rm -rf $remoteDir $remoteTar",
        "mkdir -p $remoteDir",
        "uname -a > $remoteDir/uname.txt",
        "ps aux > $remoteDir/ps.txt",
        "ss -tunap > $remoteDir/ss.txt",
        $logCmd,
        "sed -E -i 's/AKIA[0-9A-Z]{16}/[REDACTED]/g' $remoteDir/*.log 2>/dev/null || true",
        "tar -czf $remoteTar -C $remoteDir .",
        "rm -rf $remoteDir"
    ) -join "; "

    & ssh "$User@$host" $remoteScript 2>$null
    $localTar = Join-Path $OutDir "triage_$host.tar.gz"
    & scp "$User@$host:$remoteTar" $localTar 2>$null
    & ssh "$User@$host" "rm -f $remoteTar" 2>$null

    $index += [ordered]@{ host = $host; bundle = $localTar }
}

Export-Results -Data $index -Path "out/triage_index.json" -Format json
