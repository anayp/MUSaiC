param (
    [string]$ScorePath,
    [string]$MetaPath,
    [switch]$Play
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $ScorePath) {
    Write-Host "Usage: ./musaic-preview.ps1 -ScorePath <path> [-MetaPath <path>] [-Play]"
    exit 1
}

$script = Join-Path $PSScriptRoot "cdp-sequencer.ps1"

$params = @{
    ScorePath = $ScorePath
    Preview   = $true
}
if ($MetaPath) { $params["MetaPath"] = $MetaPath }
if ($Play) { $params["Play"] = $true }

Write-Host "Invoking Preview..." -ForegroundColor Cyan
& $script @params
