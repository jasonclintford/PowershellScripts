#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$Inputs,
    [Parameter()][string]$Title = "Security Audit Report",
    [Parameter()][string]$OutFile = "out/report.html"
)

Write-Host "AUTHORIZED USE ONLY - HTML report generation."
Import-Module (Join-Path $PSScriptRoot "../common/00-CommonFunctions.psm1") -Force

$sections = @()
foreach ($input in $Inputs) {
    if (-not (Test-Path $input)) { continue }
    $data = Get-Content $input | ConvertFrom-Json
    $section = "<h2>$input</h2><pre>$([System.Web.HttpUtility]::HtmlEncode(($data | ConvertTo-Json -Depth 5)))</pre>"
    $sections += $section
}

$html = @"
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>$Title</title>
<style>
body { font-family: Arial, sans-serif; margin: 20px; }
pre { background: #f4f4f4; padding: 10px; overflow: auto; }
</style>
</head>
<body>
<h1>$Title</h1>
<p>Generated: $(Get-Date)</p>
$($sections -join "\n")
</body>
</html>
"@

$dir = Split-Path -Parent $OutFile
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$html | Set-Content -Path $OutFile
