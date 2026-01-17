param(
    [string]$StemDir = "output/tmp_sequencer",
    [string]$OutPath = "output/analysis/stem_report.json",
    [double]$TargetRMS = -18.0,
    [switch]$CopyToTemp = $true
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
$skipped = @()

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

    $sourcePath = $file.FullName
    $analyzePath = $sourcePath
    $isTemp = $false

    if ($CopyToTemp) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $retries = 3
        $copied = $false
        for ($i = 0; $i -lt $retries; $i++) {
            try {
                Copy-Item -Path $sourcePath -Destination $tempFile -Force -ErrorAction Stop
                $copied = $true
                break
            }
            catch {
                Start-Sleep -Milliseconds 200
            }
        }

        if (-not $copied) {
            Write-Warning " [LOCKED] Skipping."
            $skipped += [ordered]@{
                file   = $file.Name
                reason = "Locked"
            }
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            continue
        }
        $analyzePath = $tempFile
        $isTemp = $true
    }

    # Use a unique log file to avoid contention if running in parallel contexts (though this script is serial)
    $logFile = [System.IO.Path]::GetTempFileName()

    # Run Volumedetect
    $procArgs = @("-i", $analyzePath, "-af", "volumedetect", "-f", "null", "-")
    
    try {
        $p = Start-Process -FilePath $ffmpeg -ArgumentList $procArgs -NoNewWindow -Wait -PassThru -RedirectStandardError $logFile
        
        # Retry loop for parsing logs
        $parseRetries = 3
        $parsed = $false
        $maxVol = -99.9
        $meanVol = -99.9

        for ($k = 0; $k -le $parseRetries; $k++) {
            $logContent = Get-Content $logFile -Raw
            $foundMatches = $false

            if ($logContent -match "max_volume: ([\-\d\.]+) dB") {
                $maxVol = [double]$matches[1]
                $foundMatches = $true
            }
            if ($logContent -match "mean_volume: ([\-\d\.]+) dB") {
                $meanVol = [double]$matches[1]
                $foundMatches = $true
            }

            if ($foundMatches) {
                $parsed = $true
                break
            }
            Start-Sleep -Milliseconds 200
        }

        if (-not $parsed) {
            Write-Warning " [PARSE FAIL] Could not find volume stats."
            $skipped += [ordered]@{
                file   = $file.Name
                reason = "ParseFailed"
            }
            continue
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
    catch {
        Write-Error "Analysis failed for $trackName : $_"
        $skipped += [ordered]@{
            file   = $file.Name
            reason = "Analysis Error"
        }
    }
    finally {
        if ($isTemp) { Remove-Item $analyzePath -Force -ErrorAction SilentlyContinue }
        if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }
    }
}

$outputData = [ordered]@{
    analyzed_at = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    results     = $results
    skipped     = $skipped
}

# Save JSON
$outputData | ConvertTo-Json -Depth 3 | Set-Content -Path $OutPath -Encoding UTF8
Write-Host "Report saved to: $OutPath" -ForegroundColor Cyan
