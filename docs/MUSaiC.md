# MUSaiC Project Documentation

## Overview
MUSaiC is a CLI-first, automation-driven DAW system that composes, renders, and analyzes music through a structured project model. It combines CDP (Composer's Desktop Project) DSP tools with a sequencing/rendering engine, plus plugin discovery and future hosting for instrument and FX chains. The goal is to let a CLI workflow author a full song iteratively, then render, refine, and audit the output with analysis data.


## Setup
To initialize the environment and configuration:

```powershell
./musaic.ps1 setup -CdpRoot ./CDPR8
```

To verify the installation:
```powershell
./musaic.ps1 doctor
```

## Vision
Enable an interactive workflow where a user can describe a musical intent (form, tempo, key, instrumentation, FX) and MUSaiC builds a renderable session that can be refined over time.

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

## Project Metadata
MUSaiC projects use a standalone `meta.json` file to store persistent context, allowing instruments and scores to share global settings like tempo and key without rigorous coupling.

### CLI Usage (`cdp-meta.ps1`)
- **Initialize**: `.\cdp-meta.ps1 -Init meta.json` (Creates from template)
- **View**: `.\cdp-meta.ps1 -Show meta.json` (Displays Identity, Context, Sections)
- **Update**: `.\cdp-meta.ps1 -Update meta.json -Set "key=value"`
  - Supports dot-notation for nested fields: `-Set "sections.0.name=Verse1"`
  - Auto-converts numbers and booleans.

### Sequencer Integration
`cdp-sequencer.ps1` accepts an optional `-MetaPath` argument. If provided, it loads the metadata and uses its values as fallbacks for missing score properties:
- `tempo`: If not in score, read from `meta.tempo`.
- `timeUnits`: If not in score, read from `meta.timeUnits`.

## MVP Capabilities (Today)
- JSON-driven sequencing for synth and sample tracks.
- Beat or second time units.
- Configurable output directory (defaults to `./output`, set via `musaic.config.json`).
- Offline mixdown with ffmpeg.
- Per-track mixer controls (gainDb, pan, mute). Pan uses parser-safe arithmetic.
- **Synth Amp**: Folded into mixer gain (amp -> dB) to avoid binary crashes.
- Sample looping for clip events; Auto-cleanup of temp files (`-KeepTemp` to override).
- Basic effects (reverb, pitch/varispeed, tremolo LFO).
- Sample analysis (BPM, pitch estimate, RMS/peak, duration, warnings).
- Time/pitch transforms via robust tool selection (tries `stretch`/`strans` first, falls back to `modify`).
- **Loudness Pass**: `-MasterLufs` (loudnorm) and `-MasterLimitDb` (alimiter) for broadcast-ready levels.
- **Theory**: `cdp-theory.ps1` (Key, Chords, Roman Numerals).
- **TUI Timeline**: `cdp-timeline.ps1` for lightweight ASCII score visualization.
### Rendering Engines
1.  **Native**: The built-in CDP synthesis engine (`synth.exe`, `reverb.exe`).
2.  **FluidSynth**: Renders via `fluidsynth` (CLI) using SoundFonts.
3.  **Plugin Registry**: MUSaiC provides a script `musaic-plugins.ps1` to index VST/VST3/AU/SF2 files on your system.
    - Note: MUSaiC can host VSTs via **Carla CLI** (prototype; headless render depends on version/OS).
    - Usage: `scan` to index, `list` to view.
    - Render: `./musaic-carla.ps1 -Command render -PluginPath <path> -OutWav <path>`


## Target Capabilities
1) **Composition**
   - Section-based arrangement (intro/verse/chorus/bridge/outro).
   - Key/mode-aware note generation.
   - Chord/scale constraints for arps and pads.
2) **Audio Engine**
   - Robust render graph: stems, buses, sends/returns, master chain.
   - Looping, slicing, crossfades, and clip-level automation.
3) **Plugin Hosting**
   - VST/VST3/AU instruments and FX (user-supplied).
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
Current CLI output (`cdp-analyze.ps1`) includes tempo candidates, beat grid, pitch histograms, key/chords, loop metrics, RMS/peak, LUFS, duration, and warnings for missing estimates.

### 4) Plugin Hosting Strategy
Two viable approaches:
1) **Standalone VST host**
   - **Solution**: **Carla CLI** (headless mode).
   - **Plan**: See `docs/CARLA_PLAN.md` for integration details.
   - **Tooling**: `musaic-carla.ps1` enables offline render workflows.
   - **Why**: Supports VST2/3, AU, LV2 across platforms without building a custom host.
2) **Host-agnostic plugin registry**
   - Index-only discovery for VST/VST3/AU/SF2 assets until a host backend lands.

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
   - `lufs_i` reporting (EBU R128).
   - **Theory**: Symbolic analysis of JSON scores (Key, Chords, Cadences).
   - **Analysis v2**: Automatic extraction of BPM, Key, Chords, Pitch Histograms, and Loop seam quality from audio.
   - Merges symbolic theory data (from scores) with audio analysis for consistency checking.
   - **Metrics**: Crest Factor (dynamics), Onset Density (complexity).
3) **Phase C: Plugin Hosting**
   - Standalone host integration for VST/VST3/AU instruments and FX.
4) **Phase D: Arrangement Engine**
   - Section-based composition and evolution over time.

## Missing Systems (Shortlist)
See `docs/DAW_GAPS.md` and `docs/TICKETS.md` for the full backlog and tool choices. Highlights:
- Project state + asset catalog (Postgres).
- Render graph + job cache (hash-based).
- Plugin host backend (Carla).
- MIDI engine + tempo maps + automation envelopes.
- Analysis upgrade (Essentia/Aubio) and time/pitch (Rubber Band/SoundTouch).
- Sample library management, routing matrix, and undo history.

## Open Questions
- Where should preset libraries live and how are they referenced?
- Required output formats (WAV/MP3/stems/project file)?
