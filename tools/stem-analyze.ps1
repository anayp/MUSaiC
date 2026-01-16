param(
    [string]$StemDir = "output/tmp_sequencer",
    [string]$OutPath = "output/analysis/stem_report.json",
    [double]$TargetRMS = -18.0
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- Configuration ---
$rootDir = $PSScriptRoot | Split-Path -Parent
$configHelper = Join-Path $rootDir "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig

$ffmpeg = $cfg.ffmpegPath

# --- Resolve Paths ---
if (-not [System.IO.Path]::IsPathRooted($StemDir)) {
    $StemDir = Join-Path $rootDir $StemDir
}
if (-not [System.IO.Path]::IsPathRooted($OutPath)) {
    $OutPath = Join-Path $rootDir $OutPath
}

if (-not (Test-Path $StemDir)) {
    throw "Stem directory not found: $StemDir"
}

# Ensure Output Dir
$outDir = Split-Path $OutPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

Write-Host "Analyzing Stems in: $StemDir" -ForegroundColor Cyan
Write-Host "Target RMS: $TargetRMS dB" -ForegroundColor Gray

$stems = Get-ChildItem -Path $StemDir -Filter "track_*_mix.wav"
if ($stems.Count -eq 0) {
    Write-Warning "No stems (track_*_mix.wav) found in $StemDir."
    exit 0
}

$results = @()

foreach ($file in $stems) {
    $name = $file.Name
    # Extract track name: track_NAME_mix.wav
    if ($name -match "track_(.+)_mix\.wav") {
        $trackName = $matches[1]
    }
    else {
        $trackName = $name
    }

    Write-Host "Processing $trackName..." -NoNewline

    # Run Volumedetect
    $procArgs = @("-i", $file.FullName, "-af", "volumedetect", "-f", "null", "-")
    
    $p = Start-Process -FilePath $ffmpeg -ArgumentList $procArgs -NoNewWindow -Wait -PassThru -RedirectStandardError (Join-Path $StemDir "ffmpeg_log.txt")
    
    # Read output from log (ffmpeg writes stats to stderr)
    $logContent = Get-Content (Join-Path $StemDir "ffmpeg_log.txt") -Raw
    
    # Parse
    $maxVol = -99.9
    $meanVol = -99.9
    
    if ($logContent -match "max_volume: ([\-\d\.]+) dB") {
        $maxVol = [double]$matches[1]
    }
    if ($logContent -match "mean_volume: ([\-\d\.]+) dB") {
        $meanVol = [double]$matches[1]
    }

    # Suggestions
    $suggestedGain = 0.0
    if ($meanVol -gt -90) {
        $suggestedGain = $TargetRMS - $meanVol
    }
    
    # Clip warning
    $clipWarn = ""
    if ($maxVol -gt -0.1) { $clipWarn = "[CLIPPING]" }

    # Formatting
    Write-Host " Mean: $meanVol dB | Max: $maxVol dB $clipWarn -> Suggest: $( "{0:N1}" -f $suggestedGain ) dB" -ForegroundColor Green

    $results += [ordered]@{
        track          = $trackName
        file           = $file.Name
        mean_volume    = $meanVol
        max_volume     = $maxVol
        suggested_gain = [math]::Round($suggestedGain, 2)
        clipping       = ($maxVol -gt -0.1)
    }
}

# Save JSON
$results | ConvertTo-Json -Depth 2 | Set-Content -Path $OutPath -Encoding UTF8
Write-Host "Report saved to: $OutPath" -ForegroundColor Cyan
