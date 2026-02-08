#!/usr/bin/env pwsh
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()][string[]]$InstallTools = @("jq", "dnsutils", "iproute2", "openssl"),
    [Parameter()][string[]]$InstallPwshModules = @("PSScriptAnalyzer", "Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore"),
    [Parameter()][switch]$NonInteractive = $true
)

Write-Host "AUTHORIZED USE ONLY - This script is intended for approved environments."

if (-not $PSVersionTable.PSVersion) {
    throw "PowerShell not available."
}

Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$report = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    tools = @()
    modules = @()
}

if ($InstallTools.Count -gt 0) {
    Assert-CommandExists -Name "apt-get"
    $env:DEBIAN_FRONTEND = "noninteractive"
    if ($PSCmdlet.ShouldProcess("apt-get", "update")) {
        & apt-get update | Out-Null
    }
    foreach ($tool in $InstallTools) {
        $status = "skipped"
        if ($PSCmdlet.ShouldProcess($tool, "install")) {
            $args = @("install", "-y", $tool)
            if ($NonInteractive) { $args += "-qq" }
            $null = & apt-get @args
            $status = $LASTEXITCODE -eq 0 ? "installed" : "failed"
        }
        $version = (dpkg -s $tool 2>$null | Select-String -Pattern "Version" | ForEach-Object { $_.ToString().Split(" ")[-1] })
        $report.tools += [ordered]@{ name = $tool; status = $status; version = $version }
    }
}

foreach ($module in $InstallPwshModules) {
    $status = "skipped"
    if ($PSCmdlet.ShouldProcess($module, "install")) {
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            $status = "installed"
        } catch {
            $status = "failed"
        }
    }
    $mod = Get-Module -ListAvailable -Name $module | Select-Object -First 1
    $report.modules += [ordered]@{ name = $module; status = $status; version = $mod.Version.ToString() }
}

Export-Results -Data $report -Path "out/bootstrap_versions.json" -Format json
Write-Output "Installed tools: $($report.tools.Count); modules: $($report.modules.Count)"
