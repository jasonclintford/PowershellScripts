#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$RepoPath = ".",
    [Parameter()][string]$SarifOut = "out/gitleaks.sarif",
    [Parameter()][switch]$Redact = $true
)

Write-Host "AUTHORIZED USE ONLY - Secrets scan."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "gitleaks"

$dir = Split-Path -Parent $SarifOut
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$args = @("detect", "--source", $RepoPath, "--report-format", "sarif", "--report-path", $SarifOut)
if ($Redact) { $args += "--redact" }
& gitleaks @args

$argsJson = @("detect", "--source", $RepoPath, "--report-format", "json", "--report-path", "out/gitleaks.json")
if ($Redact) { $argsJson += "--redact" }
& gitleaks @argsJson
