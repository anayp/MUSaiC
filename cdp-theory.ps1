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

# --- Key Detection (Krumhansl-Schmuckler) ---
# Profiles (Major / Minor)
$profMaj = @(6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88)
$profMin = @(6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17)

# Build Histogram weighted by duration
$hist = @(0) * 12
foreach ($n in $allNotes) {
    $hist[$n.PC] += $n.Dur
}
# Normalize ? Not strictly needed for correlation comparison, but good practice.
# Just use raw dot product as score.

function Get-Correlation {
    param($InputHist, $Profile)
    # Pearson correlation? Or just dot product? 
    # KS usually uses correlation coefficient. 
    # Simplified: Dot product matches well enough for simple estimation.
    $sum = 0
    for ($i = 0; $i -lt 12; $i++) {
        $sum += $InputHist[$i] * $Profile[$i]
    }
    return $sum
}

$isHistEmpty = ($hist | Measure-Object -Sum).Sum -eq 0

if ($isHistEmpty) {
    # If no notes, default to C Major
    $bestKey = [PSCustomObject]@{ Root = 0; Type = "Major"; Score = 0 }
    $candidates = @($bestKey)
    $confidence = 0
    Write-Warning "No pitch content found. Defaulting to C Major."
}
else {
    # Calculate scores... inputs: $hist, $profMaj, $profMin
    # ... logic already here ...
    
    $candidates = @()
    for ($root = 0; $root -lt 12; $root++) {
        # Alignment: Score = Sum( Input[(i + root)%12] * Profile[i] )
    
        # Major
        $sMaj = 0
        for ($i = 0; $i -lt 12; $i++) { $sMaj += $hist[($i + $root) % 12] * $profMaj[$i] }
        $candidates += [PSCustomObject]@{ Root = $root; Type = "Major"; Score = $sMaj }
    
        # Minor
        $sMin = 0
        for ($i = 0; $i -lt 12; $i++) { $sMin += $hist[($i + $root) % 12] * $profMin[$i] }
        $candidates += [PSCustomObject]@{ Root = $root; Type = "Minor"; Score = $sMin }
    }
    
    $candidates = $candidates | Sort-Object Score -Descending
    $bestKey = $candidates[0]
    $confidence = $candidates[0].Score - $candidates[1].Score
}

