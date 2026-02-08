#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter()][string[]]$Paths = @("/tmp", "/var/tmp", "/home", "/etc"),
    [Parameter()][ValidateRange(1, 365)][int]$ModifiedWithinDays = 3,
    [Parameter()][ValidateRange(1, 2000)][int]$MaxItems = 500
)

Write-Host "AUTHORIZED USE ONLY - File metadata triage."
Import-Module "./00-CommonFunctions.psm1" -Force
Assert-CommandExists -Name "find"
Assert-CommandExists -Name "file"

$files = @()
foreach ($path in $Paths) {
    $files += & find $path -type f -mtime -$ModifiedWithinDays 2>$null
}

$results = @()
$truncated = $false
foreach ($filePath in $files) {
    if ($results.Count -ge $MaxItems) { $truncated = $true; break }
    try {
        $info = Get-Item $filePath -ErrorAction Stop
        $type = & file -b $filePath 2>$null
        $hash = Get-FileHash -Path $filePath -Algorithm SHA256 -ErrorAction Stop
        $results += [ordered]@{
            path = $filePath
            owner = (Get-Acl $filePath).Owner
            mode = $info.Mode
            mtime = $info.LastWriteTime.ToString("o")
            type = $type
            sha256 = $hash.Hash
        }
    } catch {
        $results += [ordered]@{ path = $filePath; error = $_.Exception.Message }
    }
}

$result = [ordered]@{ truncated = $truncated; items = $results }
Export-Results -Data $result -Path "out/recent_suspicious_files.json" -Format json
