param(
    [Parameter(Mandatory = $true)]
    [string]$ScorePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("bars", "beats", "ticks")]
    [string]$Resolution = "beats",

    [Parameter(Mandatory = $false)]
    [int]$Width = 120
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ScorePath)) {
    Write-Error "Score file not found: $ScorePath"
    exit 1
}

$score = Get-Content -Raw $ScorePath | ConvertFrom-Json
$tempo = if ($score.tempo) { $score.tempo } else { 120 }
$timeUnits = if ($score.timeUnits) { $score.timeUnits } else { "beats" }

# Determine conversion to Beats
# If units are seconds, Beats = Time * (Tempo / 60)
function To-Beats {
    param($val)
    if ($timeUnits -eq "seconds") {
        return $val * ($tempo / 60.0)
    }
    return $val
}

# Resolution Scalar (Steps per Beat)
$stepsPerBeat = switch ($Resolution) {
    "bars" { 0.25 } # 1 step = 4 beats
    "beats" { 1 }    # 1 step = 1 beat
    "ticks" { 4 }    # 1 step = 0.25 beat
}

# Determine Max Duration in Beats
$maxBeat = 0
foreach ($track in $score.tracks) {
    foreach ($evt in $track.events) {
        $start = To-Beats $evt.time
        $dur = if ($evt.dur) { To-Beats $evt.dur } else { 0 }
        $end = $start + $dur
        if ($end -gt $maxBeat) { $maxBeat = $end }
    }
}
# Safety pad
$maxBeat = [Math]::Ceiling($maxBeat)
if ($maxBeat -eq 0) { $maxBeat = 16 } # Default if empty

$totalSteps = [Math]::Ceiling($maxBeat * $stepsPerBeat)
$labelWidth = 15
$gridWidth = $Width - $labelWidth - 2 # Borders

# Render Loop (Wrap support)
$currentStep = 0

Write-Host "`nCDP TIMELINE: $ScorePath (Resolution: $Resolution, Tempo: $tempo)" -ForegroundColor Cyan

while ($currentStep -lt $totalSteps) {
    $chunkSize = $gridWidth
    if ($currentStep + $chunkSize -gt $totalSteps) {
        $chunkSize = $totalSteps - $currentStep
    }

    Write-Host ("-" * $Width) -ForegroundColor DarkGray
    
    # Header (Time Grid)
    $headerLine = " " * $labelWidth + " |"
    for ($i = 0; $i -lt $chunkSize; $i++) {
        $absStep = $currentStep + $i
        # Mark Bars/Beats
        # If Resolution=Beats, 1 step = 1 beat. Mark bar every 4.
        # If Resolution=Bars, 1 step = 1 bar.
        # If Resolution=Ticks, 1 step = 0.25 beat. Beat every 4.
        
        $char = "."
        
        if ($Resolution -eq "beats") {
            if ($absStep % 4 -eq 0) { $char = [string]($absStep / 4 + 1) } # Bar number
            else { $char = "." }
        }
        elseif ($Resolution -eq "bars") {
            $char = [string]($absStep + 1)
        }
        elseif ($Resolution -eq "ticks") {
            if ($absStep % 16 -eq 0) { $char = "|" } # Bar
            elseif ($absStep % 4 -eq 0) { $char = "." } # Beat
            else { $char = " " }
        }
        
        # Keep char single
        if ($char.Length -gt 1) { $char = $char.Substring($char.Length - 1, 1) } 
        $headerLine += $char
    }
    Write-Host $headerLine -ForegroundColor Yellow

    # Tracks
    foreach ($track in $score.tracks) {
        $name = $track.name
        if ($name.Length -gt $labelWidth) { $name = $name.Substring(0, $labelWidth) }
        $name = $name.PadRight($labelWidth)
        
        $line = "$name |"
        
        # Build grid for this chunk
        for ($i = 0; $i -lt $chunkSize; $i++) {
            $stepIndex = $currentStep + $i
            $beatStart = $stepIndex / $stepsPerBeat
            $beatEnd = ($stepIndex + 1) / $stepsPerBeat
            
            # Check for events overlapping this step
            $hit = $false
            $isStart = $false
            
            foreach ($evt in $track.events) {
                $eStart = To-Beats $evt.time
                $eDur = if ($evt.dur) { To-Beats $evt.dur } else { 0.1 } # minimal duration
                $eEnd = $eStart + $eDur
                
                # Check Overlap
                # Overlap if (Start < StepEnd) AND (End > StepStart)
                if ($eStart -lt $beatEnd -and $eEnd -gt $beatStart) {
                    $hit = $true
                    # Start frame?
                    if ($eStart -ge $beatStart -and $eStart -lt $beatEnd) {
                        $isStart = $true
                    }
                }
            }
            
            if ($isStart) { $line += "#" }
            elseif ($hit) { $line += "=" }
            else { $line += "." }
        }
        
        Write-Host $line
    }
    
    $currentStep += $chunkSize
    Write-Host ""
}

Write-Host "Legend: [#] Note Start  [=] Sustain  [.] Empty" -ForegroundColor DarkGray