# Note names
$pcNames = @("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
$rootName = $pcNames[$bestKey.Root]
$keyStr = "$rootName $($bestKey.Type)"

# scale map for out-of-key
# Major: 0,2,4,5,7,9,11
# Minor: 0,2,3,5,7,8,10 (Natural)
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
        $name = $pcNames[$n.PC]
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

# chord templates (intervals from root)
$templates = @{
    "Maj"   = @(0, 4, 7)
    "Min"   = @(0, 3, 7)
    "Dim"   = @(0, 3, 6)
    "Aug"   = @(0, 4, 8)
    "Sus2"  = @(0, 2, 7)
    "Sus4"  = @(0, 5, 7)
    "Maj7"  = @(0, 4, 7, 11)
    "Dom7"  = @(0, 4, 7, 10)
    "Min7"  = @(0, 3, 7, 10)
    "HDim7" = @(0, 3, 6, 10)
    "Dim7"  = @(0, 3, 6, 9)
}

for ($t = 0; $t -lt $maxBeat; $t += $windowSize) {
    $wEnd = $t + $windowSize
    # gather notes in window
    $wHist = @(0) * 12
    $wTotal = 0
    foreach ($n in $allNotes) {
        # check overlap
        $nEnd = $n.Start + $n.Dur
        if ($n.Start -lt $wEnd -and $nEnd -gt $t) {
            # simple weight: full duration in window? 
            # simplified: use full duration if any overlap. 
            $wHist[$n.PC] += $n.Dur
            $wTotal += $n.Dur
        }
    }
    
    if ($wTotal -eq 0) { continue }
    
    $bestChord = $null
    $bestCScore = -9999
    
    foreach ($cRoot in 0..11) {
        foreach ($tmplKey in $templates.Keys) {
            $ivs = $templates[$tmplKey]
            # Match score:
            # + weight of match note
            # - 0.5 * weight of non-match
            $scoreCH = 0
            # helper set
            $cSet = @{}
            foreach ($x in $ivs) { $cSet[($cRoot + $x) % 12] = $true }
            
            for ($p = 0; $p -lt 12; $p++) {
                if ($cSet.ContainsKey($p)) {
                    $scoreCH += $wHist[$p]
                }
                else {
                    $scoreCH -= 0.5 * $wHist[$p]
                }
            }
            
            if ($scoreCH -gt $bestCScore) {
                $bestCScore = $scoreCH
                $bestChord = @{ Root = $cRoot; Quality = $tmplKey }
            }
        }
    }
    
    # Threshold? e.g. score > 0.
    if ($bestChord -and $bestCScore -gt 0) {
        $chords += [PSCustomObject]@{
            Start   = $t
            End     = $wEnd
            Root    = $bestChord.Root
            Quality = $bestChord.Quality
            Score   = $bestCScore
            Name    = $pcNames[$bestChord.Root] + $bestChord.Quality
        }
    }
}

# --- Roman Numerals ---
# Key context: $bestKey.Root
$keyRoot = $bestKey.Root
$romanMap = if ($bestKey.Type -eq "Major") {
    @("I", "bII", "ii", "bIII", "iii", "IV", "bV", "V", "bVI", "vi", "bVII", "vii")
}
else {
    # Minor
    # Minor
    # Minor (Natural: i, ii0, III, iv, v, VI, VII) 
    # Chromatic map: 0..11
    # i, bII, ii, bIII, iii, iv, bV, v, bVI, VI, bVII, VII
    @("i", "bII", "ii", "III", "iii", "iv", "bV", "v", "bVI", "VI", "bVII", "VII")
}

# Assign numerals
foreach ($c in $chords) {
    # interval from key root
    $deg = ($c.Root - $keyRoot + 12) % 12
    $rom = $romanMap[$deg]
    
    # Adjust for quality if needed? 
    # e.g. Major chord on V match "V". Minor on V match "v".
    # Simplified mapping for now based on root.
    # Refinement:
    if ($c.Quality -match "Min" -or $c.Quality -match "Dim") {
        $rom = $rom.ToLower() 
    }
    else {
        $rom = $rom.ToUpper() # Force upper for Major/Aug/Dom
    }
    
    $c | Add-Member -NotePropertyName "Roman" -NotePropertyValue $rom
}

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
    # Sort by start time for melody analysis
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

# --- Output ---
# --- Cadences ---
function Get-Cadences {
    param([array]$chordList, $keyRoot)
    $cads = @()
    # Looking for V -> I resolution
    # Major: V(7) -> I
    # Minor: V(7) -> i or v -> i? Strictly V is major in minor key for cadence.
    
    # Map chords to Roman simply by interval?
    # We already attached Roman.
    
    # Simplify: Look for Root movement.
    # V -> I means Root = (KeyRoot + 7) -> KeyRoot
    
    $dom = ($keyRoot + 7) % 12
    $tonic = $keyRoot
    $subdom = ($keyRoot + 5) % 12 # IV
    $superval = ($keyRoot + 2) % 12 # ii
    
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

# --- Scale Degree Histogram ---
$scaleDegHist = @(0) * 12 # 0=Tonic, 7=Dominant, etc.
foreach ($n in $allNotes) {
    # Degree relative to root
    $deg = ([int][Math]::Round($n.Pitch) - $bestKey.Root + 12) % 12
    $scaleDegHist[$deg] += $n.Dur
}

# --- Output ---
$analysis = [ordered]@{
    key                    = $keyStr
    key_mode               = $bestKey.Type
    key_root               = $pcNames[$bestKey.Root]
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
    $outDir = Join-Path (Split-Path $ScorePath) "..\output\analysis"
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
