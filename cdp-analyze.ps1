param(
    [Parameter(Mandatory = $false)]
    [string]$Mode = "all",
    
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $false)]
    [double]$TargetLufs,
    
    [Parameter(Mandatory = $false)]
    [double]$OnsetThresholdDb = -30,
    
    [Parameter(Mandatory = $false)]
    [double]$OnsetMinDur = 0.05
)

$ErrorActionPreference = "Stop"
$cdpBin = "f:\CDP\CDPR8\_cdp\_cdprogs"
$sndInfo = Join-Path $cdpBin "sndinfo.exe"
$pitchExe = Join-Path $cdpBin "pitch.exe"
$viewExe = Join-Path $cdpBin "view.exe"

if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }
$InputFile = (Resolve-Path $InputFile).Path

function Get-Loudness {
    # ffmpeg volumedetect
    $p = Start-Process ffmpeg -ArgumentList "-i", $InputFile, "-af", "volumedetect", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "vol_err.txt"
    $err = Get-Content "vol_err.txt"
    $mean = ($err | Select-String "mean_volume") -replace ".*mean_volume:\s*", "" -replace " dB", ""
    $max = ($err | Select-String "max_volume") -replace ".*max_volume:\s*", "" -replace " dB", ""
    
    return @{
        RMS_dB  = if ($mean) { [double]$mean } else { $null }
        Peak_dB = if ($max) { [double]$max } else { $null }
    }
}

function Get-Lufs {
    # ffmpeg ebur128=peak=none
    # output: "I:         -14.5 LUFS"
    $p = Start-Process ffmpeg -ArgumentList "-i", $InputFile, "-af", "ebur128=peak=none", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "lufs_err.txt"
    $err = Get-Content "lufs_err.txt"
    
    # scan for "I:" followed by number
    # regex: I:\s+([-\d\.]+) LUFS
    
    $iVal = $null
    foreach ($line in $err) {
        if ($line -match "I:\s+([-\d\.]+)") {
            $iVal = [double]$Matches[1]
            # Keep reading, ebur128 outputs periodically, final summary is at end.
            # But usually the last match is the integrated whole-file summary if filter ran to completion.
        }
    }
    return $iVal
}

function Get-Onsets {
    # ffmpeg silencedetect (inverse logic: silence_end = onset of sound)
    # silencedetect=noise=-30dB:d=0.05
    $filter = "silencedetect=noise=$($OnsetThresholdDb)dB:d=$($OnsetMinDur)"
    
    $p = Start-Process ffmpeg -ArgumentList "-i", $InputFile, "-af", $filter, "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "onset_err.txt"
    $err = Get-Content "onset_err.txt"
    
    # Parse "silence_end: 12.345"
    # Actually, silence_end marks the END of silence, i.e., the START of sound. This is a good proxy for onsets in sparse audio.
    # For dense audio, this metric is less useful (will just see one long sound), but instructions specifically asked for this.
    
    $count = 0
    foreach ($line in $err) {
        if ($line -match "silence_end:\s+([\d\.]+)") {
            $count++
        }
    }
    return $count
}

function Get-Beats {
    # ffmpeg bpm
    $p = Start-Process ffmpeg -ArgumentList "-i", $InputFile, "-af", "bpm", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "bpm_err.txt"
    $err = Get-Content "bpm_err.txt"
    $bpmLines = $err | Select-String "BPM"
    
    if ($bpmLines) {
        # strict parse of last line: "^\[Parsed_bpm.*\] BPM (\d+\.?\d*)" or just match number
        # Previously found lines like "BPM 123.45"
        # Improve regex to avoid partial matches
        $last = $bpmLines[-1].Line
        # Typical output: "[Parsed_bpm @ ...] BPM 120.000000"
        if ($last -match "BPM\s+(\d+\.?\d*)") {
            return [double]$Matches[1]
        }
    }
    return $null
}

function Get-PitchEstimate {
    # Run CDP pitch extract (mode 1) -> view -> parse average?
    # FIX: pitch.exe expects "mode" as first arg, not "pitch".
    # FIX: sndinfo.exe "len" gives reliable duration.
    
    if (-not (Test-Path $pitchExe)) { return $null }
    
    $anaFile = $InputFile + ".frq"
    $txtFile = $InputFile + "_pitch.txt"
    
    # pitch extract mode 1: Pitch + Amp
    # USAGE: pitch extract ...
    # Diagnosis: pitch.exe appears to fail with "Unknown program identification string" 
    # for 'extract', 'mode 1', 'anal', etc. in this environment.
    # Fallback to null to allow other analysis to proceed.
    
    try {
        $args = @("extract", 1, $InputFile, $anaFile)
        $p = Start-Process $pitchExe -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        
        if ($p.ExitCode -ne 0) {
            # Last ditch: try raw mode 1
            $args = @(1, $InputFile, $anaFile)
            $p = Start-Process $pitchExe -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        }
        
        if ($p.ExitCode -ne 0) {
            Write-Warning "Pitch analysis tool failed. Skipping pitch detection."
            return $null 
        }
    }
    catch {
        return $null
    }
    
    $est = $null
    
    if ($p.ExitCode -eq 0) {
        $out = & $viewExe $anaFile
        # Output format lines: "Time   Pitch   Amp"
        # Skip header, grab first valid line with amp > threshold?
        foreach ($line in $out) {
            if ($line -match "^\s*(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)") {
                $amp = [double]$Matches[3]
                if ($amp -gt 0.01) {
                    $est = [double]$Matches[2]
                    break # Take first significant pitch
                }
            }
        }
        Remove-Item $anaFile -ErrorAction SilentlyContinue
    }
    return $est
}

