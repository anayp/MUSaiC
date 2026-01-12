# CDP DAW Workflow (Antigravity)

This repo now includes a JSON-driven sequencer and TUI for composing with CDP.

## Quick Start
Run the interactive loader (menu):
```powershell
.\cdp-wrapper.ps1
```
Or run the sequencer directly:
```powershell
.\cdp-sequencer.ps1 -ScorePath examples\beat_score.json -Play
```
CLI- **Parameters**:
  - `-ScorePath <path>`: JSON score file (default `examples/effects_demo.json`)
  - `-OutWav <path>`: Output WAV filename
  - `-OutMp3 <path>`: Optional MP3 conversion
  - `-Play` (switch): Auto-play result.
  - `-KeepTemp`: Preserve temporary note files (debug only). Default removes them.
  - `-MetaPath <path>` (optional): Path to `meta.json` project context.
  - `-MasterLufs <double>` (optional): Target Integrated LUFS (e.g. -14).
  - `-MasterLimitDb <double>` (optional): True Peak Limit in dB (e.g. -1.0).
  - `-MasterGlue` (optional switch): Applies bus compression (ratio 2:1, slow attack) before mastering.
- **Mixer**:
  - Supports `gainDb`, `pan` (-1.0 to 1.0), and `mute`.
  - Synth tracks are generated at full amplitude; track `amp` is converted to dB and applied at mix time.
- **Example**: `.\cdp-sequencer.ps1 -ScorePath examples\mixer_demo.json -OutWav output\mix.wav`

## JSON Score Schema
Scores are defined in JSON files.
```json
{
  "project": "Song Name",
  "tempo": 120,
  "timeUnits": "beats", // "beats" or "seconds" (default).
  // If "beats", ALL time/dur/offset values are treated as beats and converted to seconds based on tempo.
  "tracks": [
    {
      "name": "Bass",
      "type": "synth",
      "waveform": "square", // sine, square, saw, ramp
      "amp": 0.5,
      "effects": [
          { "type": "reverb", "room_size": 2.0, "mix": 0.5 },
          { "type": "pitch", "semitones": -12 },
          { "type": "tremolo", "depth": 0.9, "wubsPerBeat": 2 }
      ],
      // Track-level controls
      // Looping:
      // - `loop`: true/false
      // - `loopCount`: Number of *repeats* (so `2` plays 3 times total).
      // - `loopDur`: Total duration in seconds (overrides count).
      // Mixer:
      // - `gainDb`: Volume adjustment in decibels (e.g. `-3.0`, `6.0`).
      // - `pan`: Stereo placement from `-1.0` (Left) to `1.0` (Right).
      // - `mute`: Set `true` to silence the track.
      "events": [
        { "time": 0.0, "dur": 1.0, "pitch": 60 }, // pitch in MIDI notes
        { "time": 1.0, "dur": 0.5, "pitch": 62 }
      ]
    },
    {
      "name": "Drums",
      "type": "sample",
      "source": "examples/kick.wav", 
      "amp": 1.0,
      "gainDb": -2.0,
      "pan": -0.5,
      "events": [
        { 
            "time": 0.0, "dur": 0.25, 
            "loop": true, "loopCount": 4 
        },
        { "time": 2.0, "dur": 0.5, "offset": 0.2 }
      ]
    }
  ]
}
```
Example with looping and mixer controls:
```json
{
  "name": "Kick",
  "type": "sample",
  "source": "kick.wav",
  "gainDb": -2.0,
  "pan": -0.5,
  "events": [
    { "time": 0, "dur": 1, "loop": true, "loopCount": 3 }
  ]
}
```
See:
- `examples/mixer_demo.json`
- `examples/sample_loop_demo.json`

Tremolo notes:
- `wubsPerBeat` converts to LFO frequency (Hz): `rateHz = wubsPerBeat * tempo / 60`.
- `rateMap` may be used for automation:
  ```json
  "effects": [
    {
      "type": "tremolo",
      "depth": 0.9,
      "rateMap": [
        { "time": 0, "wubsPerBeat": 1 },
        { "time": 8, "wubsPerBeat": 2 }
      ]
    }
  ]
  ```

