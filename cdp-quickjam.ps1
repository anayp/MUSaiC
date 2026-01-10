param(
    [string]$PresetName = "sine440",
    [switch]$Interactive,
    [switch]$Play,
    [switch]$ToMp3
)

# Simple CDP8 CLI jam: pick a preset, render with synth.exe, optionally play or encode to MP3.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot

# --- Configuration ---
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig
$cdpBin = $cfg.cdpBin
$synthExe = Join-Path $cdpBin "synth.exe"
$paplayExe = Join-Path $cdpBin "paplay.exe"
$ffmpeg = $cfg.ffmpegPath

if (-not (Test-Path $synthExe)) {
    throw "Missing synth.exe at $synthExe (is CDPR8 extracted beside this script?)"
}

function Test-Command {
    param([string]$Name)
    if ($Name -eq "ffmpeg") {
        if ($script:ffmpeg -eq "ffmpeg") {
            try { Get-Command "ffmpeg" -ErrorAction Stop | Out-Null; return $true } catch { return $false }
        }
        else {
            return (Test-Path $script:ffmpeg)
        }
    }
    try { Get-Command $Name -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

$presets = @(
    [pscustomobject]@{
        Name        = "sine440"
        Waveform    = "sine"
        Freq        = 440
        Amp         = 0.8
        Dur         = 2.5
        SR          = 48000
        Ch          = 2
        Description = "Warm sine at concert A"
    },
    [pscustomobject]@{
        Name        = "saw220"
        Waveform    = "saw"
        Freq        = 220
        Amp         = 0.7
        Dur         = 2.5
        SR          = 48000
        Ch          = 2
        Description = "Bright saw at A2"
    },
    [pscustomobject]@{
        Name        = "square330"
        Waveform    = "square"
        Freq        = 330
        Amp         = 0.6
        Dur         = 2.0
        SR          = 48000
        Ch          = 2
        Description = "Hollow square at E4"
    }
)

if ([string]::IsNullOrWhiteSpace($PresetName)) {
    $PresetName = "sine440"
}
$targetPreset = $PresetName
Write-Host ("Preset param after fallback: '{0}'" -f $targetPreset)

if ($Interactive) {
    Write-Host "Pick a preset:"
    for ($i = 0; $i -lt $presets.Count; $i++) {
        $p = $presets[$i]
        Write-Host ("{0}) {1} - {2}" -f ($i + 1), $p.Name, $p.Description)
    }
    $choice = Read-Host "Enter number (default 1)"
    $choiceVal = 1
    if ([int]::TryParse($choice, [ref]$choiceParsed)) {
        $choiceVal = $choiceParsed
    }
    $idx = [Math]::Max(1, [int]$choiceVal)
    $idx = [Math]::Min($idx, $presets.Count)
    $PresetName = $presets[$idx - 1].Name
    $targetPreset = $PresetName
}

$preset = $null
foreach ($p in $presets) {
    if ($p.Name -ieq $targetPreset) {
        $preset = $p
        break
    }
}
if (-not $preset) {
    $names = $presets.Name -join ", "
    Write-Host ("Debug: preset variable before throw = '{0}' (type {1})" -f $targetPreset, ($targetPreset.GetType().FullName))
    throw "Unknown preset '$targetPreset'. Available: $names"
}
Write-Host ("Selected preset value: {0} (type {1})" -f $preset, ($preset.GetType().FullName))
Write-Host ("Preset: {0} - {1}" -f $preset.Name, $preset.Description)

$modeMap = @{
    sine   = 1
    square = 2
    saw    = 3
    ramp   = 4
}

$waveform = $preset.Waveform.ToLowerInvariant()
$waveMode = $modeMap[$waveform]
$sr = [int]$preset.SR
$ch = [int]$preset.Ch
$dur = [double]$preset.Dur
$freq = [double]$preset.Freq
$amp = [double]$preset.Amp

$outDir = $cfg.outputDir
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
$wavPath = Join-Path $outDir ("cdp-{0}.wav" -f $preset.Name)
$mp3Path = Join-Path $outDir ("cdp-{0}.mp3" -f $preset.Name)

if (Test-Path $wavPath) { Remove-Item -Force -Path $wavPath }
if (Test-Path $mp3Path) { Remove-Item -Force -Path $mp3Path }

$args = @(
    "wave",
    $waveMode,
    $wavPath,
    $sr,
    $ch,
    $dur,
    $freq,
    "-a$amp"
)

Write-Host "Rendering preset '$($preset.Name)': $($preset.Description)"
Write-Host ("Command: {0} {1}" -f $synthExe, ($args -join ' '))
& $synthExe @args
if ($LASTEXITCODE -ne 0) {
    throw "synth.exe failed with exit code $LASTEXITCODE"
}
Write-Host "Wrote WAV: $wavPath"

$madeMp3 = $false
if ($ToMp3 -and (Test-Command ffmpeg)) {
    $ffArgs = @("-y", "-i", $wavPath, "-codec:a", "libmp3lame", "-qscale:a", "2", $mp3Path)
    Write-Host "Encoding MP3 with ffmpeg..."
    if ($ffmpeg -eq "ffmpeg") {
        & ffmpeg @ffArgs | Out-Null
    }
    else {
        & $ffmpeg @ffArgs | Out-Null
    }
    if ($LASTEXITCODE -eq 0 -and (Test-Path $mp3Path)) {
        $madeMp3 = $true
        Write-Host "Wrote MP3: $mp3Path"
    }
    else {
        Write-Warning "ffmpeg failed to encode MP3; WAV is still available."
    }
}

if ($Play) {
    $playTarget = $wavPath
    if ($madeMp3) { $playTarget = $mp3Path }

    if (Test-Path $paplayExe) {
        Write-Host "Playing via paplay..."
        & $paplayExe $playTarget
    }
    elseif (Test-Command ffplay) {
        Write-Host "Playing via ffplay..."
        & ffplay -nodisp -autoexit $playTarget
    }
    else {
        Write-Warning "No player found (paplay/ffplay). Use your preferred player to audition: $playTarget"
    }
}

Write-Host ""
Write-Host "Description:"
Write-Host ("- Preset: {0} ({1})" -f $preset.Name, $preset.Description)
Write-Host ("- Waveform: {0}, Freq: {1} Hz, Dur: {2}s, Amp: {3}, SR: {4}, Channels: {5}" -f $waveform, $freq, $dur, $amp, $sr, $ch)
$fileNote = "- Files: WAV=$wavPath"
if ($madeMp3) { $fileNote += "; MP3=$mp3Path" }
Write-Host $fileNote
