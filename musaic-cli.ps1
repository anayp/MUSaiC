param(
    [Parameter(Position = 0)]
    [ValidateSet("help", "list-examples", "inspect-score", "timeline", "tui", "render", "preview", "doctor")]
    [string]$Command = "help",

    [string]$ScorePath,
    [string]$MetaPath,
    [string]$OutWav,
    [string]$OutMp3,
    [switch]$Play,
    [switch]$KeepTemp,
    [ValidateSet("bars", "beats", "ticks")]
    [string]$Resolution = "beats",
    [int]$Width = 120,
    [ValidateSet("arranger", "mixer", "piano")]
    [string]$View = "arranger",
    [switch]$Interactive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Show-Help {
    Write-Host "MUSaiC CLI QoL Wrapper" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  ./musaic-cli.ps1 <command> [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  help            Show this help text"
    Write-Host "  list-examples   List JSON score files in ./examples"
    Write-Host "  inspect-score   Print score summary and quick validation"
    Write-Host "  timeline        Show ASCII timeline view (delegates cdp-timeline.ps1)"
    Write-Host "  tui             Show DAW-like ASCII views (arranger/mixer/piano)"
    Write-Host "  render          Render with cdp-sequencer.ps1"
    Write-Host "  preview         Render a low-res preview (delegates cdp-sequencer.ps1 -Preview)"
    Write-Host "  doctor          Run environment checks (delegates musaic.ps1 doctor)"
    Write-Host ""
    Write-Host "Common options:"
    Write-Host "  -ScorePath <path>    Score JSON path (required for inspect-score/timeline/render/preview)"
    Write-Host "  -MetaPath <path>     Optional meta.json path for render/preview"
    Write-Host "  -OutWav <path>       Optional output WAV path for render/preview"
    Write-Host "  -OutMp3 <path>       Optional output MP3 path for render/preview"
    Write-Host "  -Play                Auto-play after render/preview"
    Write-Host "  -KeepTemp            Keep sequencer temp files"
    Write-Host "  -Resolution <value>  bars|beats|ticks for timeline (default: beats)"
    Write-Host "  -Width <int>         Timeline width (default: 120)"
    Write-Host "  -View <value>        arranger|mixer|piano for tui command"
    Write-Host "  -Interactive         Interactive TUI mode (switch views in terminal)"
}

function Get-ScoreSummary {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Score file not found: $Path"
    }

    $score = Get-Content -Raw -Path $Path | ConvertFrom-Json

    if (-not $score.tracks) {
        throw "Score is missing required 'tracks' array: $Path"
    }

    $tempo = if ($score.PSObject.Properties["tempo"]) { [double]$score.tempo } else { 120.0 }
    $timeUnits = if ($score.PSObject.Properties["timeUnits"]) { [string]$score.timeUnits } else { "seconds" }
    if ($timeUnits -ne "seconds" -and $timeUnits -ne "beats") {
        throw "Invalid timeUnits '$timeUnits'. Use 'seconds' or 'beats'."
    }

    $project = if ($score.PSObject.Properties["project"]) { [string]$score.project } else { "(unnamed)" }
    $trackCount = 0
    $eventCount = 0
    $maxTime = 0.0
    $types = @{}

    foreach ($track in $score.tracks) {
        $trackCount++
        $tname = if ($track.PSObject.Properties["name"]) { [string]$track.name } else { "<unnamed>" }
        $ttype = if ($track.PSObject.Properties["type"]) { [string]$track.type } else { "<missing>" }
        if (-not $types.ContainsKey($ttype)) { $types[$ttype] = 0 }
        $types[$ttype]++

        if (-not $track.events) {
            Write-Warning "Track '$tname' has no events."
            continue
        }

        foreach ($evt in $track.events) {
            if (-not $evt.PSObject.Properties["time"]) { throw "Track '$tname' has event missing 'time'." }
            if (-not $evt.PSObject.Properties["dur"]) { throw "Track '$tname' has event missing 'dur'." }
            $eventCount++

            $start = [double]$evt.time
            $dur = [double]$evt.dur
            $end = $start + $dur
            if ($end -gt $maxTime) { $maxTime = $end }
        }
    }

    $estimatedSec = if ($timeUnits -eq "beats") { $maxTime * (60.0 / $tempo) } else { $maxTime }

    [PSCustomObject]@{
        Path = [System.IO.Path]::GetFullPath($Path)
        Project = $project
        Tempo = $tempo
        TimeUnits = $timeUnits
        TrackCount = $trackCount
        EventCount = $eventCount
        MaxTime = [Math]::Round($maxTime, 3)
        DurationSeconds = [Math]::Round($estimatedSec, 3)
        TrackTypes = ($types.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0}:{1}" -f $_.Name, $_.Value }) -join ", "
    }
}

function Require-ScorePath {
    if ([string]::IsNullOrWhiteSpace($ScorePath)) {
        throw "-ScorePath is required for command '$Command'."
    }
}

switch ($Command) {
    "help" {
        Show-Help
    }
    "list-examples" {
        $examplesDir = Join-Path $PSScriptRoot "examples"
        if (-not (Test-Path $examplesDir)) {
            throw "examples directory not found: $examplesDir"
        }
        $scores = Get-ChildItem -Path $examplesDir -Filter "*.json" | Sort-Object Name
        if ($scores.Count -eq 0) {
            Write-Host "No JSON score files found in $examplesDir" -ForegroundColor Yellow
            exit 0
        }
        for ($i = 0; $i -lt $scores.Count; $i++) {
            Write-Host ("[{0,2}] {1}" -f $i, $scores[$i].Name)
        }
    }
    "inspect-score" {
        Require-ScorePath
        $summary = Get-ScoreSummary -Path $ScorePath
        $summary | Format-List
    }
    "timeline" {
        Require-ScorePath
        & (Join-Path $PSScriptRoot "cdp-timeline.ps1") -ScorePath $ScorePath -Resolution $Resolution -Width $Width
    }
    "tui" {
        Require-ScorePath
        $args = @("-ScorePath", $ScorePath, "-View", $View, "-Width", $Width)
        if ($Interactive) { $args += "-Interactive" }
        & (Join-Path $PSScriptRoot "musaic-tui.ps1") @args
    }
    "render" {
        Require-ScorePath
        $args = @("-ScorePath", $ScorePath)
        if ($MetaPath) { $args += @("-MetaPath", $MetaPath) }
        if ($OutWav) { $args += @("-OutWav", $OutWav) }
        if ($OutMp3) { $args += @("-OutMp3", $OutMp3) }
        if ($Play) { $args += "-Play" }
        if ($KeepTemp) { $args += "-KeepTemp" }
        & (Join-Path $PSScriptRoot "cdp-sequencer.ps1") @args
    }
    "preview" {
        Require-ScorePath
        $args = @("-ScorePath", $ScorePath, "-Preview")
        if ($MetaPath) { $args += @("-MetaPath", $MetaPath) }
        if ($OutWav) { $args += @("-OutWav", $OutWav) }
        if ($OutMp3) { $args += @("-OutMp3", $OutMp3) }
        if ($Play) { $args += "-Play" }
        if ($KeepTemp) { $args += "-KeepTemp" }
        & (Join-Path $PSScriptRoot "cdp-sequencer.ps1") @args
    }
    "doctor" {
        & (Join-Path $PSScriptRoot "musaic.ps1") doctor
    }
    default {
        Show-Help
    }
}
