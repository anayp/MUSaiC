param(
    [string]$ScorePath = ".\\examples\\effects_demo.json",
    [string]$OutWav, # Optional override
    [string]$OutMp3, # Optional mp3 output
    [string]$MetaPath, # Optional path to meta.json
    [double]$MasterLufs, # Optional LUFS target
    [double]$MasterLimitDb, # Optional TP Limit
    [switch]$MasterGlue, # Optional Bus Compressor
    [switch]$Play,
    [switch]$KeepTemp, # Sprint 7: Default cleans up notes
    [switch]$Preview, # Sprint 26: Low-res preview
    [ValidateSet(16, 24, 32)]
    [int]$PreviewBitDepth = 16, # Sprint 27
    [ValidateRange(8000, 192000)]
    [int]$PreviewSampleRate = 22050 # Sprint 27
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    # --- Configuration ---
    $configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
    if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
    . $configHelper
    $cfg = Get-MusaicConfig

    # Validation of ffmpeg
    $ffmpeg = $cfg.ffmpegPath
    if ($ffmpeg -eq "ffmpeg") {
        if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
            throw "ffmpeg is not in your PATH. Please install ffmpeg or configure it in musaic.config.json."
        }
    }
    else {
        if (-not (Test-Path $ffmpeg)) {
            throw "Configured ffmpeg not found at: $ffmpeg"
        }
    }

    $cdpBin = $cfg.cdpBin
    $synthExe = Join-Path $cdpBin "synth.exe"
    $reverbExe = Join-Path $cdpBin "reverb.exe"
    $modifyExe = Join-Path $cdpBin "modify.exe"

    $workDir = Join-Path $cfg.outputDir "tmp_sequencer"
    $outDir = $cfg.outputDir

    if (-not (Test-Path $synthExe)) { throw "Missing synth.exe at $synthExe" }

    # --- Cleanup & Setup ---
    if (Test-Path $workDir) { Remove-Item -Recurse -Force $workDir }
    New-Item -ItemType Directory -Force -Path $workDir | Out-Null
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

    # --- Load Score ---
    Write-Host "Loading score: $ScorePath"
    if (-not (Test-Path $ScorePath)) {
        throw "Score file not found: $ScorePath"
    }
    $score = Get-Content -Raw -Path $ScorePath | ConvertFrom-Json

    # --- Load Metadata (Optional) ---
    $meta = $null
    if ($MetaPath) {
        if (Test-Path $MetaPath) {
            Write-Host "Loading Metadata: $MetaPath" -ForegroundColor Cyan
            $meta = Get-Content -Raw $MetaPath | ConvertFrom-Json
        }
        else {
            Write-Warning "Metadata file not found: $MetaPath"
        }
    }

    # --- Helper: Safe Property Access ---
    function Get-Prop {
        param($Obj, $Name, $Default)
        if ($null -eq $Obj) { return $Default }
        foreach ($p in $Obj.PSObject.Properties) {
            if ($p.Name -eq $Name) { return $p.Value }
        }
        return $Default
    }

    # --- Output Pathing ---
    if (-not $OutWav) {
        $projName = Get-Prop $score "project" "project"
        $safeProj = $projName -replace '[^a-zA-Z0-9_\-]', '_'
        
        if ($Preview) {
            $OutWav = Join-Path $outDir "${safeProj}_preview.wav"
        }
        else {
            $OutWav = Join-Path $outDir "${safeProj}-master.wav"
        }
    }
    $OutWav = [System.IO.Path]::GetFullPath($OutWav)
    Write-Host "Target Output: $OutWav"

    # --- Timing Setup ---
    $defUnits = "seconds"
    $defTempo = 120
    
    if ($meta) {
        $defUnits = Get-Prop $meta "timeUnits" "seconds"
        $defTempo = Get-Prop $meta "tempo" 120
    }

    $timeUnits = Get-Prop $score "timeUnits" $defUnits
    $tempo = Get-Prop $score "tempo" $defTempo
    $beatSec = 60.0 / $tempo

    function Get-Seconds {
        param($Val)
        if ($timeUnits -eq "beats") {
            return [double]$Val * $beatSec
        }
        return [double]$Val
    }

    Write-Host "Timing Mode: $timeUnits (Tempo: $tempo BPM)"
    
    # --- Validation ---
    function Validate-Score {
        param($S)
        if (-not $S.tracks) { throw "Score missing 'tracks' array." }
        foreach ($t in $S.tracks) {
            if (-not $t.name) { throw "Track missing 'name'." }
            if (-not $t.type) { throw "Track '$($t.name)' missing 'type'." }
            
            if ($t.type -eq "synth") {
                if (-not $t.events) { throw "Synth track '$($t.name)' missing 'events'." }
                foreach ($e in $t.events) {
                    if ($e.PSObject.Properties['time'] -eq $null) { throw "Event in '$($t.name)' missing 'time'." }
                    if ($e.PSObject.Properties['dur'] -eq $null) { throw "Event in '$($t.name)' missing 'dur'." }
                    if ($e.PSObject.Properties['pitch'] -eq $null) { throw "Event in '$($t.name)' missing 'pitch'." }
                }
            }
        }
    }
    Validate-Score -S $score

    # --- Helper Functions ---
    function Run-Synth {
        param($Output, $Waveform, $Duration, $Freq, $Amp, $SampleRate = 48000)
    
        $modeMap = @{ sine = 1; square = 2; saw = 3; ramp = 4 }
        $mode = $modeMap[$Waveform]
        if (-not $mode) { $mode = 1 } 

        $args = @(
            "wave", $mode, $Output, $SampleRate, 1, 
            $Duration, $Freq
        )
        $p = Start-Process -FilePath $synthExe -ArgumentList $args -NoNewWindow -PassThru -Wait
        if ($p.ExitCode -ne 0) { throw "Synth failed" }
    }

    function Apply-Effect {
        param(
            [string]$InputFile,
            [string]$OutputFile,
            [object]$Effect,
            [string]$WorkDir,
            [string]$TrackName,
            [double]$TrackDurationSec
        )

        $fxType = Get-Prop $Effect "type" "unknown"

        if ($fxType -eq "reverb") {
            if (-not (Test-Path $reverbExe)) { throw "Missing reverb.exe at $reverbExe needed for effect" }

            $rvbtime = Get-Prop $Effect "room_size" 1.0
            $mix = Get-Prop $Effect "mix" 0.5
            $rgain = 0.6
            $absorb = 0.5
            $lpfreq = 4000
            $tail = 1.0

            $args = @($InputFile, $OutputFile, $rgain, $mix, $rvbtime, $absorb, $lpfreq, $tail)
            $p = Start-Process -FilePath $reverbExe -ArgumentList $args -NoNewWindow -PassThru -Wait
            if ($p.ExitCode -ne 0) { throw "Effect reverb failed with code $($p.ExitCode)" }
        }
        elseif ($fxType -eq "pitch") {
            if (-not (Test-Path $modifyExe)) { throw "Missing modify.exe at $modifyExe needed for effect" }
            $semitones = Get-Prop $Effect "semitones" 0
            $ratio = [Math]::Pow(2, $semitones / 12)
            $args = @("speed", 1, $InputFile, $OutputFile, $ratio)
            $p = Start-Process -FilePath $modifyExe -ArgumentList $args -NoNewWindow -PassThru -Wait
            if ($p.ExitCode -ne 0) { throw "Effect pitch (modify speed) failed with code $($p.ExitCode)" }
        }
        elseif ($fxType -eq "tremolo") {
            $depth = Get-Prop $Effect "depth" 0.85
            $rateHz = Get-Prop $Effect "rateHz" $null
            $wubsPerBeat = Get-Prop $Effect "wubsPerBeat" $null
            $rateMap = Get-Prop $Effect "rateMap" $null

            if ($null -ne $wubsPerBeat) {
                $rateHz = [double]$wubsPerBeat * ($tempo / 60.0)
            }

            if ($rateMap) {
                if ($TrackDurationSec -le 0) { throw "Tremolo rateMap requires a valid track duration." }
                $sortedMap = $rateMap | Sort-Object time
                $segFiles = @()
                $segFxFiles = @()

                for ($idx = 0; $idx -lt $sortedMap.Count; $idx++) {
                    $entry = $sortedMap[$idx]
                    $startVal = Get-Prop $entry "time" 0.0
                    $startSec = Get-Seconds $startVal
                    $endSec = $TrackDurationSec
                    if ($idx -lt ($sortedMap.Count - 1)) {
                        $endVal = Get-Prop $sortedMap[$idx + 1] "time" $TrackDurationSec
                        $endSec = Get-Seconds $endVal
                    }
                    $segDur = [double]$endSec - [double]$startSec
                    if ($segDur -le 0) { continue }
                    $entryRate = Get-Prop $entry "rateHz" $null
                    $entryWubs = Get-Prop $entry "wubsPerBeat" $null
                    if ($null -ne $entryWubs) {
                        $entryRate = [double]$entryWubs * ($tempo / 60.0)
                    }
                    if ($null -eq $entryRate -or $entryRate -le 0) {
                        throw "Tremolo rateMap entry must include rateHz or wubsPerBeat."
                    }
                    $segFile = Join-Path $WorkDir "track_${TrackName}_seg$idx.wav"
                    $segFx = Join-Path $WorkDir "track_${TrackName}_seg${idx}_fx.wav"
                    $cutArgs = @("-y", "-i", $InputFile, "-ss", $startSec, "-t", $segDur, $segFile)
                    $pCut = Start-Process -FilePath $ffmpeg -ArgumentList $cutArgs -NoNewWindow -PassThru -Wait
                    if ($pCut.ExitCode -ne 0) { throw "Tremolo segment cut failed for $TrackName" }
                    $rateStr = ([double]$entryRate).ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
                    $depthStr = ([double]$depth).ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
                    $fxArgs = @("-y", "-i", $segFile, "-filter:a", "tremolo=f=${rateStr}:d=${depthStr}", $segFx)
                    $pFx = Start-Process -FilePath $ffmpeg -ArgumentList $fxArgs -NoNewWindow -PassThru -Wait
                    if ($pFx.ExitCode -ne 0) { throw "Tremolo effect failed for $TrackName" }
                    $segFiles += $segFile
                    $segFxFiles += $segFx
                }
                if ($segFxFiles.Count -eq 0) { throw "Tremolo rateMap produced no segments." }
                if ($segFxFiles.Count -eq 1) {
                    Move-Item -Force $segFxFiles[0] $OutputFile
                }
                else {
                    $listFile = Join-Path $WorkDir "track_${TrackName}_tremolo_concat.txt"
                    $listLines = $segFxFiles | ForEach-Object {
                        $safePath = $_ -replace "'", "''"
                        "file '$safePath'"
                    }
                    Set-Content -Path $listFile -Value $listLines -Encoding ascii
                    $concatArgs = @("-y", "-f", "concat", "-safe", "0", "-i", $listFile, "-c:a", "pcm_s16le", $OutputFile)
                    $pCat = Start-Process -FilePath $ffmpeg -ArgumentList $concatArgs -NoNewWindow -PassThru -Wait
                    if ($pCat.ExitCode -ne 0) { throw "Tremolo concat failed for $TrackName" }
                }
                if (-not $KeepTemp) {
                    foreach ($f in $segFiles) { Remove-Item $f -ErrorAction SilentlyContinue }
                    foreach ($f in $segFxFiles) { Remove-Item $f -ErrorAction SilentlyContinue }
                    Remove-Item $listFile -ErrorAction SilentlyContinue
                }
            }
            else {
                if ($null -eq $rateHz -or $rateHz -le 0) { throw "Tremolo requires rateHz or wubsPerBeat." }
                $rateStr = ([double]$rateHz).ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
                $depthStr = ([double]$depth).ToString("0.000", [System.Globalization.CultureInfo]::InvariantCulture)
                $args = @("-y", "-i", $InputFile, "-filter:a", "tremolo=f=${rateStr}:d=${depthStr}", $OutputFile)
                $p = Start-Process -FilePath $ffmpeg -ArgumentList $args -NoNewWindow -PassThru -Wait
                if ($p.ExitCode -ne 0) { throw "Effect tremolo failed with code $($p.ExitCode)" }
            }
        }
        else {
            throw "Effect '$fxType' is not supported."
        }
    }


    function Get-Channels {
        param($File)
        $probeFile = Join-Path $workDir "probe.txt"
        try { $p = & $ffmpeg "-i" $File 2> $probeFile } catch {}
        if (Test-Path $probeFile) {
            $info = Get-Content $probeFile -Raw
            if ($info -match "mono") { return 1 }
            if ($info -match "stereo") { return 2 }
            if ($info -match "1 channels") { return 1 }
        }
        return 2 
    }

    function Get-DurationSec {
        param($File)
        $probeFile = Join-Path $workDir "probe_duration.txt"
        try { & $ffmpeg "-i" $File 2> $probeFile | Out-Null } catch {}
        if (Test-Path $probeFile) {
            $info = Get-Content $probeFile -Raw
            if ($info -match "Duration:\s+(\d+):(\d+):(\d+)\.(\d+)") {
                $h = [int]$Matches[1]
                $m = [int]$Matches[2]
                $s = [int]$Matches[3]
                $frac = [double]("0." + $Matches[4])
                return ($h * 3600) + ($m * 60) + $s + $frac
            }
        }
        return 0.0
    }

    function Apply-Mixer {
        param($InputFile, $TrackName, $GainDb, $Pan, $WorkDir)
        $mixOut = Join-Path $WorkDir "track_${TrackName}_mix.wav"
        $pVal = ($Pan + 1.0) / 2.0
        $vLeft = 1.0 - $pVal
        $vRight = $pVal
        $sL = $vLeft.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $sR = $vRight.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $gStr = $GainDb.ToString("0.00", [System.Globalization.CultureInfo]::InvariantCulture)
        $ch = Get-Channels $InputFile
        $filters = @("volume=${gStr}dB")
        if ($Pan -ne 0.0 -and $null -ne $Pan) {
            if ($ch -eq 1) { $filters += "pan=stereo|c0=c0*$sL|c1=c0*$sR" }
            else { $filters += "pan=stereo|c0=c0*$sL|c1=c1*$sR" }
        }
        $filterStr = $filters -join ","
        $argsMix = @("-y", "-i", $InputFile, "-filter_complex", $filterStr, $mixOut)
        $pMix = Start-Process -FilePath $ffmpeg -ArgumentList $argsMix -NoNewWindow -PassThru -Wait
        if ($pMix.ExitCode -ne 0) {
            Write-Warning "Mixer failed for track $TrackName"
            return $InputFile
        }
        else { return $mixOut }
    }

    # --- Sequencer Logic ---
    $trackFiles = @()

    foreach ($track in $score.tracks) {
        Write-Host "Processing Track: $($track.name) ($($track.type))"
        $trackEvents = $track.events | Sort-Object time
        $trackStem = Join-Path $workDir "track_$($track.name).wav"
    
        if ($track.type -eq "synth") {
            $eventFiles = @()
            $i = 0
            foreach ($evt in $trackEvents) {
                $noteFile = Join-Path $workDir "t$($track.name)_n$i.wav"
                $durVal = Get-Prop $evt "dur" 1.0
                $dur = Get-Seconds $durVal
                $pitch = Get-Prop $evt "pitch" 60
                $freq = 440 * [Math]::Pow(2, ($pitch - 69) / 12)
                $amp = Get-Prop $track "amp" 0.8
                $wave = Get-Prop $track "waveform" "sine"
                Run-Synth -Output $noteFile -Waveform $wave -Duration $dur -Freq $freq -Amp $amp
                $timeVal = Get-Prop $evt "time" 0.0
                $timeSec = Get-Seconds $timeVal
                $delayMs = [int]($timeSec * 1000)
                $eventFiles += @{ File = $noteFile; Delay = $delayMs }
                $i++
            }

            if ($eventFiles.Count -gt 0) {
                $ffmpegArgs = @("-y")
                $filterComplex = ""
                $inputs = ""
                for ($k = 0; $k -lt $eventFiles.Count; $k++) {
                    $ffmpegArgs += "-i", $eventFiles[$k].File
                    $filterComplex += "[$k]adelay=$($eventFiles[$k].Delay)|$($eventFiles[$k].Delay)[s$k];"
                    $inputs += "[s$k]"
                }
                $filterComplex += "${inputs}amix=inputs=$($eventFiles.Count):duration=longest[out]"
                $ffmpegArgs += "-filter_complex", $filterComplex, "-map", "[out]", $trackStem
                $p = Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait
                if ($p.ExitCode -ne 0) { Write-Warning "Failed to render track $($track.name)" }
                else {
                    if (-not $KeepTemp) {
                        foreach ($ef in $eventFiles) { Remove-Item $ef.File -ErrorAction SilentlyContinue }
                    }
                    $trackDurationSec = Get-DurationSec $trackStem
                    if ($track.PSObject.Properties['effects'] -and $track.effects) {
                        foreach ($fx in $track.effects) {
                            $fxType = Get-Prop $fx "type" "unknown"
                            $fxOut = Join-Path $workDir "track_$($track.name)_fx.wav"
                            Apply-Effect -InputFile $trackStem -OutputFile $fxOut -Effect $fx -WorkDir $workDir -TrackName $track.name -TrackDurationSec $trackDurationSec
                            Move-Item -Force $fxOut $trackStem
                        }
                    }
                    $gainDb = Get-Prop $track "gainDb" 0.0
                    $pan = Get-Prop $track "pan" 0.0
                    $mute = Get-Prop $track "mute" $false
                    $amp = Get-Prop $track "amp" 0.8
                    if ($amp -gt 0) { $gainDb += 20 * [Math]::Log10($amp) }
                    
                    if ($mute) { Write-Host "Track $($track.name) Muted." }
                    else {
                        $mixed = Apply-Mixer -InputFile $trackStem -TrackName $track.name -GainDb $gainDb -Pan $pan -WorkDir $workDir
                        $trackFiles += $mixed
                    }
                }
            }
        }
        elseif ($track.type -eq "sample") {
            Write-Host "Processing Sample Track: $($track.name)"
            $eventFiles = @()
            $i = 0
            foreach ($evt in $trackEvents) {
                $offset = $null
                $dur = $null
                $isLoop = $false
                $loopCount = 0
                $loopDur = 0.0
                $srcVal = Get-Prop $evt "source" $null
                $trackSrc = Get-Prop $track "source" $null
                $src = if ($srcVal) { $srcVal } else { $trackSrc }
                if (-not $src -or -not (Test-Path $src)) {
                    Write-Warning "Source not found for event $i in $($track.name): $src"
                    continue
                }
                $snippetFile = Join-Path $workDir "t$($track.name)_s$i.wav"
                $offsetVal = Get-Prop $evt "offset" 0.0
                $durVal = Get-Prop $evt "dur" 0.0
                $isLoop = Get-Prop $evt "loop" $false
                $offset = if ($offsetVal) { Get-Seconds $offsetVal } else { $null }
                $dur = if ($durVal) { Get-Seconds $durVal } else { $null }

                if ($isLoop) {
                    $tempSnippet = Join-Path $workDir "t$($track.name)_s$($i)_temp.wav"
                    $ffArgs = @("-y", "-i", $src)
                    if ($null -ne $offset) { $ffArgs += "-ss", $offset }
                    if ($null -ne $dur) { $ffArgs += "-t", $dur }
                    $ffArgs += $tempSnippet
                    $p = Start-Process -FilePath $ffmpeg -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                    
                    $loopCount = Get-Prop $evt "loopCount" 0
                    $loopDurVal = Get-Prop $evt "loopDur" 0.0
                    $loopDur = if ($loopDurVal) { Get-Seconds $loopDurVal } else { 0 }
                    $loopArgs = @("-y")
                    if ($loopCount -gt 1) { $loopArgs += "-stream_loop", ($loopCount - 1) }
                    elseif ($loopDur -gt 0) { $loopArgs += "-stream_loop", "-1" }
                    $loopArgs += "-i", $tempSnippet
                    if ($loopDur -gt 0) { $loopArgs += "-t", $loopDur }
                    $loopArgs += $snippetFile
                    $p = Start-Process -FilePath $ffmpeg -ArgumentList $loopArgs -NoNewWindow -PassThru -Wait
                }
                else {
                    $ffArgs = @("-y", "-i", $src)
                    if ($null -ne $offset) { $ffArgs += "-ss", $offset }
                    if ($null -ne $dur) { $ffArgs += "-t", $dur }
                    $ffArgs += $snippetFile
                    $p = Start-Process -FilePath $ffmpeg -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                }
                if ($p.ExitCode -eq 0) {
                    $timeVal = Get-Prop $evt "time" 0.0
                    $delayMs = [int]( (Get-Seconds $timeVal) * 1000 )
                    $eventFiles += @{ File = $snippetFile; Delay = $delayMs }
                }
                $i++
            }
        
            if ($eventFiles.Count -gt 0) {
                $ffmpegArgs = @("-y")
                $filterComplex = ""
                $inputs = ""
                for ($k = 0; $k -lt $eventFiles.Count; $k++) {
                    $ffmpegArgs += "-i", $eventFiles[$k].File
                    $amp = Get-Prop $track "amp" 1.0
                    $filterComplex += "[$k]volume=$amp,adelay=$($eventFiles[$k].Delay)|$($eventFiles[$k].Delay)[s$k];"
                    $inputs += "[s$k]"
                }
                $filterComplex += "${inputs}amix=inputs=$($eventFiles.Count):duration=longest[out]"
                $ffmpegArgs += "-filter_complex", $filterComplex, "-map", "[out]", $trackStem
                $p = Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait
                if ($p.ExitCode -eq 0) {
                    if (-not $KeepTemp) {
                        foreach ($ef in $eventFiles) { Remove-Item $ef.File -ErrorAction SilentlyContinue }
                        Remove-Item (Join-Path $workDir "t$($track.name)_s*_temp.wav") -ErrorAction SilentlyContinue
                    }
                    $trackDurationSec = Get-DurationSec $trackStem
                    if ($track.PSObject.Properties['effects'] -and $track.effects) {
                        foreach ($fx in $track.effects) {
                            $fxType = Get-Prop $fx "type" "unknown"
                            $fxOut = Join-Path $workDir "track_$($track.name)_fx.wav"
                            Apply-Effect -InputFile $trackStem -OutputFile $fxOut -Effect $fx -WorkDir $workDir -TrackName $track.name -TrackDurationSec $trackDurationSec
                            Move-Item -Force $fxOut $trackStem
                        }
                    }
                    $gainDb = Get-Prop $track "gainDb" 0.0
                    $pan = Get-Prop $track "pan" 0.0
                    $mute = Get-Prop $track "mute" $false
                    if ($mute) { Write-Host "Track $($track.name) Muted." }
                    else {
                        $mixed = Apply-Mixer -InputFile $trackStem -TrackName $track.name -GainDb $gainDb -Pan $pan -WorkDir $workDir
                        $trackFiles += $mixed
                    }
                }
            }
        }
    }

    # --- Master Mix ---
    if ($trackFiles.Count -gt 0) {
        Write-Host "Mixing Master..."
        $ffmpegArgs = @("-y")
        $inputs = ""
        for ($k = 0; $k -lt $trackFiles.Count; $k++) {
            $ffmpegArgs += "-i", $trackFiles[$k]
            $inputs += "[$k]"
        }
        $filterComplex = "${inputs}amix=inputs=$($trackFiles.Count):duration=longest[out]"
        $ffmpegArgs += "-filter_complex", $filterComplex, "-map", "[out]", $OutWav
        $p = Start-Process -FilePath $ffmpeg -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait
        if ($p.ExitCode -ne 0) { throw "FFmpeg master mix failed." }
        
        # --- Mastering / Preview Pass ---
        if ($MasterLufs -or $MasterLimitDb -or $MasterGlue -or $Preview) {
            Write-Host "Applying Mastering/Preview..."
            $masterIn = $OutWav
            
            $outExt = [System.IO.Path]::GetExtension($OutWav)
            if (-not $outExt) { $outExt = ".wav" }
            $outBase = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($OutWav), [System.IO.Path]::GetFileNameWithoutExtension($OutWav))
            if ($Preview) {
                # Use a temp file for processing to allow moving it back
                $masterOut = "$outBase`_processed$outExt"
            }
            else {
                # Normal mastering distinct file
                $masterOut = "$outBase`_master$outExt"
            }
            
            $filters = @()
            $extraArgs = @()

            if ($MasterGlue) {
                $filters += "acompressor=threshold=-18dB:ratio=2:attack=5:release=50:makeup=2"
            }
            
            if ($MasterLufs) {
                $tp = -1.0
                if ($MasterLimitDb) { $tp = $MasterLimitDb }
                $filters += "loudnorm=I=$($MasterLufs):TP=$($tp):LRA=11"
            }
            elseif ($MasterLimitDb) {
                $lin = [Math]::Pow(10, $MasterLimitDb / 20)
                $linStr = $lin.ToString("0.0000", [System.Globalization.CultureInfo]::InvariantCulture)
                $filters += "alimiter=limit=$($linStr):level_in=1:level_out=1:measure=0"
            }

            if ($Preview) {
                $filters += "aresample=${PreviewSampleRate},ac=1"
                if (-not ($MasterLufs -or $MasterLimitDb)) {
                    $filters += "alimiter=limit=0.95:level_in=1:level_out=1:measure=0"
                }
                $extraArgs += "-sample_fmt", "s${PreviewBitDepth}"
            }
            
            $filterStr = $filters -join ","
            
            if ($filterStr) {
                Write-Host "Master Filter: $filterStr"
                $processArgs = @("-y", "-i", $masterIn, "-filter_complex", $filterStr) + $extraArgs + @($masterOut)
                $p = Start-Process "ffmpeg" -ArgumentList $processArgs -NoNewWindow -PassThru -Wait
                if ($p.ExitCode -eq 0) {
                    if ($Preview) {
                        Move-Item -Force $masterOut $OutWav
                    }
                    else {
                        $OutWav = $masterOut
                    }
                    Write-Host "Mastered Output: $OutWav" -ForegroundColor Green
                }
                else {
                    Write-Warning "Mastering failed. Keeping unmastered mix."
                }
            }
        }
        
        Write-Host "Rendered to $OutWav"
    
        if ($OutMp3) {
            $mp3Args = @("-y", "-i", $OutWav, $OutMp3)
            $p = Start-Process -FilePath $ffmpeg -ArgumentList $mp3Args -NoNewWindow -PassThru -Wait
            if ($p.ExitCode -ne 0) { throw "FFmpeg MP3 conversion failed." }
            Write-Host "Converted to $OutMp3"
        }
    
        if ($Play) {
            Write-Host "Playing..."
            Start-Process $OutWav
        }
    }
    else {
        Write-Warning "No tracks rendered."
    }

}
catch {
    Write-Error "Sequencer Error: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}
