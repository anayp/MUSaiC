param(
    [Parameter(Mandatory = $false)]
    [string]$Mode = "all",
    
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $false)]
    [string]$ScorePath,

    [Parameter(Mandatory = $false)]
    [string]$MetaPath,
    
    [Parameter(Mandatory = $false)]
    [double]$TargetLufs,
    
    [Parameter(Mandatory = $false)]
    [double]$OnsetThresholdDb = -30,
    
    [Parameter(Mandatory = $false)]
    [double]$OnsetMinDur = 0.05
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig
$cdpBin = $cfg.cdpBin
$ffmpeg = $cfg.ffmpegPath

# Import shared theory logic
$modulePath = Join-Path $PSScriptRoot "musaic-theory.psm1"
if (-not (Test-Path $modulePath)) { throw "Missing musaic-theory.psm1" }
Import-Module $modulePath -Force

$sndInfo = Join-Path $cdpBin "sndinfo.exe"
$pitchExe = Join-Path $cdpBin "pitch.exe"
$viewExe = Join-Path $cdpBin "view.exe"

if (-not (Test-Path $InputFile)) { throw "Input file not found: $InputFile" }
$InputFile = (Resolve-Path $InputFile).Path

# Resolve optional Score/Meta paths early (for tempo/key compare and chord window)
$targetScore = $null
if ($ScorePath) {
    if (Test-Path $ScorePath) { $targetScore = (Resolve-Path $ScorePath).Path }
}
if (-not $targetScore) {
    $cand = $InputFile -replace "\.wav$", ".json"
    if (Test-Path $cand) { $targetScore = $cand }
}

$targetMeta = $null
if ($MetaPath) {
    if (Test-Path $MetaPath) { $targetMeta = (Resolve-Path $MetaPath).Path }
}
if (-not $targetMeta) {
    $metaCand = if ($targetScore) { Join-Path (Split-Path $targetScore) "meta.json" } else { Join-Path (Split-Path $InputFile) "meta.json" }
    if (Test-Path $metaCand) { $targetMeta = $metaCand }
}

$metaData = $null
if ($targetMeta -and (Test-Path $targetMeta)) {
    try {
        $metaData = Get-Content $targetMeta -Raw | ConvertFrom-Json
    }
    catch { 
        Write-Warning "Could not parse meta.json: $_" 
    }
}

# ... (Get-Loudness, Get-Lufs unchanged) ...

function Get-Loudness {
    # ffmpeg volumedetect
    $p = Start-Process $ffmpeg -ArgumentList "-i", $InputFile, "-af", "volumedetect", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "vol_err.txt"
    $err = Get-Content "vol_err.txt"
    $mean = ($err | Select-String "mean_volume") -replace ".*mean_volume:\s*", "" -replace " dB", ""
    $max = ($err | Select-String "max_volume") -replace ".*max_volume:\s*", "" -replace " dB", ""
    
    return @{
        RMS_dB  = if ($mean) { [double]$mean } else { $null }
        Peak_dB = if ($max) { [double]$max } else { $null }
    }
}

function Get-Lufs {
    $p = Start-Process $ffmpeg -ArgumentList "-i", $InputFile, "-af", "ebur128=peak=none", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "lufs_err.txt"
    $err = Get-Content "lufs_err.txt"
    $iVal = $null
    foreach ($line in $err) {
        if ($line -match "I:\s+([-\d\.]+)") {
            $iVal = [double]$Matches[1]
        }
    }
    return $iVal
}

