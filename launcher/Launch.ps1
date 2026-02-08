#!/usr/bin/env pwsh
[CmdletBinding()]
param()

Write-Host "AUTHORIZED USE ONLY - Security script launcher."

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPaths = Get-ChildItem -Path $repoRoot -Recurse -Filter "*.ps1" | Where-Object {
    $_.FullName -notmatch [regex]::Escape([IO.Path]::Combine($repoRoot, "common")) -and
    $_.FullName -ne $MyInvocation.MyCommand.Path
} | Sort-Object FullName

$scripts = $scriptPaths | ForEach-Object { $_.FullName }

while ($true) {
    Write-Host "\nSelect a script to run:" 
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        $relative = $scripts[$i].Replace($repoRoot + [IO.Path]::DirectorySeparatorChar, "")
        Write-Host ("[{0}] {1}" -f ($i + 1), $relative)
    }
    Write-Host "[0] Exit"
    $choice = Read-Host "Enter selection"
    if ($choice -eq "0") { break }
    if (-not [int]::TryParse($choice, [ref]$null)) { continue }
    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $scripts.Count) {
        $script = $scripts[$index]
        $argsInput = Read-Host "Enter arguments (or leave blank)"
        if ($argsInput) {
            Invoke-Expression "pwsh `"$script`" $argsInput"
        } else {
            Invoke-Expression "pwsh `"$script`""
        }
    }
}
