param(
    [string]$OutWav, # Optional override
    [switch]$ToMp3,
    [switch]$Play
)

# Build a short motif from multiple CDP synth notes, concatenate via ffmpeg, optional MP3 + playback.
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

# Resolve ffmpeg from config
$ffmpeg = $cfg.ffmpegPath
function Invoke-Ffmpeg {
    param($ArgsList)
    if ($script:ffmpeg -eq "ffmpeg") {
        & "ffmpeg" @ArgsList
    }
    else {
        & $script:ffmpeg @ArgsList
    }
}

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

$modeMap = @{
    sine   = 1
    square = 2
    saw    = 3
    ramp   = 4
}

# Simple motif; tweak durations/amps as desired.
$notes = @(
    [pscustomobject]@{ Name = "A4"; Waveform = "sine"; Freq = 440; Dur = 0.5; Amp = 0.75 },
    [pscustomobject]@{ Name = "C5"; Waveform = "saw"; Freq = 523.25; Dur = 0.6; Amp = 0.70 },
    [pscustomobject]@{ Name = "E5"; Waveform = "square"; Freq = 659.25; Dur = 0.55; Amp = 0.60 },
    [pscustomobject]@{ Name = "A5"; Waveform = "sine"; Freq = 880; Dur = 0.75; Amp = 0.80 },
    [pscustomobject]@{ Name = "E5"; Waveform = "ramp"; Freq = 659.25; Dur = 0.45; Amp = 0.55 },
    [pscustomobject]@{ Name = "C5"; Waveform = "saw"; Freq = 523.25; Dur = 0.65; Amp = 0.65 },
    [pscustomobject]@{ Name = "A4"; Waveform = "sine"; Freq = 440; Dur = 0.8; Amp = 0.75 }
)

$sr = 48000
$ch = 2

if ([string]::IsNullOrWhiteSpace($OutWav)) {
    $OutWav = Join-Path $cfg.outputDir "cdp-melody.wav"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutWav)) {
    $OutWav = Join-Path $root $OutWav
}

$outDir = Split-Path $OutWav
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$outMp3 = [System.IO.Path]::ChangeExtension($OutWav, ".mp3")

$tmpDir = Join-Path $cfg.outputDir "melody_tmp"
if (Test-Path $tmpDir) { Remove-Item -Recurse -Force $tmpDir }
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$segmentPaths = @()
$idx = 0
foreach ($note in $notes) {
    $idx++
    $waveform = $note.Waveform.ToLowerInvariant()
    if (-not $modeMap.ContainsKey($waveform)) {
        throw "Unsupported waveform '$waveform' in note $idx"
    }
    $waveMode = $modeMap[$waveform]
    $dur = [double]$note.Dur
    $freq = [double]$note.Freq
    $amp = [double]$note.Amp

    $segPath = Join-Path $tmpDir ("seg-{0:00}-{1}.wav" -f $idx, $note.Name)
    $segmentPaths += $segPath

    $procArgs = @(
        "wave",
        $waveMode,
        $segPath,
        $sr,
        $ch,
        $dur,
        $freq,
        "-a$amp"
    )

    Write-Host ("Rendering note {0}: {1} {2}Hz dur {3}s amp {4}" -f $idx, $waveform, $freq, $dur, $amp)
    & $synthExe @procArgs
    if ($LASTEXITCODE -ne 0) {
        throw "synth.exe failed on note $idx with exit code $LASTEXITCODE"
    }
}

# Build concat list for ffmpeg.
$listFile = Join-Path $tmpDir "list.txt"
$segmentPaths | ForEach-Object { "file '$($_)'" } | Set-Content -Path $listFile -Encoding ASCII

if (Test-Path $OutWav) { Remove-Item -Force -Path $OutWav }
Write-Host "Concatenating segments -> $OutWav"

$concatArgs = @("-y", "-f", "concat", "-safe", "0", "-i", $listFile, "-c", "copy", $OutWav)
if ($script:ffmpeg -eq "ffmpeg") {
    $p = Start-Process "ffmpeg" -ArgumentList $concatArgs -NoNewWindow -Wait -PassThru
}
else {
    $p = Start-Process $script:ffmpeg -ArgumentList $concatArgs -NoNewWindow -Wait -PassThru
}

if ($p.ExitCode -ne 0) {
    throw "ffmpeg concat failed with exit code $($p.ExitCode)"
}

$madeMp3 = $false
if ($ToMp3 -and (Test-Command ffmpeg)) {
    Write-Host "Encoding MP3 -> $outMp3"
    $mp3Args = @("-y", "-i", $OutWav, "-codec:a", "libmp3lame", "-qscale:a", "2", $outMp3)
    Invoke-Ffmpeg -ArgsList $mp3Args | Out-Null
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outMp3)) {
        $madeMp3 = $true
        Write-Host "MP3 ready: $outMp3"
    }
    else {
        Write-Warning "ffmpeg failed to encode MP3."
    }
}

if ($Play) {
    $playTarget = $OutWav
    if ($madeMp3) { $playTarget = $outMp3 }

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
Write-Host "Melody built."
Write-Host ("- Segments: {0}" -f ($segmentPaths.Count))
Write-Host ("- WAV: {0}" -f $OutWav)
if ($madeMp3) { Write-Host ("- MP3: {0}" -f $outMp3) }
