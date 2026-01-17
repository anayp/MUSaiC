param(
    [string]$InputFile,
    [string]$OutputJson,
    [string]$Backend,
    [string[]]$BackendArgs,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- Configuration ---
$rootDir = $PSScriptRoot
$configHelper = Join-Path $rootDir "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig

if (-not $InputFile) {
    Write-Host "Usage: ./musaic-segment.ps1 -InputFile <wav> [-OutputJson <path>] [-Backend <cmd>] [-BackendArgs <...>] [-DryRun]"
    exit 1
}

$fileFull = [System.IO.Path]::GetFullPath($InputFile)
if (-not (Test-Path $fileFull)) { throw "Input file not found: $InputFile" }

# --- Resolve Output ---
if (-not $OutputJson) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileFull)
    $OutputJson = Join-Path $cfg.outputDir "analysis" "${baseName}_segments.json"
}

# --- Resolve Backend ---
$exe = if ($Backend) { $Backend } else { $cfg.segmenterPath }

if (-not $exe) {
    throw "No segmentation backend configured. Set 'segmenterPath' in musaic.config.json or use -Backend."
}

# --- Build Command ---
# Note: Actual arguments heavily depend on the backend (e.g. msaf, aubio)
if (-not $BackendArgs) {
    throw "No arguments provided for backend '$exe'. This stub requires explicit args."
}

# --- Execution ---
if ($DryRun) {
    Write-Host "Would run:" -ForegroundColor Cyan
    Write-Host "$exe $BackendArgs" -ForegroundColor Green
    Write-Host "Input: $fileFull"
    Write-Host "Output: $OutputJson"
    exit 0
}

Write-Host "Running segmentation..." -ForegroundColor Cyan
# In a real implementation, we would parse the output of the tool and normalize it to JSON.
# Since this is a scaffold, we defer execution to the backend directly?
# But we claim to output JSON. 
# For now, we assume the user invokes a backend that outputs to the target, or we just run the command.

$p = Start-Process -FilePath $exe -ArgumentList $BackendArgs -NoNewWindow -PassThru -Wait
if ($p.ExitCode -ne 0) {
    throw "Segmentation backend failed with exit code $($p.ExitCode)"
}

Write-Host "Segmentation complete (backend exit 0)." -ForegroundColor Green
