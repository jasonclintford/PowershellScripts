#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string]$VaultName = "LocalSecretStore",
    [Parameter(Mandatory = $true)][ValidateSet("Init", "Set", "Get", "List")][string]$Action,
    [Parameter()][string]$SecretName,
    [Parameter()][securestring]$SecretValue
)

Write-Host "AUTHORIZED USE ONLY - This script is intended for approved environments."

Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

foreach ($module in @("Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        throw "Required module '$module' not installed."
    }
}

$entries = @()
$existing = "out/secrets_audit.json"
if (Test-Path $existing) {
    $entries = Get-Content $existing | ConvertFrom-Json
}

switch ($Action) {
    "Init" {
        Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction Stop
        Set-SecretStoreConfiguration -Authentication None -Interaction None -Confirm:$false
        $entries += [ordered]@{ timestamp = (Get-Date).ToString("o"); action = "Init"; vault = $VaultName }
        Write-Output "Vault initialized: $VaultName"
    }
    "Set" {
        if (-not $SecretName -or -not $SecretValue) { throw "SecretName and SecretValue are required for Set." }
        Set-Secret -Name $SecretName -Secret $SecretValue -Vault $VaultName -ErrorAction Stop
        $entries += [ordered]@{ timestamp = (Get-Date).ToString("o"); action = "Set"; vault = $VaultName; secret = $SecretName }
        Write-Output "Secret stored: $SecretName"
    }
    "Get" {
        if (-not $SecretName) { throw "SecretName is required for Get." }
        $null = Get-Secret -Name $SecretName -Vault $VaultName -ErrorAction Stop
        $entries += [ordered]@{ timestamp = (Get-Date).ToString("o"); action = "Get"; vault = $VaultName; secret = $SecretName }
        Write-Output "Secret retrieved: $SecretName (value masked)"
    }
    "List" {
        $secrets = Get-SecretInfo -Vault $VaultName -ErrorAction Stop
        $entries += [ordered]@{ timestamp = (Get-Date).ToString("o"); action = "List"; vault = $VaultName; count = $secrets.Count }
        Write-Output "Secrets in vault: $($secrets.Count)"
    }
}

Export-Results -Data $entries -Path "out/secrets_audit.json" -Format json