function Get-Onsets {
    $filter = "silencedetect=noise=$($OnsetThresholdDb)dB:d=$($OnsetMinDur)"
    
    $p = Start-Process $ffmpeg -ArgumentList "-i", $InputFile, "-af", $filter, "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "onset_err.txt"
    $err = Get-Content "onset_err.txt"
    
    $onsets = @()
    foreach ($line in $err) {
        if ($line -match "silence_end:\s+([\d\.]+)") {
            $onsets += [double]$Matches[1]
        }
    }
    
    # B1: IOI Tempo Logic & Stats
    $bpmCands = @()
    $ioiStats = @{ Median = 0; IQR = 0; Mean = 0 }
    
    if ($onsets.Count -gt 2) {
        $iois = @()
        for ($i = 0; $i -lt $onsets.Count - 1; $i++) {
            $diff = $onsets[$i + 1] - $onsets[$i]
            if ($diff -gt 0.1 -and $diff -lt 2.0) {
                $iois += $diff
            }
        }
        
        if ($iois.Count -gt 0) {
            $sorted = $iois | Sort-Object
            $count = $sorted.Count
            $mid = $sorted[[Math]::Floor($count / 2)]
            
            # IQR
            $q1 = $sorted[[Math]::Floor($count * 0.25)]
            $q3 = $sorted[[Math]::Floor($count * 0.75)]
            $iqr = $q3 - $q1
            $avg = ($sorted | Measure-Object -Average).Average
            
            $ioiStats.Median = $mid
            $ioiStats.IQR = $iqr
            $ioiStats.Mean = $avg
            
            # Simple median-based BPM
            if ($mid -gt 0) {
                $baseBpm = 60.0 / $mid
                # Confidence based on consistency (low IQR = high conf)
                $consistency = 1.0 - ($iqr / ($mid + 0.001))
                if ($consistency -lt 0) { $consistency = 0.1 }
                if ($consistency -gt 1) { $consistency = 1.0 }

                $bpmCands += @{ Src = "IOI_Median"; BPM = $baseBpm; Conf = $consistency }
                $bpmCands += @{ Src = "IOI_x2"; BPM = $baseBpm * 2; Conf = $consistency * 0.8 }
                $bpmCands += @{ Src = "IOI_x0.5"; BPM = $baseBpm * 0.5; Conf = $consistency * 0.8 }
                $bpmCands += @{ Src = "IOI_x3"; BPM = $baseBpm * 3; Conf = $consistency * 0.7 }
            }
        }
    }

    # Return PSCustomObject to fix Property Access bug
    return [PSCustomObject]@{
        Count         = $onsets.Count
        Times         = $onsets
        BpmCandidates = $bpmCands
        IoiStats      = $ioiStats
        Density       = 0 # To be calculated later with Duration
    }
}

function Get-Beats {
    # ffmpeg bpm
    $p = Start-Process $ffmpeg -ArgumentList "-i", $InputFile, "-af", "bpm", "-f", "null", "-" -NoNewWindow -Wait -PassThru -RedirectStandardError "bpm_err.txt"
    $err = Get-Content "bpm_err.txt"
    $bpmLines = $err | Select-String "BPM"
    
    if ($bpmLines) {
        $last = $bpmLines[-1].Line
        if ($last -match "BPM\s+(\d+\.?\d*)") {
            return [double]$Matches[1]
        }
    }
    return $null
}

