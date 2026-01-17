param (
    [string]$ScorePath,
    [string]$MetaPath,
    [switch]$Play,
    [int]$PreviewBitDepth,
    [int]$PreviewSampleRate,
    [double]$PreviewTargetLufs,
    [switch]$PreviewDebug
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
if ($PreviewBitDepth) { $params["PreviewBitDepth"] = $PreviewBitDepth }
if ($PreviewSampleRate) { $params["PreviewSampleRate"] = $PreviewSampleRate }
if ($PreviewTargetLufs) { $params["PreviewTargetLufs"] = $PreviewTargetLufs }
if ($PreviewDebug) { $params["PreviewDebug"] = $true }

Write-Host "Invoking Preview..." -ForegroundColor Cyan
& $script @params
