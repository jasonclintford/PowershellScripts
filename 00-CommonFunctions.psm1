function Write-AuditLog {
    <#
    .SYNOPSIS
        Write a structured audit log entry.
    .PARAMETER Action
        Action name.
    .PARAMETER Target
        Target item.
    .PARAMETER Result
        Result status.
    .PARAMETER Details
        Additional details.
    .PARAMETER ScriptId
        Script identifier.
    .PARAMETER Path
        Output path for the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$Result,
        [Parameter()][string]$Details,
        [Parameter()][string]$ScriptId = $MyInvocation.MyCommand.Name,
        [Parameter()][string]$Path = "out/audit_log.jsonl"
    )

    $entry = [ordered]@{
        timestamp = (Get-Date).ToString("o")
        host      = $env:HOSTNAME
        script_id = $ScriptId
        action    = $Action
        target    = $Target
        result    = $Result
        details   = $Details
    }

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $entry | ConvertTo-Json -Depth 5 -Compress | Add-Content -Path $Path
}

function Export-Results {
    <#
    .SYNOPSIS
        Export structured results to disk.
    .PARAMETER Data
        Data to export.
    .PARAMETER Path
        Output path.
    .PARAMETER Format
        Output format (json, ndjson, csv, html, sarif).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Data,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter()][ValidateSet("json", "ndjson", "csv", "html", "sarif")][string]$Format = "json"
    )

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    switch ($Format) {
        "json" { $Data | ConvertTo-Json -Depth 6 | Set-Content -Path $Path }
        "ndjson" {
            $lines = foreach ($item in $Data) { $item | ConvertTo-Json -Depth 6 -Compress }
            $lines | Set-Content -Path $Path
        }
        "csv" { $Data | Export-Csv -Path $Path -NoTypeInformation }
        default { $Data | ConvertTo-Json -Depth 6 | Set-Content -Path $Path }
    }
}

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Invoke a scriptblock with retries.
    .PARAMETER ScriptBlock
        Scriptblock to invoke.
    .PARAMETER RetryCount
        Maximum retries.
    .PARAMETER DelaySeconds
        Delay between retries.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [Parameter()][ValidateRange(0, 10)][int]$RetryCount = 3,
        [Parameter()][ValidateRange(0, 300)][int]$DelaySeconds = 2
    )

    for ($attempt = 0; $attempt -le $RetryCount; $attempt++) {
        try {
            return & $ScriptBlock
        } catch {
            if ($attempt -ge $RetryCount) {
                throw
            }
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

function Invoke-Parallel {
    <#
    .SYNOPSIS
        Run a scriptblock in parallel for input items.
    .PARAMETER InputObject
        Input objects.
    .PARAMETER ScriptBlock
        Scriptblock to run.
    .PARAMETER ThrottleLimit
        Throttle limit.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object[]]$InputObject,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [Parameter()][ValidateRange(1, 1024)][int]$ThrottleLimit = 50
    )

    $InputObject | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit
}

function Assert-CommandExists {
    <#
    .SYNOPSIS
        Ensure a command exists on PATH.
    .PARAMETER Name
        Command name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' is not available on PATH."
    }
}

Export-ModuleMember -Function Write-AuditLog, Export-Results, Invoke-WithRetry, Invoke-Parallel, Assert-CommandExists