function Get-PitchAnalysis {
    if (-not (Test-Path $pitchExe)) { return $null }
    
    $anaFile = $InputFile + ".frq"
    $baseArgs = @("extract", 1, $InputFile, $anaFile)
    
    try {
        $p = Start-Process $pitchExe -ArgumentList $baseArgs -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        if ($p.ExitCode -ne 0) { return $null } # Fail silently
    }
    catch { return $null }

    if (-not (Test-Path $anaFile)) { return $null }

    $out = & $viewExe $anaFile
    # Parse frames (raw)
    $rawFrames = @()
    foreach ($line in $out) {
        if ($line -match "^\s*(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)") {
            $t = [double]$Matches[1]
            $f = [double]$Matches[2]
            $a = [double]$Matches[3]
            if ($a -gt 0.001 -and $f -gt 20) {
                $rawFrames += [PSCustomObject]@{ Time = $t; Freq = $f; Amp = $a }
            }
        }
    }

    $rawFrames = $rawFrames | Sort-Object Time
    $frames = @()
    $hist = @(0) * 12
    $domPitch = 0
    $totalWt = 0
    $midis = @()

    $dtList = @()
    for ($i = 0; $i -lt ($rawFrames.Count - 1); $i++) {
        $dtList += ($rawFrames[$i + 1].Time - $rawFrames[$i].Time)
    }
    $medianDt = 0.0
    if ($dtList.Count -gt 0) {
        $sortedDt = $dtList | Sort-Object
        $medianDt = $sortedDt[[Math]::Floor($sortedDt.Count / 2)]
    }

    for ($i = 0; $i -lt $rawFrames.Count; $i++) {
        $t = $rawFrames[$i].Time
        $f = $rawFrames[$i].Freq
        $a = $rawFrames[$i].Amp
        $dt = if ($i -lt ($rawFrames.Count - 1)) { $rawFrames[$i + 1].Time - $t } else { $medianDt }
        if ($dt -lt 0) { $dt = 0 }

        $midi = 69 + 12 * [Math]::Log($f / 440.0, 2)
        $pc = [int][Math]::Round($midi) % 12

        # Weight = Amp * Frame Duration
        $wt = $a * ($dt + 0.001)

        $hist[$pc] += $wt
        $totalWt += $wt
        $domPitch += $f * $wt
        $midis += $midi

        $frames += [PSCustomObject]@{ Time = $t; Freq = $f; Amp = $a; Midi = $midi; PC = $pc; Weight = $wt }
    }
    Remove-Item $anaFile -ErrorAction SilentlyContinue

    # Finish stats
    if ($totalWt -gt 0) {
        $domPitch /= $totalWt
        # Normalize hist
        for ($i = 0; $i -lt 12; $i++) { $hist[$i] /= $totalWt }
    }
    
    # Stability
    $stability = 0
    if ($midis.Count -gt 1) {
        $avgMidi = ($midis | Measure-Object -Average).Average
        $sumSq = 0
        foreach ($m in $midis) { $sumSq += [Math]::Pow($m - $avgMidi, 2) }
        $stability = [Math]::Sqrt($sumSq / $midis.Count)
    }

    # Pitch Candidates (Top 3 bins)
    $candIndices = 0..11 | Sort-Object { - $hist[$_] } | Select-Object -First 3
    $candidates = $candIndices | ForEach-Object {
        @{ PC = $_; Note = (Get-NoteName $_); Weight = $hist[$_] }
    }

    return @{
        Histogram  = $hist
        Frames     = $frames
        DomPitch   = $domPitch
        Stability  = $stability
        Candidates = $candidates
    }
}

function Get-AudioKey {
    param($Hist)
    if (-not $Hist) { return $null }
    $cands = Get-KeyEstimates -Hist $Hist
    if ($cands.Count -gt 0) {
        return @{
            Estimate   = (Get-NoteName $cands[0].Root) + " " + $cands[0].Type
            Root       = $cands[0].Root
            Type       = $cands[0].Type
            Confidence = if ($cands.Count -gt 1) { $cands[0].Score - $cands[1].Score } else { 1.0 }
            Candidates = $cands | Select-Object -First 3
        }
    }
    return $null
}

function Get-AudioChords {
    param($Frames, $Bpm, $KeyRoot, $KeyType)
    if (-not $Frames) { return @() }
    
    # Window size: 1 bar @ 4/4 = 4 beats. 
    $winSec = (60.0 / (if ($Bpm) { $Bpm } else { 120 })) * 4
    $maxT = $Frames[-1].Time
    
    $chords = @()
    for ($t = 0; $t -lt $maxT; $t += $winSec) {
        $wEnd = $t + $winSec
        $wHist = @(0) * 12
        $wWt = 0
        
        foreach ($fr in $Frames) {
            if ($fr.Time -ge $t -and $fr.Time -lt $wEnd) {
                $wHist[$fr.PC] += $fr.Weight # Use new Weight field
                $wWt += $fr.Weight
            }
        }
        
        if ($wWt -gt 0) {
            # Normalize
            for ($i = 0; $i -lt 12; $i++) { $wHist[$i] /= $wWt }
            
            $best = Get-BestChord -Hist $wHist
            if ($best -and $best.Score -gt 0.5) {
                
                $roman = $null
                # Calculate Roman Numeral if KeyRoot provided
                if ($null -ne $KeyRoot) {
                    $kType = if ($KeyType) { $KeyType } else { "Major" }
                    $roman = Get-RomanNumeral -ChordRoot $best.Root -ChordQuality $best.Quality -KeyRoot $KeyRoot -KeyType $kType
                }

                $chords += [PSCustomObject]@{
                    Start = $t
                    End   = $wEnd
                    Name  = (Get-NoteName $best.Root) + $best.Quality
                    Roman = $roman
                    Score = $best.Score
                }
            }
        }
    }
    return $chords
}

