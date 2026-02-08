#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string[]]$Paths = @("/"),
    [Parameter()][string[]]$ExcludePaths = @("/proc", "/sys", "/dev"),
    [Parameter()][ValidateRange(1, 20)][int]$MaxDepth = 6
)

Write-Host "AUTHORIZED USE ONLY - Permission scan."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$excludeArgs = $ExcludePaths | ForEach-Object { "-path $_ -prune -o" }
$pathArgs = $Paths -join " "

$worldWritable = @()
$cmd = "find $pathArgs -maxdepth $MaxDepth $(($excludeArgs -join ' ')) -type f -perm -0002 -print"
$worldWritable = & bash -c $cmd 2>$null

$suid = @()
$cmdSuid = "find $pathArgs -maxdepth $MaxDepth $(($excludeArgs -join ' ')) -type f -perm -4000 -print"
$suid = & bash -c $cmdSuid 2>$null

$sgid = @()
$cmdSgid = "find $pathArgs -maxdepth $MaxDepth $(($excludeArgs -join ' ')) -type f -perm -2000 -print"
$sgid = & bash -c $cmdSgid 2>$null

$capabilities = @()
if (Get-Command getcap -ErrorAction SilentlyContinue) {
    $capabilities = & getcap -r $Paths 2>$null
}

$result = [ordered]@{
    worldWritable = @($worldWritable)
    suid = @($suid)
    sgid = @($sgid)
    capabilities = @($capabilities)
}

Export-Results -Data $result -Path "out/permissions_findings.json" -Format json
