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
  - `-Play`: Auto-play result
  - `-KeepTemp`: Preserve temporary note files (debug only). Default removes them.
  - `-MetaPath <path>`: Optional `meta.json` source for global context (Tempo default).
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
          { "type": "pitch", "semitones": -12 }
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

## 5. Helper Tools
### Analysis (`cdp-analyze.ps1`)
Standardized JSON analysis including BPM, pitch estimate, loudness, and duration.
```powershell
.\cdp-analyze.ps1 -InputFile "loop.wav"
# Outputs:
#   output/analysis/loop.json (analysis + warnings)
#   output/analysis/loop.txt (human-readable summary)
```
JSON fields:
- `analysis.tempo_bpm`
- `analysis.pitch_hz`
- `analysis.rms_db`
- `analysis.peak_db`
- `analysis.duration`
- `warnings` (array)


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
- **cdp-sequencer.ps1**: Core engine. Parses JSON, renders synth notes via `synth.exe`, trims samples via `ffmpeg`, applies effects (reverb/pitch), and mixes everything.
- Mixer note: if `ffmpeg` pan/gain filters error, the sequencer warns and keeps the raw stem.
- **cdp-wrapper.ps1**: Interactive menu to browse `examples/*.json` and render/play them.
- **cdp-meta.ps1**: CLI for managing `meta.json` files.

## Requirements
- CDP `synth.exe`, `reverb.exe`, `modify.exe` in local `CDPR8\_cdp\_cdprogs`.
- `ffmpeg` in PATH.