function Get-LoopSeam {
    param($Dur)
    if (-not $Dur) { return $null }
    # Head/Tail window
    $win = 0.2
    if ($Dur -lt ($win * 2)) { return $null }

    try {
        $tailStart = $Dur - $win

        function Get-SegmentStats {
            param($Start, $D, $Lbl)
            $sOut = "seam_$Lbl.txt"
            $argsS = "-ss", $Start, "-t", $D, "-i", $InputFile, "-af", "astats=metadata=1:reset=1", "-f", "null", "-"
            $p = Start-Process $ffmpeg -ArgumentList $argsS -NoNewWindow -Wait -PassThru -RedirectStandardError $sOut
            $txt = Get-Content $sOut -Raw

            $rms = -99.0
            $centroid = $null
            if ($txt -match "RMS_level:\s*([-\d\.]+)") { $rms = [double]$Matches[1] }
            if ($txt -match "SpectralCentroid:\s*([-\d\.]+)") { $centroid = [double]$Matches[1] }

            Remove-Item $sOut -ErrorAction SilentlyContinue
            return @{ Rms = $rms; Centroid = $centroid }
        }

        function Get-F32Samples {
            param($Start, $D)
            $args = @("-ss", $Start, "-t", $D, "-i", $InputFile, "-ac", "1", "-ar", "44100", "-f", "f32le", "-")
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $ffmpeg
            $psi.Arguments = ($args -join " ")
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $p = [System.Diagnostics.Process]::Start($psi)
            $ms = New-Object System.IO.MemoryStream
            $p.StandardOutput.BaseStream.CopyTo($ms)
            $p.WaitForExit()
            $bytes = $ms.ToArray()
            $count = [int]($bytes.Length / 4)
            $floats = New-Object double[] $count
            for ($i = 0; $i -lt $count; $i++) {
                $floats[$i] = [BitConverter]::ToSingle($bytes, $i * 4)
            }
            return $floats
        }

        function Get-BestCorrelation {
            param($A, $B, $MaxOffset)
            if (-not $A -or -not $B) { return $null }
            $bestScore = -1.0
            $bestOffset = 0

            for ($off = - $MaxOffset; $off -le $MaxOffset; $off++) {
                $sum = 0.0
                $sumAA = 0.0
                $sumBB = 0.0
                $count = 0
                for ($i = 0; $i -lt $A.Length; $i++) {
                    $j = $i + $off
                    if ($j -ge 0 -and $j -lt $B.Length) {
                        $va = $A[$i]
                        $vb = $B[$j]
                        $sum += ($va * $vb)
                        $sumAA += ($va * $va)
                        $sumBB += ($vb * $vb)
                        $count++
                    }
                }
                if ($count -gt 0) {
                    $den = [Math]::Sqrt($sumAA * $sumBB)
                    if ($den -gt 0) {
                        $corr = $sum / $den
                        if ($corr -gt $bestScore) {
                            $bestScore = $corr
                            $bestOffset = $off
                        }
                    }
                }
            }
            return @{ Offset = $bestOffset; Score = $bestScore }
        }

        $headStats = Get-SegmentStats 0 $win "head"
        $tailStats = Get-SegmentStats $tailStart $win "tail"

        $rmsDiff = [Math]::Abs($headStats.Rms - $tailStats.Rms)
        $rmsScore = 1.0 / (1.0 + ($rmsDiff * 0.5))

        $centDiff = $null
        $centScore = $null
        if ($null -ne $headStats.Centroid -and $null -ne $tailStats.Centroid) {
            $centDiff = [Math]::Abs($headStats.Centroid - $tailStats.Centroid)
            $centScore = 1.0 / (1.0 + ($centDiff / 1000.0))
        }

        $score = if ($null -ne $centScore) { ($rmsScore + $centScore) / 2.0 } else { $rmsScore }

        # Cross-correlation for best alignment (+/- 50ms)
        $corrWin = 0.1
        $maxOffset = [int]([Math]::Round(0.05 * 44100))
        $headSamples = Get-F32Samples 0 $corrWin
        $tailSamples = Get-F32Samples ($Dur - $corrWin) $corrWin
        $corr = Get-BestCorrelation $headSamples $tailSamples $maxOffset

        $corrScore = $null
        $loopOffsetMs = 0
        if ($corr) {
            $corrScore = [Math]::Max(0.0, [Math]::Min(1.0, (($corr.Score + 1.0) / 2.0)))
            $loopOffsetMs = [Math]::Round(($corr.Offset / 44100.0) * 1000.0, 2)
            $score = ($score + $corrScore) / 2.0
        }

        return @{
            loop_candidate = ($score -gt 0.7)
            loop_score     = $score
            loop_offset_ms = $loopOffsetMs
            rms_head_db    = $headStats.Rms
            rms_tail_db    = $tailStats.Rms
            rms_diff_db    = $rmsDiff
            centroid_head  = $headStats.Centroid
            centroid_tail  = $tailStats.Centroid
            centroid_diff  = $centDiff
            corr_score     = $corrScore
        }
    }
    catch { return $null }
}

