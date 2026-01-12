param(
    [Parameter(Mandatory = $true)][string]$ScorePath,
    [string]$OutJson,
    [string]$OutTxt,
    [int]$BeatsPerBar = 4,
    [double]$WindowBars = 1.0,
    [string]$MetaPath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- Configuration ---
$configHelper = Join-Path $PSScriptRoot "musaic-config.ps1"
if (-not (Test-Path $configHelper)) { throw "Missing musaic-config.ps1" }
. $configHelper
$cfg = Get-MusaicConfig

# Import shared theory logic
$modulePath = Join-Path $PSScriptRoot "musaic-theory.psm1"
if (-not (Test-Path $modulePath)) { throw "Missing musaic-theory.psm1" }
Import-Module $modulePath -Force

# ...

# --- Helper Functions ---
function Get-Prop {
    param($Obj, $Name, $Default)
    if ($null -eq $Obj) { return $Default }
    foreach ($p in $Obj.PSObject.Properties) {
        if ($p.Name -eq $Name) { return $p.Value }
    }
    return $Default
}

# --- Core Logic ---
if ([string]::IsNullOrWhiteSpace($ScorePath)) { throw "ScorePath argument is missing." }
if (-not (Test-Path $ScorePath)) { throw "Score not found: $ScorePath" }
$score = Get-Content $ScorePath -Raw | ConvertFrom-Json

# Timing Setup
$defUnits = "seconds"
$defTempo = 120
if ($MetaPath -and (Test-Path $MetaPath)) {
    $meta = Get-Content $MetaPath -Raw | ConvertFrom-Json
    $defUnits = Get-Prop $meta "timeUnits" $defUnits
    $defTempo = Get-Prop $meta "tempo" $defTempo
}
$units = Get-Prop $score "timeUnits" $defUnits
$tempo = Get-Prop $score "tempo" $defTempo

function Convert-ToBeats {
    param($val)
    if ($units -eq "beats") { return [double]$val }
    # seconds -> beats: val * (BPM / 60)
    return [double]$val * ($tempo / 60.0)
}

# Parse events
$allNotes = @()
if ($score.tracks) {
    foreach ($track in $score.tracks) {
        if (Get-Prop $track "mute" $false) { continue }
        $trackName = Get-Prop $track "name" "Unknown"
        $events = Get-Prop $track "events" @()
        foreach ($evt in $events) {
            $p = Get-Prop $evt "pitch" $null
            if ($p -is [int] -or $p -is [double] -or $p -is [long] -or $p -is [decimal]) {
                $time = Convert-ToBeats (Get-Prop $evt "time" 0.0)
                $dur = Convert-ToBeats (Get-Prop $evt "dur" 1.0)
                $dPitch = [double]$p
                $allNotes += [PSCustomObject]@{
                    Start = [double]$time
                    Dur   = [double]$dur
                    Pitch = $dPitch
                    PC    = [int][Math]::Round($dPitch) % 12
                    Track = $trackName
                }
            }
        }
    }
}

# --- Key Detection ---
# Build Histogram weighted by duration
$hist = @(0) * 12
foreach ($n in $allNotes) {
    $hist[$n.PC] += $n.Dur
}

$isHistEmpty = ($hist | Measure-Object -Sum).Sum -eq 0

if ($isHistEmpty) {
    $bestKey = [PSCustomObject]@{ Root = 0; Type = "Major"; Score = 0 }
    $candidates = @($bestKey)
    $confidence = 0
    Write-Warning "No pitch content found. Defaulting to C Major."
}
else {
    $candidates = Get-KeyEstimates -Hist $hist
    $bestKey = $candidates[0]
    $confidence = $candidates[0].Score - $candidates[1].Score
}

# Note names
$rootName = Get-NoteName -Pc $bestKey.Root
$keyStr = "$rootName $($bestKey.Type)"

# Scale Mismatch
$majIntervals = @(0, 2, 4, 5, 7, 9, 11)
$minIntervals = @(0, 2, 3, 5, 7, 8, 10)
$scaleSet = @{}
$intervals = if ($bestKey.Type -eq "Major") { $majIntervals } else { $minIntervals }
foreach ($iv in $intervals) { $scaleSet[($bestKey.Root + $iv) % 12] = $true }

$outNoteCounts = @{}
$totalNotes = 0
$outNotes = 0
foreach ($n in $allNotes) {
    $totalNotes++
    if (-not $scaleSet.ContainsKey($n.PC)) {
        $outNotes++
        $name = Get-NoteName -Pc $n.PC
        if (-not $outNoteCounts.ContainsKey($name)) { $outNoteCounts[$name] = 0 }
        $outNoteCounts[$name]++
    }
}
$outRatio = if ($totalNotes -gt 0) { $outNotes / $totalNotes } else { 0 }

# --- Chord Detection ---
$windowSize = $WindowBars * $BeatsPerBar
$maxBeat = 0
foreach ($n in $allNotes) {
    $end = $n.Start + $n.Dur
    if ($end -gt $maxBeat) { $maxBeat = $end }
}

$chords = @()

for ($t = 0; $t -lt $maxBeat; $t += $windowSize) {
    $wEnd = $t + $windowSize
    # gather notes in window
    $wHist = @(0) * 12
    $wTotal = 0
    foreach ($n in $allNotes) {
        # check overlap
        if ($n.Start -lt $wEnd -and ($n.Start + $n.Dur) -gt $t) {
            $wHist[$n.PC] += $n.Dur
            $wTotal += $n.Dur
        }
    }
    
    if ($wTotal -eq 0) { continue }
    
    $bestChord = Get-BestChord -Hist $wHist
    if ($bestChord -and $bestChord.Score -gt 0) {
        $chords += [PSCustomObject]@{
            Start   = $t
            End     = $wEnd
            Root    = $bestChord.Root
            Quality = $bestChord.Quality
            Score   = $bestChord.Score
            Name    = (Get-NoteName $bestChord.Root) + $bestChord.Quality
        }
    }
}

# --- Roman Numerals ---
foreach ($c in $chords) {
    $rom = Get-RomanNumeral -ChordRoot $c.Root -ChordQuality $c.Quality -KeyRoot $bestKey.Root -KeyType $bestKey.Type
    $c | Add-Member -NotePropertyName "Roman" -NotePropertyValue $rom
}

# --- Cadences ---
function Get-Cadences {
    param([array]$chordList, $keyRoot)
    $cads = @()
    $dom = ($keyRoot + 7) % 12
    $tonic = $keyRoot
    $subdom = ($keyRoot + 5) % 12 
    
    for ($i = 0; $i -lt $chordList.Count - 1; $i++) {
        $c1 = $chordList[$i]
        $c2 = $chordList[$i + 1]
        
        # Check V -> I
        if ($c1.Root -eq $dom -and ($c2.Root -eq $tonic)) {
            $cads += "Perfect Cadence (V-I) at Bar $(($c2.Start/$BeatsPerBar).ToString("0.0"))"
        }
        # Check IV -> I
        if ($c1.Root -eq $subdom -and $c2.Root -eq $tonic) {
            $cads += "Plagal Cadence (IV-I) at Bar $(($c2.Start/$BeatsPerBar).ToString("0.0"))"
        }
    }
    return $cads
}
$cadenceList = @(Get-Cadences $chords $bestKey.Root)

# --- Track Stats ---
$trackStats = @{}
foreach ($trackGroup in ($allNotes | Group-Object Track)) {
    $tName = $trackGroup.Name
    $tNotes = $trackGroup.Group
    $minP = ($tNotes | Measure-Object Pitch -Minimum).Minimum
    $maxP = ($tNotes | Measure-Object Pitch -Maximum).Maximum
    
    # Intervals
    $intervals = @()
    $prev = $null
    $sorted = $tNotes | Sort-Object Start
    
    foreach ($n in $sorted) {
        if ($prev) {
            $diff = [Math]::Abs($n.Pitch - $prev.Pitch)
            $intervals += $diff
        }
        $prev = $n
    }
    
    $step = 0
    $leap = 0
    $avgInt = 0
    if ($intervals.Count -gt 0) {
        $step = @($intervals | Where-Object { $_ -le 2 }).Count
        $leap = @($intervals | Where-Object { $_ -ge 7 }).Count
        $avgInt = ($intervals | Measure-Object -Average).Average
    }
    
    $trackStats[$tName] = @{
        Range         = "$minP - $maxP"
        AvgInterval   = "$($avgInt.ToString("F1"))"
        StepwiseRatio = if ($intervals.Count) { ($step / $intervals.Count).ToString("P0") } else { "0%" }
        LeapRatio     = if ($intervals.Count) { ($leap / $intervals.Count).ToString("P0") } else { "0%" }
    }
}

# --- Scale Degree Histogram ---
$scaleDegHist = @(0) * 12 
foreach ($n in $allNotes) {
    $deg = ([int][Math]::Round($n.Pitch) - $bestKey.Root + 12) % 12
    $scaleDegHist[$deg] += $n.Dur
}

# --- Output ---
$analysis = [ordered]@{
    key                    = $keyStr
    key_mode               = $bestKey.Type
    key_root               = (Get-NoteName $bestKey.Root)
    key_confidence         = $confidence
    key_candidates         = $candidates | Select-Object -First 3
    
    pitch_class_histogram  = $hist
    scale_degree_histogram = $scaleDegHist

    out_of_key_ratio       = $outRatio
    out_of_key_notes       = $outNoteCounts
    
    chords                 = $chords | Select-Object Start, Name, Roman, Score
    roman_numerals         = ($chords | Select-Object -ExpandProperty Roman)
    cadences               = $cadenceList
    
    track_stats            = $trackStats
    warnings               = @()
}

if (-not $OutJson) { 
    $base = [System.IO.Path]::GetFileNameWithoutExtension($ScorePath)
    $outDir = Join-Path $cfg.outputDir "analysis"
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    $OutJson = Join-Path $outDir "${base}_theory.json"
    $OutTxt = Join-Path $outDir "${base}_theory.txt"
}

$analysis | ConvertTo-Json -Depth 4 | Out-File $OutJson -Encoding UTF8
Write-Host "JSON: $OutJson"

$rpt = "Theory Report: $(Split-Path $ScorePath -Leaf)`n"
$rpt += "Key: $keyStr (Conf: $($confidence.ToString("F2")))`n"
if ($cadenceList.Count -gt 0) {
    $rpt += "Cadences:`n  " + ($cadenceList -join "`n  ") + "`n"
}
$rpt += "Scale Mismatch: $($outRatio.ToString("P1"))`n"
if ($outNoteCounts.Count -gt 0) {
    $rpt += "Out-of-key: " + ($outNoteCounts.Keys -join ", ") + "`n"
}
$rpt += "`nChords:`n"
foreach ($c in $chords) {
    $rpt += "Bar $(($c.Start/$BeatsPerBar).ToString("0.0")): $($c.Name) ($($c.Roman))`n"
}
$rpt += "`nTracks:`n"
foreach ($k in $trackStats.Keys) {
    $s = $trackStats[$k]
    $rpt += "[$k] Range:$($s.Range) AvgInt:$($s.AvgInterval) Steps:$($s.StepwiseRatio)`n"
}

if ($OutTxt) {
    $rpt | Out-File $OutTxt -Encoding UTF8
    Write-Host "Report: $OutTxt"
}
