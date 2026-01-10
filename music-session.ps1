param(
    [string]$SessionPath = ".\\examples\\musaic_session.json",
    [string]$OutputPath = ".\\examples\\musaic_session_score.json"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not (Test-Path $SessionPath)) { throw "Session file not found: $SessionPath" }

$session = Get-Content -Raw $SessionPath | ConvertFrom-Json
Write-Host "Composing session: $($session.project)"

# Helper to fetch prop safely
function Get-Prop {
    param($Obj, $Name, $Default)
    # Safe iterative lookup (Strict Mode compliant)
    if ($null -eq $Obj) { return $Default }
    foreach ($p in $Obj.PSObject.Properties) {
        if ($p.Name -eq $Name) { return $p.Value }
    }
    return $Default
}

# --- Music Theory Helpers ---
$noteMap = @{ C = 0; "C#" = 1; D = 2; "D#" = 3; E = 4; F = 5; "F#" = 6; G = 7; "G#" = 8; A = 9; "A#" = 10; B = 11 }
function Get-MidiPitch {
    param($NoteName, $Octave)
    $pc = $noteMap[$NoteName.ToUpper()]
    if ($null -eq $pc) { return 60 } # Default Middle C
    return ($Octave + 1) * 12 + $pc
}

$keyRoot = Get-Prop $session.key "root" "C"
$rootMidi = Get-MidiPitch $keyRoot 3 # C3

# --- Build Score Structure ---
$score = [ordered]@{
    project   = $session.project
    tempo     = $session.tempo
    timeUnits = "beats"
    tracks    = @()
}

$cursor = 0.0 # Beat cursor

# --- Generate Events ---
foreach ($sect in $session.sections) {
    Write-Host "  Section: $($sect.name) ($($sect.bars) bars)"
    $sectionDur = $sect.bars * 4 # Assuming 4/4
    
    foreach ($trkDef in $session.tracks) {
        # Check if track object exists in score, else add it
        $trkName = Get-Prop $trkDef "name" "Unknown"
        $existing = $null
        foreach ($t in $score.tracks) { if ($t.name -eq $trkName) { $existing = $t; break } }
        
        if (-not $existing) {
            $existing = [ordered]@{
                name   = $trkName
                type   = (Get-Prop $trkDef "type" "synth")
                events = @()
            }
            # Copy basics
            if ($existing.type -eq "sample") {
                $existing["source"] = Get-Prop $trkDef "source" ""
                $existing["amp"] = Get-Prop $trkDef "amp" 1.0
            }
            elseif ($existing.type -eq "synth") {
                $existing["waveform"] = Get-Prop $trkDef "waveform" "sine"
                $existing["amp"] = Get-Prop $trkDef "amp" 0.6
            }
            $score.tracks += $existing
        }
        
        # Generator Logic
        $pattern = Get-Prop $trkDef "pattern" "x..."
        
        # Simple Step Sequencer: pattern string "x..." (x=hit, .=rest)
        # Or "root" (sustain root note)
        
        if ($pattern -eq "root") {
            # One long note for section? Or one per bar?
            # Let's do one per bar for rhythm
            for ($b = 0; $b -lt $sect.bars; $b++) {
                $start = $cursor + ($b * 4)
                $evt = [ordered]@{
                    time  = $start
                    dur   = 4.0
                    pitch = $rootMidi
                }
                $existing.events += $evt
            }
        }
        else {
            # Drum pattern parsing
            # Assume pattern is 16th notes? Or beats?
            # "x..." length 4 -> 1 beat each?
            # Let's assume pattern repeats every bar.
            # "x..." (4 chars) -> Quarter notes.
            # "x.x." (4 chars) -> Quarter notes using 1,3.
            
            $chars = $pattern.ToCharArray()
            $steps = $chars.Count
            $stepSize = 4.0 / $steps # Bar is 4.0 beats
            
            for ($b = 0; $b -lt $sect.bars; $b++) {
                $barStart = $cursor + ($b * 4)
                for ($s = 0; $s -lt $steps; $s++) {
                    $c = $chars[$s]
                    if ($c -eq 'x') {
                        $existing.events += [ordered]@{
                            time  = $barStart + ($s * $stepSize)
                            dur   = $stepSize
                            pitch = 60 # Dummy for sample
                        }
                    }
                }
            }
        }
    }
    
    $cursor += $sectionDur
}

# --- Serialize ---
$json = $score | ConvertTo-Json -Depth 5
$json | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Generated score: $OutputPath"