function Get-Info {
    if (Test-Path $sndInfo) {
        $outLines = & $sndInfo "len" $InputFile 2>&1
        $outStr = $outLines -join "`n"
        if ($outStr -match "DURATION:\s*([\d\.]+)") {
            return [double]$Matches[1]
        }
    }
    return 0.0
}

# --- Main Analysis ---
Write-Host "Analyzing $InputFile..."

$durVal = Get-Info
$loudness = Get-Loudness
$lufsI = Get-Lufs
$onsets = Get-Onsets
$bpm = Get-Beats
$pitchData = Get-PitchAnalysis


# --- Tempo Merge (ffmpeg + IOI) ---
$tempoCandidates = @()
if ($bpm) {
    $tempoCandidates += [PSCustomObject]@{ Src = "ffmpeg"; BPM = $bpm; Conf = 0.6 }
}



if ($onsets -and $onsets.BpmCandidates) {
    foreach ($c in $onsets.BpmCandidates) {
        $cConf = [double]$c.Conf
        if ($cConf -lt 0) { $cConf = 0 }
        if ($cConf -gt 1) { $cConf = 1 }
        $tempoCandidates += [PSCustomObject]@{ Src = $c.Src; BPM = [double]$c.BPM; Conf = $cConf }
    }
}

$tempoFinal = $bpm
$tempoMethod = if ($bpm) { "ffmpeg" } else { "unknown" }
$tempoConfidence = if ($bpm) { 0.5 } else { 0.0 }

if ($onsets -and $onsets.BpmCandidates -and $onsets.BpmCandidates.Count -gt 0) {
    if ($bpm) {
        $closest = $onsets.BpmCandidates | Sort-Object { [Math]::Abs($_.BPM - $bpm) } | Select-Object -First 1
        $tempoFinal = $closest.BPM
        $tempoMethod = "merged"
        $prox = 1.0 - ([Math]::Abs($closest.BPM - $bpm) / ($bpm + 0.001))
        if ($prox -lt 0) { $prox = 0 }
        if ($prox -gt 1) { $prox = 1 }
        $tempoConfidence = [Math]::Min(1.0, ([double]$closest.Conf + $prox) / 2.0)
    }
    else {
        $best = $onsets.BpmCandidates | Sort-Object Conf -Descending | Select-Object -First 1
        $tempoFinal = $best.BPM
        $tempoMethod = "ioi"
        $tempoConfidence = [Math]::Min(1.0, [double]$best.Conf)
    }
}

# Beat grid (seconds)
$beatGrid = @()
if ($tempoFinal -and $tempoFinal -gt 0 -and $durVal -gt 0) {
    $step = 60.0 / $tempoFinal
    for ($t = 0.0; $t -le $durVal; $t += $step) {
        $beatGrid += [Math]::Round($t, 6)
    }
}

