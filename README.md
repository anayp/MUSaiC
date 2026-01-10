# MUSaiC Project Documentation

## Overview
MUSaiC is a CLI-first, AI-driven DAW system that composes, renders, and analyzes music through a structured project model. It combines CDP (Composer's Desktop Project) DSP tools with a sequencing/rendering engine, plus optional VST hosting for instrument and FX chains. The goal is to let a CLI agent author a full song conversationally, then render, iterate, and audit the output with analysis data.

## Vision
Enable a conversational workflow where a user can describe a musical intent (form, tempo, key, instrumentation, FX) and MUSaiC builds a renderable session that can be refined over time.

Example goal:
```
"Create an intro at 140 BPM in D mixolydian, move into Em for the verse.
Use arpeggios and pads, Iris for instruments, BreakTweaker preset 3 for beats."
```

## Core Concepts
- **Session**: The full project state (tempo map, key centers, sections, tracks, plugins, automation, assets).
- **Section**: A labeled song segment (intro, verse, chorus) with local harmony and instrumentation rules.
- **Track**: A signal path with a source (synth/sample/VST) and a chain of effects.
- **Clip/Event**: Time-stamped data for notes, samples, automation, or pattern triggers.
- **Project Metadata**: Persistent musical context (tempo, key, scale, sections, notes) stored alongside scores for cross-machine continuity.
- **Render Graph**: Offline render plan that maps the session to actual audio files.

## MVP Capabilities (Today)
- JSON-driven sequencing for synth and sample tracks.
- Beat or second time units.
- Offline mixdown with ffmpeg.
- Per-track mixer controls (gainDb, pan, mute). Pan uses parser-safe arithmetic.
- **Synth Amp**: Folded into mixer gain (amp -> dB) to avoid binary crashes.
- Sample looping for clip events; Auto-cleanup of temp files (`-KeepTemp` to override).
- Basic effects via CDP (reverb, pitch/varispeed).
- Sample analysis (BPM, pitch estimate, RMS/peak, duration, warnings).
- Time/pitch transforms via robust tool selection (tries `stretch`/`strans` first, falls back to `modify`).
- **TUI Timeline**: `cdp-timeline.ps1` for lightweight ASCII score visualization.

## Target Capabilities
1) **Composition**
   - Section-based arrangement (intro/verse/chorus/bridge/outro).
   - Key/mode-aware note generation.
   - Chord/scale constraints for arps and pads.
2) **Audio Engine**
   - Robust render graph: stems, buses, sends/returns, master chain.
   - Looping, slicing, crossfades, and clip-level automation.
3) **Plugin Hosting**
   - VST instruments/FX (Izotope Iris, BreakTweaker).
   - Parameter automation and preset recall.
4) **Analysis**
   - Beat detection, pitch estimation, loudness/crest/RMS metrics.
   - Ability to validate that output matches target intent.
5) **CLI + TUI**
   - Interactive selection and render triggers.
   - Structured commands for analysis and transforms.

## Architecture

### 1) Project Model
Canonical JSON or YAML representation of a session.
- `session.json` stores global project data.
- `score.json` stores note/sample events.
- `meta.json` stores persistent musical context (tempo, key, scale, sections, notes).
- `analysis.json` stores computed analysis output.

### 2) Sequencing + Rendering
- Build event timelines per track.
- Render sources (CDP synth, samples, VST host).
- Apply per-track FX.
- Mix buses, then master.

### 3) Analysis Layer
Offline analysis scripts produce:
- Tempo, beat grid, onset density.
- Pitch contour or dominant pitch class.
- Loudness (RMS/LUFS), peak, crest factor.
Current CLI output (`cdp-analyze.ps1`) includes BPM, pitch estimate (Hz), RMS/peak dB, duration, and warnings for missing estimates.

### 4) Plugin Hosting Strategy
Two viable approaches:
1) **Reaper integration**
   - Use ReaScript + Reaper CLI to load tracks/FX and render.
   - Supports Reaper JSFX, VST, and presets.
2) **Standalone VST host**
   - Carla or custom host to render VST instruments offline.
   - Scriptable parameter automation via config.

## Data Model (Draft)
Minimal session shape for future:
```json
{
  "project": "MUSaiC Demo",
  "tempo": 140,
  "timeUnits": "beats",
  "sections": [
    { "name": "intro", "length": 16, "key": "D mixolydian" },
    { "name": "verse", "length": 32, "key": "E minor" }
  ],
  "tracks": [
    {
      "name": "arp",
      "type": "synth",
      "waveform": "saw",
      "amp": 0.5,
      "events": []
    },
    {
      "name": "pad",
      "type": "vst",
      "plugin": "Izotope Iris",
      "preset": "User/Pad01",
      "events": []
    },
    {
      "name": "drums",
      "type": "vst",
      "plugin": "BreakTweaker",
      "preset": "UserPreset3",
      "events": []
    }
  ]
}
```

## CLI Surface (Planned)
- `cdp-sequencer.ps1`: render CDP-based tracks from JSON.
- `cdp-analyze.ps1`: analyze audio (tempo, pitch, loudness).
- `cdp-transform.ps1`: quick time/pitch changes or advanced transforms.
- `music-session.ps1`: session-level build (sections, arrangement, export).
- `cdp-wrapper.ps1`: menu-based score selection and render.

## Constraints
- Offline rendering first; real-time playback is optional.
- ASCII-only config and logs.
- Avoid paths with spaces for CDP compatibility.

## Phased Roadmap
1) **Phase A: Stability + Validation**
   - Solid score validation, robust routing, clear errors.
2) **Phase B: Analysis**
   - Beat/pitch detection and loudness reports.
3) **Phase C: Plugin Hosting**
   - Reaper or VST host integration for Iris/BreakTweaker.
4) **Phase D: Arrangement Engine**
   - Section-based composition and evolution over time.
5) **Phase E: Metadata Continuity**
   - Persistent metadata files for tempo/key/scale/notes across sessions and machines.
6) **Phase F: Loudness Pass (Done)**
   - `-MasterLimitDb <dB>` and `-MasterLufs` implemented.
   - Analysis reports `lufs_i` via `ebur128`.

## Future: Polishing
- Improve analysis accuracy (pitch detection mode).
- TUI enhancements.

## Open Questions
- Preferred VST host path: Reaper integration vs standalone?
- Where should preset libraries live and how are they referenced?
- Required output formats (WAV/MP3/stems/project file)?
