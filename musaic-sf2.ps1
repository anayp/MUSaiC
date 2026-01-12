param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("validate", "render", "help")]
    [string]$Command,
    
    [string]$ScorePath,
    [string]$SoundfontPath,
    [string]$OutWav, # Explicit, or auto-derived
    [string]$MetaPath
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig

function Show-Help {
    Write-Host "musaic-sf2.ps1 - FluidSynth Bridge for MUSaiC"
    Write-Host "Usage:"
    Write-Host "  ./musaic-sf2.ps1 -Command validate"
    Write-Host "  ./musaic-sf2.ps1 -Command render -ScorePath <json> -SoundfontPath <sf2> [-OutWav <wav>]"
}

function Test-FluidSynth {
    if (-not $cfg.fluidsynthPath) { return $false }
    try {
        $p = Start-Process $cfg.fluidsynthPath -ArgumentList "-h" -NoNewWindow -PassThru -Wait -ErrorAction SilentlyContinue
        return $p.ExitCode -eq 0
    }
    catch { return $false }
}

# --- MIDI Writer Helper ---
function Get-Vlq {
    param([int]$val)
    $bytes = New-Object System.Collections.Generic.List[byte]
    $buffer = $val -band 0x7F
    while (($val = $val -shr 7) -gt 0) {
        $bytes.Add([byte]($buffer -bor 0x80))
        $buffer = $val -band 0x7F
    }
    $bytes.Add([byte]$buffer)
    $arr = $bytes.ToArray()
    [array]::Reverse($arr)
    return $arr
}

function Convert-ScoreToMidi {
    param($Score, $Meta, $OutMidiPath)

    # 1. Timing
    $ppqn = 480
    $tempoBpm = if ($Score.tempo) { $Score.tempo } else { 120 }
    if ($Meta -and $Meta.tempo) { $tempoBpm = $Meta.tempo }
    $timeUnits = if ($Score.timeUnits) { $Score.timeUnits } elseif ($Meta -and $Meta.timeUnits) { $Meta.timeUnits } else { "beats" }

    $usPerBeat = [int](60000000 / $tempoBpm)

    function To-Beats {
        param([double]$v)
        if ($timeUnits -eq "seconds") {
            return $v * ($tempoBpm / 60.0)
        }
        return $v
    }

    # Header: MThd, len=6, fmt=1, ntrks=?, ppqn
    $tracks = @()
    if ($Score.tracks) { $tracks = $Score.tracks }
    $numTracks = $tracks.Count + 1 # +1 for tempo map/conductor track
    
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $bytes.AddRange([System.Text.Encoding]::ASCII.GetBytes("MThd"))
    $bytes.AddRange(@(0, 0, 0, 6)) # len
    $bytes.AddRange(@(0, 1))     # fmt 1
    $bytes.AddRange(@(($numTracks -shr 8), ($numTracks -band 0xFF)))
    $bytes.AddRange(@(($ppqn -shr 8), ($ppqn -band 0xFF)))
    
    # Track 0: Conductor (Tempo)
    # Delta 0, Meta Tempo (FF 51 03 tt tt tt)
    # Delta 0, End Track (FF 2F 00)
    $t0 = [System.Collections.Generic.List[byte]]::new()
    $t0.AddRange(@(0)) # delta 0
    $t0.AddRange(@(0xFF, 0x51, 0x03))
    $t0.AddRange(@(($usPerBeat -shr 16), (($usPerBeat -shr 8) -band 0xFF), ($usPerBeat -band 0xFF)))
    $t0.AddRange(@(0, 0xFF, 0x2F, 0x00)) # end
    
    $bytes.AddRange([System.Text.Encoding]::ASCII.GetBytes("MTrk"))
    $count = $t0.Count
    $bytes.AddRange(@(($count -shr 24), (($count -shr 16) -band 0xFF), (($count -shr 8) -band 0xFF), ($count -band 0xFF)))
    $bytes.AddRange($t0)
    
    # Note Tracks
    $ch = 0
    foreach ($trk in $tracks) {
        $tBytes = [System.Collections.Generic.List[byte]]::new()
        
        # Collect events absolute time
        # Event: { Time: ticks, Type: On/Off, Pitch, Vel }
        $evs = @()
        
        if ($trk.events) {
            foreach ($e in $trk.events) {
                $time = [double]($e.time)
                $dur = [double]($e.dur)
                $pitch = [int]($e.pitch)
                $vel = if ($e.velocity) { [int]$e.velocity } else { 100 }
                if ($vel -lt 1) { $vel = 1 }
                if ($vel -gt 127) { $vel = 127 }

                $beatTime = To-Beats $time
                $beatDur = To-Beats $dur
                $onTick = [int]($beatTime * $ppqn)
                $offTick = [int](($beatTime + $beatDur) * $ppqn)
                
                $evs += [PSCustomObject]@{ Tick = $onTick; Type = "On"; Pitch = $pitch; Vel = $vel }
                $evs += [PSCustomObject]@{ Tick = $offTick; Type = "Off"; Pitch = $pitch; Vel = 0 }
            }
        }
        
        $evs = $evs | Sort-Object Tick
        
        $lastTick = 0
        foreach ($e in $evs) {
            $delta = $e.Tick - $lastTick
            $lastTick = $e.Tick
            
            # Write VLQ Delta
            $tBytes.AddRange((Get-Vlq $delta))
            
            # Status
            # NoteOn ch=0..15. 9n.
            # Running status omitted for simplicity, always write status
            $status = 0x90 -bor ($ch -band 0x0F) # Always use NoteOn (Vel=0 for off)
            $tBytes.Add([byte]$status)
            $tBytes.Add([byte]$e.Pitch)
            $tBytes.Add([byte]$e.Vel)
        }
        
        # End Track
        $tBytes.AddRange(@(0, 0xFF, 0x2F, 0x00))
        
        # Write Chunk
        $bytes.AddRange([System.Text.Encoding]::ASCII.GetBytes("MTrk"))
        $count = $tBytes.Count
        $bytes.AddRange(@(($count -shr 24), (($count -shr 16) -band 0xFF), (($count -shr 8) -band 0xFF), ($count -band 0xFF)))
        $bytes.AddRange($tBytes)
        
        $ch = ($ch + 1) % 16
        if ($ch -eq 9) { $ch++ } # Skip drums channel 10 (9) if we aren't handling drums specially?
    }
    
    [System.IO.File]::WriteAllBytes($OutMidiPath, $bytes.ToArray())
}