# Key & Chords (Audio)
$keyEst = if ($pitchData) { Get-AudioKey -Hist $pitchData.Histogram } else { $null }

# Pass key root if available for roman numerals
$kRoot = if ($keyEst) { $keyEst.Root } else { $null }
$kType = if ($keyEst) { $keyEst.Type } else { $null }
$chordTempo = if ($metaData -and $metaData.tempo) { [double]$metaData.tempo } elseif ($tempoFinal) { $tempoFinal } elseif ($bpm) { $bpm } else { 120 }
$chords = if ($pitchData) { Get-AudioChords -Frames $pitchData.Frames -Bpm $chordTempo -KeyRoot $kRoot -KeyType $kType } else { @() }
$loopSeam = Get-LoopSeam -Dur $durVal

# Conversions for Density
# Access property via hashtable key or object property depending on return
$oCount = $onsets.Count
if ($null -eq $oCount) { $oCount = 0 }

$density = if ($durVal -gt 0) { $oCount / $durVal } else { 0 }

# Update density in onsets object
$onsets.Density = $density

# Crest
$crest = $null
if ($loudness.Peak_dB -ne $null -and $loudness.RMS_dB -ne $null) {
    $crest = $loudness.Peak_dB - $loudness.RMS_dB
}



# --- Theory Merge (B6) ---
$theoryData = $null
if ($targetScore -and (Test-Path $targetScore)) {
    Write-Host "Merging Theory from: $targetScore"
    
    # Use outputDir for temp theory analysis
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($targetScore)
    $anaDir = Join-Path $cfg.outputDir "analysis"
    if (-not (Test-Path $anaDir)) { New-Item -ItemType Directory -Force -Path $anaDir | Out-Null }
    
    $theoryJson = Join-Path $anaDir "${baseName}_theory.json"
    $theoryTxt = Join-Path $anaDir "${baseName}_theory.txt"
    $theoryScript = Join-Path $PSScriptRoot "cdp-theory.ps1"
    
    if (Test-Path $theoryScript) {
        $procArgs = @("-File", $theoryScript, "-ScorePath", $targetScore, "-OutJson", $theoryJson, "-OutTxt", $theoryTxt)
        if ($targetMeta) { $procArgs += @("-MetaPath", $targetMeta) }
        $p = Start-Process "pwsh" -ArgumentList $procArgs -NoNewWindow -Wait -PassThru
        if ($p.ExitCode -eq 0 -and (Test-Path $theoryJson)) {
            $theoryData = Get-Content $theoryJson -Raw | ConvertFrom-Json
            
            # Auto-cleanup theory artifacts as they are merged into the main analysis JSON
            # Unless user wants debugging. keeping for now? No, instruction says remove.
            Remove-Item $theoryJson -ErrorAction SilentlyContinue
            Remove-Item $theoryTxt -ErrorAction SilentlyContinue
        }
    }
}



$analysis = [ordered]@{
    tempo_bpm        = $tempoFinal
    tempo_method     = $tempoMethod
    tempo_confidence = $tempoConfidence
    tempo_candidates = $tempoCandidates
    tempo_stats      = $onsets.IoiStats
    beat_grid        = $beatGrid

    pitch_analysis   = @{
        dominant_hz = if ($pitchData) { $pitchData.DomPitch } else { $null }
        stability   = if ($pitchData) { $pitchData.Stability } else { $null }
        histogram   = if ($pitchData) { $pitchData.Histogram } else { $null }
        candidates  = if ($pitchData) { $pitchData.Candidates } else { $null }
    }
    
    key_estimate     = $keyEst
    chords_audio     = $chords
    loop_analysis    = $loopSeam
    
    theory           = $theoryData
    
    rms_db           = $loudness.RMS_dB
    peak_db          = $loudness.Peak_dB
    crest_db         = $crest
    lufs_i           = $lufsI
    
    onsets           = @{
        count   = $onsets.Count
        density = $density
        times   = $onsets.Times
    }
    duration         = $durVal
}


$warnings = @()
if (-not $bpm) { $warnings += "Could not detect BPM (ffmpeg)" }
if (-not $tempoFinal) { $warnings += "Could not determine final tempo." }
if (-not $pitchData) { $warnings += "Could not estimate Pitch" }

