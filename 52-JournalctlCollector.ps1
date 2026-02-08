#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Unit,
    [Parameter()][string]$Since = "1 hour ago",
    [Parameter()][string]$Until = "now"
)

Write-Host "AUTHORIZED USE ONLY - Journald export."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "journalctl"

$metadata = [ordered]@{ script = "52-JournalctlCollector"; unit = $Unit; since = $Since; until = $Until; timestamp = (Get-Date).ToString("o") }
$lines = @($metadata | ConvertTo-Json -Compress)
$entries = & journalctl -u $Unit --since "$Since" --until "$Until" -o json 2>$null
$lines += $entries

$dir = "out"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$lines | Set-Content -Path "out/journal_unit.ndjson"
