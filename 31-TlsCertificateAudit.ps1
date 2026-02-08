#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Targets,
    [Parameter()][ValidateRange(1, 365)][int]$NearExpiryDays = 30
)

Write-Host "AUTHORIZED USE ONLY - TLS certificate audit."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "openssl"

$results = foreach ($target in $Targets) {
    $host, $port = $target.Split(":")
    if (-not $port) { $port = "443" }
    $raw = & openssl s_client -connect "$host`:$port" -servername $host -showcerts < /dev/null 2>$null
    $certs = [regex]::Matches($raw, "-----BEGIN CERTIFICATE-----[\s\S]+?-----END CERTIFICATE-----") | ForEach-Object { $_.Value }
    $parsed = @()
    foreach ($cert in $certs) {
        $temp = New-TemporaryFile
        Set-Content -Path $temp -Value $cert
        $info = & openssl x509 -noout -subject -issuer -dates -ext subjectAltName -in $temp 2>$null
        Remove-Item $temp -Force
        $subject = ($info | Select-String -Pattern "subject=").ToString().Replace("subject=", "").Trim()
        $issuer = ($info | Select-String -Pattern "issuer=").ToString().Replace("issuer=", "").Trim()
        $notBefore = ($info | Select-String -Pattern "notBefore=").ToString().Replace("notBefore=", "").Trim()
        $notAfter = ($info | Select-String -Pattern "notAfter=").ToString().Replace("notAfter=", "").Trim()
        $san = ($info | Select-String -Pattern "DNS:").ToString().Trim()
        $parsed += [ordered]@{
            subject = $subject
            issuer = $issuer
            notBefore = $notBefore
            notAfter = $notAfter
            subjectAltName = $san
            nearExpiry = $false
        }
    }
    foreach ($entry in $parsed) {
        if ($entry.notAfter) {
            $expiry = Get-Date $entry.notAfter
            if ($expiry -lt (Get-Date).AddDays($NearExpiryDays)) { $entry.nearExpiry = $true }
        }
    }
    [ordered]@{ target = $target; certificates = $parsed }
}

Export-Results -Data $results -Path "out/tls_certs.json" -Format json