### 6. Music Theory (`cdp-theory.ps1`)
`cdp-theory.ps1 -ScorePath <json> [-OutJson <path>]`
Analyzes a MUSaiC JSON score for harmonic content.
- **Key Detection**: Uses Krumhansl-Schmuckler profiles (Major/Minor/Modes).
- **Chords**: Windowed chord detection (Triads, 7ths, Sus).
- **Roman Numerals**: Maps chords to key (e.g. `V`, `iv`, `I`).
- **Cadences**: Detects V-I, IV-I resolution points.
- **Histograms**: Pitch Class (Durational) and Scale Degree usage.
- **Metrics**: Voice leading stats, stepwise movement ratio, range.

#### Theory JSON Output
- `key`: "C Major"
- `key_candidates`: Top 3 [{Root, Type, Score}...]
- `pitch_class_histogram`: Array[12] of durations per PC.
- `scale_degree_histogram`: Array[12] of durations relative to key root.
- `chords`: List of {Start, Name, Roman}
- `cadences`: List of strings descibing cadence points.


### 7. Helper Tools
### Analysis (`cdp-analyze.ps1`)
`cdp-analyze.ps1 -InputFile <wav>`
Returns JSON object with:
- `analysis.tempo_bpm`, `analysis.tempo_method`, `analysis.tempo_confidence`
- `analysis.tempo_candidates` (IOI + ffmpeg)
- `analysis.beat_grid` (seconds)
- `analysis.onsets` (count, density, times)
- `analysis.pitch_analysis` (dominant_hz, histogram, candidates, stability)
- `analysis.key_estimate`, `analysis.chords_audio`
- `analysis.loop_analysis` (loop_candidate, loop_score, loop_offset_ms + metrics)
- `analysis.rms_db`, `analysis.peak_db`, `analysis.crest_db`, `analysis.lufs_i`
- `analysis.duration`
- `analysis.theory` (merged when score is provided)
- `warnings`

Optional:
- `-ScorePath <json>` and `-MetaPath <json>` for consistency checks.
- `-TargetLufs <double>`: Validates output against target (+/- 1.0 LU).
- `-OnsetThresholdDb` / `-OnsetMinDur`: Tuning for onset detection.
```powershell
.\cdp-analyze.ps1 -InputFile "loop.wav"
# Outputs:
#   output/analysis/loop.json (or configured outputDir/analysis/_...)
#   output/analysis/loop.txt
```
Warnings are in `warnings` array (e.g., clipping, silence, key mismatch).

### Transformation (`cdp-transform.ps1`)
```powershell
.\cdp-transform.ps1 -Mode tempo -In kick.wav -Out slow.wav -Amount 80
# Use JSON Config:
.\cdp-transform.ps1 -ConfigPath examples/transform_pvoc.json -In kick.wav -Out modified.wav
```
Notes:
- `-Method fast` uses `modify speed` (reliable, changes pitch + tempo together).
- `-Method pvoc` attempts independent time/pitch. Advanced PVOC params are ignored for reliability. Falls back to fast if PVOC fails.

### Session Composer (`music-session.ps1`)
Generate a sequencer score from high-level session data.
```powershell
.\music-session.ps1 -SessionPath examples/musaic_session.json -OutputPath examples/musaic_generated.json
.\cdp-sequencer.ps1 -ScorePath examples/musaic_generated.json
```

### Metadata (`cdp-meta.ps1`)
Manage global project context.
```powershell
.\cdp-meta.ps1 -Init meta.json
.\cdp-meta.ps1 -Update meta.json -Set "sections.0.name=Verse"
```

## Scripts
- **cdp-sequencer.ps1**: Core engine. Parses JSON, renders synth notes via `synth.exe`, trims samples via `ffmpeg`, applies effects (reverb/pitch/tremolo), and mixes everything.
- Mixer note: if `ffmpeg` pan/gain filters error, the sequencer warns and keeps the raw stem.
- **cdp-wrapper.ps1**: Interactive menu to browse `examples/*.json` and render/play them.
- **cdp-meta.ps1**: CLI for managing `meta.json` files.

## Requirements
## Requirements
- Run `.\musaic.ps1 setup` to configure paths.
- CDP `synth.exe`, `reverb.exe`, `modify.exe` (configured via `musaic.config.json`).
- `ffmpeg` (configured via `musaic.config.json` or PATH).

## Project Planning
- Gap analysis and roadmap: `docs/DAW_GAPS.md`
- Ticket log: `docs/TICKETS.md`
- Release notes: `CHANGELOG.md`
