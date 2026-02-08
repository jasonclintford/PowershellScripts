#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$SshdConfigPath = "/etc/ssh/sshd_config",
    [Parameter()][switch]$UseSshdT = $true
)

Write-Host "AUTHORIZED USE ONLY - SSH configuration audit."
Import-Module "./00-CommonFunctions.psm1" -Force

$config = @{}
if ($UseSshdT -and (Get-Command sshd -ErrorAction SilentlyContinue)) {
    $output = & sshd -T 2>$null
    foreach ($line in $output) {
        $parts = $line -split "\s+"
        if ($parts.Length -ge 2) { $config[$parts[0]] = $parts[1] }
    }
} elseif (Test-Path $SshdConfigPath) {
    $lines = Get-Content $SshdConfigPath | Where-Object { $_ -and $_ -notmatch '^\s*#' }
    foreach ($line in $lines) {
        $parts = $line -split "\s+"
        if ($parts.Length -ge 2) { $config[$parts[0]] = $parts[1] }
    }
}

$result = [ordered]@{
    passwordAuthentication = $config["passwordauthentication"]
    permitRootLogin = $config["permitrootlogin"]
    kexAlgorithms = $config["kexalgorithms"]
    ciphers = $config["ciphers"]
}

Export-Results -Data $result -Path "out/sshd_posture.json" -Format json