function Get-Info {
    if (Test-Path $sndInfo) {
        # Use 'sndinfo len file' for duration
        $outLines = & $sndInfo "len" $InputFile 2>&1
        $outStr = $outLines -join "`n"
        
        # Output: "DURATION: 0.500000 secs samples 24000"
        # Regex: DURATION:\s*([\d\.]+)
        if ($outStr -match "DURATION:\s*([\d\.]+)") {
            return $Matches[1]
        }
        # Fallback to general info parse
        $out = & $sndInfo $InputFile 2>&1
        $durLine = $out | Select-String "Duration"
        if ($durLine) {
            return ($durLine.Line -replace ".*Duration\s*:\s*", "")
        }
    }
    return "Unknown"
}

# --- Main Analysis ---
Write-Host "Analyzing $InputFile..."

$loudness = Get-Loudness
$lufsI = Get-Lufs
$onsetCount = Get-Onsets
$bpm = Get-Beats
$pitch = Get-PitchEstimate
$dur = Get-Info

# Conversions for density
# dur might be string "0.500...", convert to double
$durVal = if ($dur -ne "Unknown") { [double]$dur } else { 0.0 }
$density = if ($durVal -gt 0) { $onsetCount / $durVal } else { 0 }

# Crest
$crest = $null
if ($loudness.Peak_dB -ne $null -and $loudness.RMS_dB -ne $null) {
    $crest = $loudness.Peak_dB - $loudness.RMS_dB
}

$analysis = [ordered]@{
    tempo_bpm     = $bpm
    pitch_hz      = $pitch
    rms_db        = $loudness.RMS_dB
    peak_db       = $loudness.Peak_dB
    crest_db      = $crest
    lufs_i        = $lufsI
    onset_count   = $onsetCount
    onset_density = $density
    duration      = $dur
}

$warnings = @()
if (-not $bpm) { $warnings += "Could not detect BPM" }
if (-not $pitch) { $warnings += "Could not estimate Pitch" }

if ($onsetCount -eq 0 -and $durVal -gt 0.5) {
    $warnings += "Zero onsets detected for substantial audio duration ($durVal s). Threshold ($OnsetThresholdDb dB) may be too low."
}
if ($onsetCount -gt 0 -and $density -eq 0) {
    $warnings += "Density calculation failed (Duration=$dur, Count=$onsetCount)."
}

if ($TargetLufs) {
    if ($null -eq $analysis.lufs_i) {
        $warnings += "Could not measure LUFS for target validation."
    }
    elseif ($analysis.lufs_i -lt ($TargetLufs - 1.0) -or $analysis.lufs_i -gt ($TargetLufs + 1.0)) {
        $found = $analysis.lufs_i
        $warnings += "Loudness miss: Found $found LUFS, Target $TargetLufs (+/- 1)"
    }
}

$finalData = @{
    analysis = $analysis
    warnings = $warnings
    details  = @{
        filesize = (Get-Item $InputFile).Length
    }
}

# --- Output ---
$baseDetail = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$outDir = Join-Path $PSScriptRoot "output\analysis"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$jsonPath = Join-Path $outDir "$baseDetail.json"
$txtPath = Join-Path $outDir "$baseDetail.txt"

$finalData | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "JSON: $jsonPath"

$report = "Analysis Report: $baseDetail`n"
$report += "----------------------------`n"
$report += "BPM:   $($analysis.tempo_bpm)`n"
$report += "Pitch: $($analysis.pitch_hz) Hz`n"
$report += "RMS:   $($analysis.rms_db) dB`n"
$report += "Peak:  $($analysis.peak_db) dB`n"
$report += "Crest: $(if ($analysis.crest_db) { $analysis.crest_db.ToString("F2") } else { "N/A" }) dB`n"
$report += "LUFS:  $($analysis.lufs_i)`n"
$report += "Onsets: $($analysis.onset_count) (Density: $($analysis.onset_density.ToString("F2"))/s)`n"
$report += "Dur:   $($analysis.duration)`n"
if ($warnings.Count -gt 0) {
    $report += "`nWarnings:`n" + ($warnings -join "`n")
}

$report | Out-File -FilePath $txtPath -Encoding UTF8
Write-Host "Text: $txtPath"

# Cleanup
if (Test-Path "vol_err.txt") { Remove-Item "vol_err.txt" -ErrorAction SilentlyContinue }
if (Test-Path "lufs_err.txt") { Remove-Item "lufs_err.txt" -ErrorAction SilentlyContinue }
if (Test-Path "bpm_err.txt") { Remove-Item "bpm_err.txt" -ErrorAction SilentlyContinue }
if (Test-Path "onset_err.txt") { Remove-Item "onset_err.txt" -ErrorAction SilentlyContinue }
