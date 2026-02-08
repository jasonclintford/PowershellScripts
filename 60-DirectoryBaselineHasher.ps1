#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Paths,
    [Parameter()][string[]]$ExcludeGlobs = @("*.log", "*.tmp"),
    [Parameter()][string]$HashAlgorithm = "SHA256",
    [Parameter()][string]$OutFile = "out/fim_baseline.json"
)

Write-Host "AUTHORIZED USE ONLY - File integrity baseline."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "find"

$files = @()
foreach ($path in $Paths) {
    $files += & find $path -type f 2>$null
}

$results = @()
foreach ($file in $files) {
    if ($ExcludeGlobs | Where-Object { $file -like $_ }) { continue }
    try {
        $info = Get-Item $file -ErrorAction Stop
        $hash = Get-FileHash -Path $file -Algorithm $HashAlgorithm -ErrorAction Stop
        $results += [ordered]@{
            path = $file
            size = $info.Length
            mtime = $info.LastWriteTime.ToString("o")
            owner = (Get-Acl $file).Owner
            mode = (Get-Item $file).Mode
            hash = $hash.Hash
        }
    } catch {
        $results += [ordered]@{ path = $file; error = $_.Exception.Message }
    }
}

Export-Results -Data $results -Path $OutFile -Format json