if ($oCount -eq 0 -and $durVal -gt 0.5) {
    if ($loudness.RMS_dB -gt -50) {
        $warnings += "Zero onsets detected for substantial audio duration ($durVal s) but RMS is high ($($loudness.RMS_dB)). Threshold ($OnsetThresholdDb dB) may be too low."
    }
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

# Meta Consistency Check
if ($metaData) {
    if ($metaData.PSObject.Properties.Match("tempo").Count -gt 0 -and $metaData.tempo -and $tempoFinal) {
        $metaTempo = [double]$metaData.tempo
        $diff = [Math]::Abs($tempoFinal - $metaTempo) / ($metaTempo + 0.001)
        if ($diff -gt 0.03) {
            $warnings += "Tempo Mismatch: Audio($tempoFinal) vs Meta($metaTempo)"
        }
    }
    elseif ($metaData.PSObject.Properties.Match("tempo").Count -gt 0 -and $metaData.tempo -and -not $tempoFinal) {
        $warnings += "Tempo Mismatch: Meta tempo present but audio tempo missing."
    }

    if ($metaData.PSObject.Properties.Match("key").Count -gt 0 -and $metaData.key -and $keyEst) {
        $mKey = $metaData.key.ToString().Trim()
        $audioKey = (Get-NoteName $keyEst.Root)
        if ($mKey -and ($mKey.ToUpperInvariant() -ne $audioKey.ToUpperInvariant())) {
            $warnings += "Key Mismatch: Audio($audioKey) vs Meta($mKey)"
        }
    }

    if ($metaData.PSObject.Properties.Match("scale").Count -gt 0 -and $metaData.scale -and $keyEst) {
        $mScale = $metaData.scale.ToString().Trim().ToLowerInvariant()
        $audioScale = $keyEst.Type.ToLowerInvariant()
        if (($mScale -eq "major" -or $mScale -eq "minor") -and ($mScale -ne $audioScale)) {
            $warnings += "Scale Mismatch: Audio($audioScale) vs Meta($mScale)"
        }
    }
}


# Theory Consistency Check
if ($theoryData) {
    # Check Key
    if ($keyEst -and $theoryData.key_root) {
        $audioKey = $keyEst.Estimate
        $theoryKey = $theoryData.key
        if ($audioKey -notmatch $theoryData.key_root) {
            $warnings += "Key Mismatch: Audio($audioKey) vs Score($theoryKey)"
        }
    }
}

$finalData = @{
    analysis = $analysis
    warnings = $warnings
    details  = @{
        filesize = (Get-Item $InputFile).Length
        score    = $targetScore
        meta     = $targetMeta
    }
}

# --- Output ---
$baseDetail = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
# Default output directory from config
$defaultOut = Join-Path $cfg.outputDir "analysis"
if (-not (Test-Path $defaultOut)) { New-Item -ItemType Directory -Force -Path $defaultOut | Out-Null }

$jsonPath = Join-Path $defaultOut "$baseDetail.json"
$txtPath = Join-Path $defaultOut "$baseDetail.txt"

$finalData | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "JSON: $jsonPath"

$report = "Analysis Report: $baseDetail`n"
$report += "----------------------------`n"
$report += "BPM:   $($analysis.tempo_bpm)`n"
if ($pitchData -and $keyEst) {
    if ($keyEst.Estimate) { $report += "Key:   $($keyEst.Estimate) " }
    if ($keyEst.Confidence) { $report += "(Conf: $($keyEst.Confidence.ToString('F2')))`n" } else { $report += "`n" }
    if ($pitchData.DomPitch) { $report += "Pitch: $($pitchData.DomPitch.ToString('F1')) Hz`n" }
}
$report += "RMS:   $($analysis.rms_db) dB`n"
$report += "LUFS:  $($analysis.lufs_i)`n"
$report += "Dur:   $($analysis.duration)`n"
if ($loopSeam -and $loopSeam.Score) {
    $report += "Loop:  Seam Score $($loopSeam.Score.ToString('F2')) (Loop=$($loopSeam.IsLoop))`n"
}
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
