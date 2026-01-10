---
name: cdp-cli
description: Use the Composer Desktop Project (CDP/CDPR8) CLI tools to synthesize, process, and render audio via CDP binaries (synth.exe, pitch.exe, pvoc.exe, etc.), plus helper scripts in this repo. Trigger when working with CDP audio generation, sequencing, effects, or playback via the command line.
---

# CDP CLI Skill

## Paths
- CDP root: `F:\CDP\CDPR8`
- CDP binaries: `F:\CDP\CDPR8\_cdp\_cdprogs`
- Helper scripts (repo): 
    - **CDP Sequencer** (`cdp-sequencer.ps1`): 
      - Renders JSON scores to WAV/MP3.
      - Supports Synth and Sample tracks.
      - Features: Beat timing, Effects (reverb/pitch), Sample trimming/looping.
      - Mixer: Per-track `gainDb`, `pan`, and `mute`. Pan uses safe arithmetic; Synth Amp is folded into gain.
      - Usage: `.\cdp-sequencer.ps1 -ScorePath score.json -OutWav "my_song.wav" -Play`
      - Flags: `-OutWav <path>`, `-OutMp3 <path>`, `-Play`, `-KeepTemp`.
    - **CDP Wrapper** (`cdp-wrapper.ps1`): Simple menu for rendering.
    - **Session Composer** (`music-session.ps1`): Generates scores from JSON sessions.
    - **Analysis** (`cdp-analyze.ps1`): Outputs JSON/Text to `output/analysis/` with BPM, pitch, loudness, duration, and warnings.
    - **Transform** (`cdp-transform.ps1`): Supports `-ConfigPath`; `-Method pvoc` automatically bypasses legacy tool issues by checking for `stretch`/`strans` first.
- **Assets**: `examples/kick.wav` (generated test sample).
- Outputs: `F:\CDP\output`

## Quick Usage
### DAW / Sequencer (Recommended)
- **Interactive Menu**: `.\cdp-wrapper.ps1` (Selects and renders JSON scores from `examples/`)
- **Direct Render**: `.\cdp-sequencer.ps1 -ScorePath examples\effects_demo.json -Play`

### Single Configs
- Tone via JSON: `.\cdp-synth.ps1 -ConfigPath .\examples\simple-tone.json`
- Preset tone: `.\cdp-quickjam.ps1 -ToMp3 [-Play]`

## JSON Score Schema (`cdp-sequencer.ps1`)
Scores define tracks, effects, and events.
```json
{
  "project": "My Song",
  "tempo": 120,
  "timeUnits": "beats", // Converts time/dur/offset to seconds based on tempo
  "tracks": [
    {
      "name": "Bass",
      "type": "synth",
      "waveform": "square",
      "amp": 0.5,
      "effects": [{ "type": "reverb", "room_size": 2.0 }],
      "events": [{ "time": 0.0, "dur": 1.0, "pitch": 60 }]
    },
    { 
      "name": "Kick", "type": "sample", "source": "examples/kick.wav",
      "events": [{ "time": 0, "dur": 1 }] 
    }
  ]
}
```
See `examples/beat_score.json`, `examples/sample_beat_test.json`, `examples/mixer_demo.json`, and `examples/sample_loop_demo.json` for live examples.

## Common CDP binaries
- `synth.exe`: generate waveforms (sine/square/saw/ramp)
- `reverb.exe`: Apply reverb (supported in sequencer effects)
- `modify.exe`: Pitch/speed modification (supported in sequencer effects)
- `sndinfo.exe`: Inspect audio properties
- `paplay.exe`: Playback utility

## Workflow Tips
- **Sequencing**: Prefer `cdp-sequencer.ps1` for multi-track or effects-heavy work.
- **Paths**: Avoid spaces in file paths (CDP requirement).
- **Mixing**: The sequencer uses `ffmpeg` `adelay`+`amix` to combine stems. If pan/gain filters fail, it warns and keeps the raw stem.
- **Extending**: Add new effects to `Apply-Effect` in `cdp-sequencer.ps1`.
