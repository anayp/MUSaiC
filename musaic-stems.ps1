param(
    [string]$InputFile,
    [string]$OutputDir,
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
    Write-Host "Usage: ./musaic-stems.ps1 -InputFile <wav> [-OutputDir <path>] [-Backend <cmd>] [-BackendArgs <...>] [-DryRun]"
    exit 1
}

$fileFull = [System.IO.Path]::GetFullPath($InputFile)
if (-not (Test-Path $fileFull)) { throw "Input file not found: $InputFile" }

# --- Resolve Output ---
if (-not $OutputDir) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileFull)
    $OutputDir = Join-Path $cfg.outputDir "stems" $baseName
}

# --- Resolve Backend ---
$exe = if ($Backend) { $Backend } else { $cfg.stemSeparatorPath }

if (-not $exe) {
    throw "No stem separation backend configured. Set 'stemSeparatorPath' in musaic.config.json or use -Backend (e.g. demucs)."
}

# --- Build Command ---
if (-not $BackendArgs) {
    throw "No arguments provided for backend '$exe'. This stub requires explicit args."
}

# --- Execution ---
if ($DryRun) {
    Write-Host "Would run:" -ForegroundColor Cyan
    Write-Host "$exe $BackendArgs" -ForegroundColor Green
    Write-Host "Input: $fileFull"
    Write-Host "Output: $OutputDir"
    exit 0
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

Write-Host "Running stem separation..." -ForegroundColor Cyan

$p = Start-Process -FilePath $exe -ArgumentList $BackendArgs -NoNewWindow -PassThru -Wait
if ($p.ExitCode -ne 0) {
    throw "Stem separation backend failed with exit code $($p.ExitCode)"
}

Write-Host "Stem separation complete (backend exit 0)." -ForegroundColor Green
