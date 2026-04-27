param(
    [Parameter(Mandatory = $true)]
    [string]$ScorePath,

    [ValidateSet("arranger", "mixer", "piano")]
    [string]$View = "arranger",

    [int]$Width = 120,
    [switch]$Interactive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Prop {
    param($Obj, [string]$Name, $Default)
    if ($null -eq $Obj) { return $Default }
    foreach ($p in $Obj.PSObject.Properties) {
        if ($p.Name -eq $Name) { return $p.Value }
    }
    return $Default
}

function To-Beats {
    param([double]$Val, [string]$Units, [double]$Tempo)
    if ($Units -eq "seconds") { return $Val * ($Tempo / 60.0) }
    return $Val
}

function Get-TrackStats {
    param($Track, [string]$Units, [double]$Tempo)
    $events = Get-Prop $Track "events" @()
    $count = 0
    $endBeat = 0.0
    foreach ($e in $events) {
        $count++
        $st = To-Beats ([double](Get-Prop $e "time" 0.0)) $Units $Tempo
        $du = To-Beats ([double](Get-Prop $e "dur" 0.0)) $Units $Tempo
        $en = $st + $du
        if ($en -gt $endBeat) { $endBeat = $en }
    }
    return [PSCustomObject]@{
        eventCount = $count
        endBeat = $endBeat
    }
}

function Get-SelectedTrackInfo {
    param($Score, [int]$SelectedTrackIdx)
    $tracks = Get-Prop $Score "tracks" @()
    if ($tracks.Count -eq 0) {
        return [PSCustomObject]@{
            index = -1
            trackCount = 0
            name = "<none>"
            type = "<none>"
            events = 0
            details = "No tracks loaded."
        }
    }

    if ($SelectedTrackIdx -lt 0) { $SelectedTrackIdx = 0 }
    if ($SelectedTrackIdx -ge $tracks.Count) { $SelectedTrackIdx = $tracks.Count - 1 }
    $track = $tracks[$SelectedTrackIdx]
    $events = Get-Prop $track "events" @()
    return [PSCustomObject]@{
        index = $SelectedTrackIdx
        trackCount = $tracks.Count
        name = [string](Get-Prop $track "name" "<unnamed>")
        type = [string](Get-Prop $track "type" "<unknown>")
        events = $events.Count
        details = ("Track {0}/{1} :: {2} [{3}] events={4}" -f ($SelectedTrackIdx + 1), $tracks.Count, (Get-Prop $track "name" "<unnamed>"), (Get-Prop $track "type" "<unknown>"), $events.Count)
    }
}

function Write-InfoPane {
    param(
        [string]$ViewName,
        $SelectedInfo
    )
    Write-Host ""
    Write-Host ("Info :: View={0} | Focus={1}" -f $ViewName, $SelectedInfo.details) -ForegroundColor Yellow
    Write-Host "Hint :: [a] arranger [m] mixer [p] piano [j] next track [k] prev track [q] quit" -ForegroundColor DarkYellow
}

function Show-ArrangerView {
    param($Score, [int]$Width, [int]$SelectedTrackIdx)
    $project = Get-Prop $Score "project" "Project"
    $tempo = [double](Get-Prop $Score "tempo" 120)
    $units = [string](Get-Prop $Score "timeUnits" "beats")
    $tracks = Get-Prop $Score "tracks" @()

    Write-Host ("MUSaiC TUI :: Arranger  | Project: {0} | Tempo: {1} | Units: {2}" -f $project, $tempo, $units) -ForegroundColor Cyan
    Write-Host ("-" * $Width)
    Write-Host ("{0,-18} {1,-10} {2,-8} {3,-10} {4}" -f "Track", "Type", "Events", "Len(beats)", "Preview")
    Write-Host ("-" * $Width)

    for ($i = 0; $i -lt $tracks.Count; $i++) {
        $track = $tracks[$i]
        $name = [string](Get-Prop $track "name" "<unnamed>")
        $type = [string](Get-Prop $track "type" "<unknown>")
        $stats = Get-TrackStats -Track $track -Units $units -Tempo $tempo
        $previewLen = [Math]::Min(40, [int][Math]::Ceiling($stats.endBeat))
        if ($previewLen -lt 1) { $previewLen = 1 }
        $bar = ("#" * $previewLen).PadRight(40, ".")
        $prefix = if ($i -eq $SelectedTrackIdx) { ">" } else { " " }
        Write-Host ("{0}{1,-18} {2,-10} {3,-8} {4,-10} [{5}]" -f $prefix, $name.Substring(0, [Math]::Min(18, $name.Length)), $type, $stats.eventCount, ([Math]::Round($stats.endBeat, 2)), $bar)
    }
}

function Show-MixerView {
    param($Score, [int]$Width, [int]$SelectedTrackIdx)
    $project = Get-Prop $Score "project" "Project"
    $tracks = Get-Prop $Score "tracks" @()
    Write-Host ("MUSaiC TUI :: Mixer     | Project: {0}" -f $project) -ForegroundColor Cyan
    Write-Host ("-" * $Width)
    Write-Host ("{0,-18} {1,-8} {2,-8} {3,-8} {4,-8} {5}" -f "Track", "Mute", "Pan", "GainDb", "Amp", "FX")
    Write-Host ("-" * $Width)
    for ($i = 0; $i -lt $tracks.Count; $i++) {
        $track = $tracks[$i]
        $name = [string](Get-Prop $track "name" "<unnamed>")
        $mute = [string](Get-Prop $track "mute" $false)
        $pan = [string](Get-Prop $track "pan" 0.0)
        $gainDb = [string](Get-Prop $track "gainDb" 0.0)
        $amp = [string](Get-Prop $track "amp" 1.0)
        $fx = Get-Prop $track "effects" @()
        $fxNames = @()
        foreach ($f in $fx) {
            $fxNames += [string](Get-Prop $f "type" "fx")
        }
        $fxStr = if ($fxNames.Count -gt 0) { $fxNames -join " > " } else { "-" }
        $shortName = $name.Substring(0, [Math]::Min(18, $name.Length))
        $prefix = if ($i -eq $SelectedTrackIdx) { ">" } else { " " }
        Write-Host ("{0}{1,-18} {2,-8} {3,-8} {4,-8} {5,-8} {6}" -f $prefix, $shortName, $mute, $pan, $gainDb, $amp, $fxStr)
    }
}

function Show-PianoView {
    param($Score, [int]$Width, [int]$SelectedTrackIdx)
    $project = Get-Prop $Score "project" "Project"
    $tempo = [double](Get-Prop $Score "tempo" 120)
    $units = [string](Get-Prop $Score "timeUnits" "beats")
    $tracks = Get-Prop $Score "tracks" @()

    $synthTrack = $null
    if ($tracks.Count -gt 0 -and $SelectedTrackIdx -ge 0 -and $SelectedTrackIdx -lt $tracks.Count) {
        $candidate = $tracks[$SelectedTrackIdx]
        if ((Get-Prop $candidate "type" "") -eq "synth") {
            $synthTrack = $candidate
        }
    }
    if ($null -eq $synthTrack) {
        foreach ($t in $tracks) {
            if ((Get-Prop $t "type" "") -eq "synth") { $synthTrack = $t; break }
        }
    }
    if ($null -eq $synthTrack) {
        Write-Warning "No synth track found for piano view."
        return
    }
    $trackName = [string](Get-Prop $synthTrack "name" "synth")
    $events = Get-Prop $synthTrack "events" @()
    if ($events.Count -eq 0) {
        Write-Warning "Synth track '$trackName' has no events."
        return
    }

    $minPitch = 127
    $maxPitch = 0
    $maxBeat = 0.0
    foreach ($e in $events) {
        $p = [int](Get-Prop $e "pitch" 60)
        if ($p -lt $minPitch) { $minPitch = $p }
        if ($p -gt $maxPitch) { $maxPitch = $p }
        $st = To-Beats ([double](Get-Prop $e "time" 0.0)) $units $tempo
        $du = To-Beats ([double](Get-Prop $e "dur" 0.0)) $units $tempo
        $en = $st + $du
        if ($en -gt $maxBeat) { $maxBeat = $en }
    }
    if (($maxPitch - $minPitch) -gt 24) { $minPitch = $maxPitch - 24 }
    $gridCols = [Math]::Min(64, [Math]::Max(16, [int][Math]::Ceiling($maxBeat)))
    $rows = @()
    for ($pitch = $maxPitch; $pitch -ge $minPitch; $pitch--) {
        $line = New-Object System.Text.StringBuilder
        for ($x = 0; $x -lt $gridCols; $x++) { [void]$line.Append(".") }
        foreach ($e in $events) {
            $ep = [int](Get-Prop $e "pitch" 60)
            if ($ep -ne $pitch) { continue }
            $st = To-Beats ([double](Get-Prop $e "time" 0.0)) $units $tempo
            $du = To-Beats ([double](Get-Prop $e "dur" 0.25)) $units $tempo
            $sIdx = [Math]::Max(0, [int][Math]::Floor($st))
            $eIdx = [Math]::Min($gridCols - 1, [int][Math]::Ceiling($st + $du) - 1)
            for ($i = $sIdx; $i -le $eIdx; $i++) {
                $line[$i] = "#"
            }
        }
        $rows += ("{0,3} |{1}" -f $pitch, $line.ToString())
    }

    Write-Host ("MUSaiC TUI :: PianoRoll | Project: {0} | Track: {1}" -f $project, $trackName) -ForegroundColor Cyan
    Write-Host ("-" * $Width)
    foreach ($r in $rows) { Write-Host $r }
    Write-Host ("-" * $Width)
    Write-Host "Legend: # note / . empty"
}

if (-not (Test-Path $ScorePath)) {
    throw "Score not found: $ScorePath"
}

$score = Get-Content -Raw $ScorePath | ConvertFrom-Json

function Render-View {
    param([int]$SelectedTrackIdx)
    switch ($View) {
        "arranger" { Show-ArrangerView -Score $score -Width $Width -SelectedTrackIdx $SelectedTrackIdx }
        "mixer" { Show-MixerView -Score $score -Width $Width -SelectedTrackIdx $SelectedTrackIdx }
        "piano" { Show-PianoView -Score $score -Width $Width -SelectedTrackIdx $SelectedTrackIdx }
    }
}

$selectedTrackIdx = 0
$selectedInfo = Get-SelectedTrackInfo -Score $score -SelectedTrackIdx $selectedTrackIdx

if (-not $Interactive) {
    Render-View -SelectedTrackIdx $selectedTrackIdx
    Write-InfoPane -ViewName $View -SelectedInfo $selectedInfo
    exit 0
}

while ($true) {
    Clear-Host
    $selectedInfo = Get-SelectedTrackInfo -Score $score -SelectedTrackIdx $selectedTrackIdx
    Render-View -SelectedTrackIdx $selectedTrackIdx
    Write-InfoPane -ViewName $View -SelectedInfo $selectedInfo
    $k = Read-Host "Choose view"
    if ($k -eq "q") { break }
    if ($k -eq "a") { $View = "arranger" }
    if ($k -eq "m") { $View = "mixer" }
    if ($k -eq "p") { $View = "piano" }
    if ($k -eq "j") { $selectedTrackIdx++ }
    if ($k -eq "k") { $selectedTrackIdx-- }
    $count = $selectedInfo.trackCount
    if ($count -gt 0) {
        if ($selectedTrackIdx -lt 0) { $selectedTrackIdx = 0 }
        if ($selectedTrackIdx -ge $count) { $selectedTrackIdx = $count - 1 }
    }
}