if ($Command -eq "help") {
    Show-Help
    exit 0
}

if ($Command -eq "validate") {
    if (Test-FluidSynth) {
        Write-Host "FluidSynth OK."
        if (-not (Test-Path $cfg.soundfontDir)) {
            Write-Warning "soundfontDir not found: $($cfg.soundfontDir)"
        }
        else {
            $sf2 = Get-ChildItem $cfg.soundfontDir -Filter "*.sf2" | Select-Object -First 1
            if (-not $sf2) { Write-Warning "No .sf2 files found in $($cfg.soundfontDir)" }
        }
        exit 0
    }
    Write-Error "FluidSynth not found or invalid."
}

if ($Command -eq "render") {
    if (-not (Test-FluidSynth)) { throw "FluidSynth not ready." }
    if (-not $ScorePath) { throw "-ScorePath required" }
    
    if (-not $SoundfontPath) {
        # Check config default
        if ($cfg.soundfontDir) {
            # Pick first sf2?
            $sf2 = Get-ChildItem $cfg.soundfontDir -Filter "*.sf2" | Select-Object -First 1
            if ($sf2) { $SoundfontPath = $sf2.FullName }
        }
    }
    
    if (-not $SoundfontPath -or -not (Test-Path $SoundfontPath)) {
        throw "Soundfont not found: $SoundfontPath"
    }

    $score = Get-Content $ScorePath -Raw | ConvertFrom-Json
    $meta = $null
    if ($MetaPath -and (Test-Path $MetaPath)) { $meta = Get-Content $MetaPath -Raw | ConvertFrom-Json }
    
    # Generate MIDI
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ScorePath)
    $midiPath = Join-Path $cfg.outputDir "${baseName}_temp.mid"
    
    Write-Host "Converting Score to MIDI: $midiPath"
    Convert-ScoreToMidi -Score $score -Meta $meta -OutMidiPath $midiPath
    
    # Render
    $wavOut = if ($OutWav) { $OutWav } else { Join-Path $cfg.outputDir "${baseName}_sf2.wav" }
    
    Write-Host "Rendering with FluidSynth to $wavOut ..."
    
    # fluidsynth -ni -g 1.0 <sf2> <midi> -F <wav> -r 44100
    $fsArgs = "-ni", "-g", "1.0", $SoundfontPath, $midiPath, "-F", $wavOut, "-r", "44100"
    
    $p = Start-Process $cfg.fluidsynthPath -ArgumentList $fsArgs -NoNewWindow -PassThru -Wait
    
    # Cleanup MIDI
    Remove-Item $midiPath -ErrorAction SilentlyContinue
    
    if ($p.ExitCode -eq 0) {
        Write-Host "Render Complete."
    }
    else {
        Write-Error "FluidSynth exited with code $($p.ExitCode)"
    }
}
