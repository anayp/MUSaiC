param(
    [string]$ScorePath = ".\\examples\\effects_demo.json",
    [string]$OutWav, # Optional override
    [string]$OutMp3, # Optional mp3 output
    [switch]$Play
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Dependency Checks ---
if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
    throw "ffmpeg is not in your PATH. Please install ffmpeg."
}

try {
    # --- Configuration ---
    $cdpBin = Join-Path $PSScriptRoot "CDPR8\\_cdp\\_cdprogs"
    $synthExe = Join-Path $cdpBin "synth.exe"
    $reverbExe = Join-Path $cdpBin "reverb.exe"
    $modifyExe = Join-Path $cdpBin "modify.exe"

    $workDir = Join-Path $PSScriptRoot "output\\tmp_sequencer"
    $outDir = Join-Path $PSScriptRoot "output"

    if (-not (Test-Path $synthExe)) { throw "Missing synth.exe at $synthExe" }
    # reverb and modify checks are now lazy in Apply-Effect

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

    # --- Helper: Safe Property Access ---
    function Get-Prop {
        param($Obj, $Name, $Default)
        if ($Obj.PSObject.Properties[$Name]) { return $Obj.$Name }
        return $Default
    }

    # --- Output Pathing ---
    if (-not $OutWav) {
        $projName = Get-Prop $score "project" "project"
        # Sanitize filename
        $safeProj = $projName -replace '[^a-zA-Z0-9_\-]', '_'
        $OutWav = Join-Path $outDir "$safeProj-master.wav"
    }
    $OutWav = [System.IO.Path]::GetFullPath($OutWav)
    Write-Host "Target Output: $OutWav"

    # --- Timing Setup ---
    $timeUnits = Get-Prop $score "timeUnits" "seconds"
    $tempo = Get-Prop $score "tempo" 120
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
            elseif ($t.type -eq "sample") {
                # Valid loop fields: loop(bool), loopCount(int), loopDur(num)
                # Not strictly ensuring existence here but types if present?
            }
        }
    }
    Validate-Score -S $score

    # --- Helper Functions ---
    function Run-Synth {
        param($Output, $Waveform, $Duration, $Freq, $Amp, $SampleRate = 48000)
    
        $modeMap = @{ sine = 1; square = 2; saw = 3; ramp = 4 }
        $mode = $modeMap[$Waveform]
        if (-not $mode) { $mode = 1 } # Default to sine

        $args = @(
            "wave", $mode, $Output, $SampleRate, 1, # Mono
            $Duration, $Freq, "-a$Amp" # Pass -a with no space
        )
        $p = Start-Process -FilePath $synthExe -ArgumentList $args -NoNewWindow -PassThru -Wait
        if ($p.ExitCode -ne 0) { throw "Synth failed" }
    }

    function Apply-Effect {
        param(
            [string]$InputFile,
            [string]$OutputFile,
            [object]$Effect
        )
    
        # REVERB USAGE:
        # reverb infile outfile rgain mix rvbtime absorb lpfreq tail [times.txt]
        # We will map:
        #   rgain <- 0.6 (fixed)
        #   mix <- prior (0-1)
        #   rvbtime <- room_size (default 1.0)
        #   absorb <- 0.5
        #   lpfreq <- 5000 (default)
        #   tail <- 1.0 (extra time)
    
        # MODIFY SPEED USAGE:
        # modify speed 1 infile outfile ratio
    
        $fxType = Get-Prop $Effect "type" "unknown"

        if ($fxType -eq "reverb") {
            if (-not (Test-Path $reverbExe)) { throw "Missing reverb.exe at $reverbExe needed for effect" }
        
            $rvbtime = Get-Prop $Effect "room_size" 1.0
            $mix = Get-Prop $Effect "mix" 0.5
        
            # Helper params
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
        else {
            throw "Effect '$fxType' is not supported."
        }
    }

    # --- Sequencer Logic ---
    $trackFiles = @()

    foreach ($track in $score.tracks) {
        Write-Host "Processing Track: $($track.name) ($($track.type))"
    
        $trackEvents = $track.events | Sort-Object time
        $trackStem = Join-Path $workDir "track_$($track.name).wav"
    
        if ($track.type -eq "synth") {
            # Generate individual note files
            $eventFiles = @()
            $i = 0
            foreach ($evt in $trackEvents) {
                $noteFile = Join-Path $workDir "t$($track.name)_n$i.wav"
            
                # Default params if missing
                $durVal = Get-Prop $evt "dur" 1.0
                $dur = Get-Seconds $durVal
            
                $pitch = Get-Prop $evt "pitch" 60
                $freq = 440 * [Math]::Pow(2, ($pitch - 69) / 12)
            
                $amp = Get-Prop $track "amp" 0.8
                $wave = Get-Prop $track "waveform" "sine"

                Run-Synth -Output $noteFile -Waveform $wave -Duration $dur -Freq $freq -Amp $amp
            
                # Calculate delay in ms
                $timeVal = Get-Prop $evt "time" 0.0
                $timeSec = Get-Seconds $timeVal
                $delayMs = [int]($timeSec * 1000)
                $eventFiles += @{ File = $noteFile; Delay = $delayMs }
                $i++
            }

            # Mix notes into one track stem using ffmpeg adelay
            # Filter: [0]adelay=1000|1000[a];[1]adelay=2000|2000[b];[a][b]amix=2
            # Note: synth.exe output is mono. adelay args: delay_ch1|delay_ch2... 
            # mixing to stereo usually happens at master, but let's keep track mono or stereo? 
            # Let's keep stem mono for now, mixed to stereo at end.
        
            if ($eventFiles.Count -gt 0) {
                $ffmpegArgs = @("-y")
                $filterComplex = ""
                $inputs = ""
            
                for ($k = 0; $k -lt $eventFiles.Count; $k++) {
                    $ffmpegArgs += "-i", $eventFiles[$k].File
                    # Delay mono: just one value
                    $filterComplex += "[$k]adelay=$($eventFiles[$k].Delay)|$($eventFiles[$k].Delay)[s$k];"
                    $inputs += "[s$k]"
                }
            
                $filterComplex += "${inputs}amix=inputs=$($eventFiles.Count):duration=longest[out]"
            
                $ffmpegArgs += "-filter_complex", $filterComplex, "-map", "[out]", $trackStem
            
                # Write-Host "FFmpeg args: $ffmpegArgs"
                $p = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait
                if ($p.ExitCode -ne 0) { 
                    Write-Warning "Failed to render track $($track.name)"
                }
                else {
                    if ($track.PSObject.Properties['effects'] -and $track.effects) {
                        foreach ($fx in $track.effects) {
                            # Safe prop access
                            $fxType = Get-Prop $fx "type" "unknown"
                            Write-Host "Applying effect: $fxType"
                            $fxOut = Join-Path $workDir "track_$($track.name)_fx.wav"
                            Apply-Effect -InputFile $trackStem -OutputFile $fxOut -Effect $fx
                            Move-Item -Force $fxOut $trackStem
                        }
                    }
                    $trackFiles += $trackStem
                }
            }
        }
        elseif ($track.type -eq "sample") {
            Write-Host "Processing Sample Track: $($track.name)"
            # For samples, we assume source files exist.
            # Events have time and optional duration/offset.
        
            $eventFiles = @()
            $i = 0
            foreach ($evt in $trackEvents) {
                # STRICT MODE INIT
                $offset = $null
                $dur = $null
                $isLoop = $false
                $tempSnippet = $null
                $loopCount = 0
                $loopDur = 0.0

                # Find source: track default or event overwrite
                $srcVal = Get-Prop $evt "source" $null
                $trackSrc = Get-Prop $track "source" $null
                $src = if ($srcVal) { $srcVal } else { $trackSrc }
            
                if (-not $src -or -not (Test-Path $src)) {
                    Write-Warning "Source not found for event $i in $($track.name): $src"
                    continue
                }
            
                # Create a snippet for this event
                $snippetFile = Join-Path $workDir "t$($track.name)_s$i.wav"
            
                # trim logic
                $offsetVal = Get-Prop $evt "offset" 0.0
                $durVal = Get-Prop $evt "dur" 0.0
                $isLoop = Get-Prop $evt "loop" $false

                # Apply timing conversion if 'beats'
                $offset = if ($offsetVal) { Get-Seconds $offsetVal } else { $null }
                $dur = if ($durVal) { Get-Seconds $durVal } else { $null }

                # Looping Logic
                # Strict mode is FULLY ON. Variables initialized above.
                
                # DEBUG INIT STATE
                # Write-Host "DEBUG: isLoop=$isLoop offset=$offset dur=$dur"
                
                if ($isLoop) {
                    # If lopping, we first extract the snippet, then loop it.
                    # 1. Extract Snippet
                    $tempSnippet = Join-Path $workDir "t$($track.name)_s$i_temp.wav"
                    $ffArgs = @("-y", "-i", $src)
                    if ($null -ne $offset) { $ffArgs += "-ss", $offset }
                    if ($null -ne $dur) { $ffArgs += "-t", $dur }
                    $ffArgs += $tempSnippet
                     
                    $p = Start-Process -FilePath "ffmpeg" -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                    if ($p.ExitCode -ne 0) {
                        Write-Warning "Failed to extract snippet for looping event $i in $($track.name)"
                        continue
                    }
                     
                    # 2. Loop Snippet
                    # loopCount or loopDur?
                    $loopCount = Get-Prop $evt "loopCount" 0
                    $loopDurVal = Get-Prop $evt "loopDur" 0.0
                    $loopDur = if ($loopDurVal) { Get-Seconds $loopDurVal } else { 0 }
                     
                    $loopArgs = @("-y")
                     
                    # -stream_loop N (loops N times, so total N+1 plays? No, "number of times to loop". 0=no loop. 1=play,loop(1) = 2 totals)
                    # If user says loopCount=4, usually implies 4 repeats -> 5 plays? Or 4 plays?
                    # Let's assume loopCount means "Total Plays". So loop = count - 1.
                    # If loopCount=1, loop=0.
                     
                    if ($loopCount -gt 1) {
                        $loopArgs += "-stream_loop", ($loopCount - 1)
                    }
                    elseif ($loopDur -gt 0) {
                        $loopArgs += "-stream_loop", "-1" # infinite
                    }
                     
                    $loopArgs += "-i", $tempSnippet
                     
                    if ($loopDur -gt 0) {
                        $loopArgs += "-t", $loopDur 
                    }
                    
                    $loopArgs += $snippetFile
                     
                    $p = Start-Process -FilePath "ffmpeg" -ArgumentList $loopArgs -NoNewWindow -PassThru -Wait
                    if ($p.ExitCode -ne 0) {
                        Write-Warning "Failed to loop event $i in $($track.name)"
                        continue
                    }
                }
                else {
                    # Normal Trim
                    # input args
                    $ffArgs = @("-y", "-i", $src)
                    if ($null -ne $offset) { $ffArgs += "-ss", $offset }
                    if ($null -ne $dur) { $ffArgs += "-t", $dur }
                    $ffArgs += $snippetFile
                
                    $p = Start-Process -FilePath "ffmpeg" -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                }


            
                if ($p.ExitCode -eq 0) {
                    $timeVal = Get-Prop $evt "time" 0.0
                    $delayMs = [int]( (Get-Seconds $timeVal) * 1000 )
                    $eventFiles += @{ File = $snippetFile; Delay = $delayMs }
                }
                $i++
            }
        
            # Mix samples into track stem
            if ($eventFiles.Count -gt 0) {
                $ffmpegArgs = @("-y")
                $filterComplex = ""
                $inputs = ""
            
                for ($k = 0; $k -lt $eventFiles.Count; $k++) {
                    $ffmpegArgs += "-i", $eventFiles[$k].File
                    # Apply optional amp (volume)
                    $amp = Get-Prop $track "amp" 1.0
                    $filterComplex += "[$k]volume=$amp,adelay=$($eventFiles[$k].Delay)|$($eventFiles[$k].Delay)[s$k];"
                    $inputs += "[s$k]"
                }
            
                $filterComplex += "${inputs}amix=inputs=$($eventFiles.Count):duration=longest[out]"
                $ffmpegArgs += "-filter_complex", $filterComplex, "-map", "[out]", $trackStem
            
                $p = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait
                if ($p.ExitCode -eq 0) {
                    # Apply Effects for Sample Track
                    if ($track.PSObject.Properties['effects'] -and $track.effects) {
                        foreach ($fx in $track.effects) {
                            # Safe prop access
                            $fxType = Get-Prop $fx "type" "unknown"
                            Write-Host "Applying effect: $fxType"
                            $fxOut = Join-Path $workDir "track_$($track.name)_fx.wav"
                            Apply-Effect -InputFile $trackStem -OutputFile $fxOut -Effect $fx
                            Move-Item -Force $fxOut $trackStem
                        }
                    }
                    $trackFiles += $trackStem
                }
            }
        }
    }

    # --- Master Mix ---
    if ($trackFiles.Count -gt 0) {
        Write-Host "Mixing Master..."
        $ffmpegArgs = @("-y")
        $inputs = ""
        # Just mix all stems. They are already timed relative to 0.
        for ($k = 0; $k -lt $trackFiles.Count; $k++) {
            $ffmpegArgs += "-i", $trackFiles[$k]
            $inputs += "[$k]"
        }
        $filterComplex = "${inputs}amix=inputs=$($trackFiles.Count):duration=longest[out]"
        $ffmpegArgs += "-filter_complex", $filterComplex, "-map", "[out]", $OutWav
    
    
        $p = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait
        if ($p.ExitCode -ne 0) { throw "FFmpeg master mix failed." }
        Write-Host "Rendered to $OutWav"
    
        # Optional MP3 Conversion
        if ($OutMp3) {
            $mp3Args = @("-y", "-i", $OutWav, $OutMp3)
            $p = Start-Process -FilePath "ffmpeg" -ArgumentList $mp3Args -NoNewWindow -PassThru -Wait
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
