# MUSaiC Project Documentation

## Overview
MUSaiC is a CLI-first, automation-driven DAW system that composes, renders, and analyzes music through a structured project model. It combines CDP (Composer's Desktop Project) DSP tools with a sequencing/rendering engine, plus plugin discovery and future hosting for instrument and FX chains. The goal is to let a CLI workflow author a full song iteratively, then render, refine, and audit the output with analysis data.

## Setup
CDP is not bundled in this repo (size/licensing). Install CDPR8 separately and point MUSaiC at it.

Helper script (download/unzip/validate):
```powershell
./musaic-cdp.ps1 install -ZipPath <path_to_cdp_zip> -CdpRoot ./CDPR8 -UpdateConfig
```
You can also use `-ZipUrl` instead of `-ZipPath` if you have a direct download link.

If you already have CDPR8 somewhere:
```powershell
./musaic-cdp.ps1 check -CdpRoot <path_to_cdpr8>
```

To initialize the environment and configuration:

```powershell
./musaic.ps1 setup -CdpRoot ./CDPR8
```

To verify the installation:
```powershell
./musaic.ps1 doctor
```

### Database Configuration (Postgres)
MUSaiC uses PostgreSQL for project state and asset tracking. Set your connection string in `musaic.config.json`:
```json
{
  "dbConnectionString": "postgresql://user:pass@localhost:5432/musaic"
}
```
Initialize the schema with:
```powershell
./tools/db.ps1 -Init
```

## Quick Start

### 1. Basic Sequence (Synth)
Generate a song from a score file:
```powershell
./cdp-sequencer.ps1 -ScorePath examples/cheesy_classical_16bars.json
```

### 2. Plugin Registry (Index Only)
Scan and list VST/AU/SF2 plugins (no hosting, just discovery):
```powershell
# Configure paths first in musaic.config.json ("pluginPaths": ["<path_to_vst_plugins>"])
./musaic-plugins.ps1 -Command scan
./musaic-plugins.ps1 -Command list -Format VST3
```

### 3. SF2 SoundFont Bridger
Render using FluidSynth (requires configured `fluidsynthPath` + SoundFonts):
```powershell
./musaic-sf2.ps1 -Command render -ScorePath examples/cheesy_classical_16bars.json -SoundfontPath ./soundfonts/GeneralUser.sf2
```

### 4. Carla Plugin Host (Prototype)
Prototype render using VST3 plugins via Carla (requires `carlaPath` in config). Headless support varies by version and OS:
```powershell
./musaic-carla.ps1 -Command render -PluginPath "<path_to_vst3>" -OutWav ./output/vst_test.wav
```

### 5. Preview Playback
Quickly render a low-res (22kHz mono 16-bit) preview and play it:
```powershell
./musaic-preview.ps1 -ScorePath examples/cheesy_classical_16bars.json -Play
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

## MVP Capabilities (Today)
- JSON-driven sequencing for synth and sample tracks.
- Beat or second time units.
- Configurable output directory (defaults to `./output`, set via `musaic.config.json`).
- Per-track mixer controls (gainDb, pan, mute). Pan uses parser-safe arithmetic.
- **Synth Amp**: Folded into mixer gain (amp -> dB) to avoid binary crashes.
- Sample looping for clip events; Auto-cleanup of temp files (`-KeepTemp` to override).
- Basic effects (reverb, pitch/varispeed, tremolo LFO).
- Sample analysis (BPM, pitch estimate, RMS/peak, duration, warnings).
- Time/pitch transforms via robust tool selection (tries `stretch`/`strans` first, falls back to `modify`).
- **TUI Timeline**: `cdp-timeline.ps1` for lightweight ASCII score visualization.

## TUI Preview (ASCII)

These are snapshots from the local TUI design specs (not committed).

### Arranger View
```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ MUSaiC  project: NeonMix  │ BPM 140 │ Key D mixo │ 4/4 │ ▣ Snap:1/16 │ Loop: ON │ Render: idle             │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Tracks                     │ 1        5        9        13       17       21       25       29      33     │
│ ┌──────────────┐           │ ─┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬─── │
│ │[S][M] arp    │           │  │███▒███▒███▒███▒│   │   │   │   │   │   │   │   │   │   │   │   │   │    │
│ │   ▒▒▒▒▒▒▒▒   │ Intro     │  │███▒███▒███▒███▒│   │   │   │   │   │   │   │   │   │   │   │   │   │    │
│ └──────────────┘           │  │               │   │   │   │   │   │   │   │   │   │   │   │   │   │      │
│ ┌──────────────┐           │  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│   │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│   │   │   │   │   │      │
│ │[S][ ] pad    │           │  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│   │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│   │   │   │   │   │      │
│ │   ▓▓▓▓▓▓▓▓   │ Verse     │  │               │   │                       │   │   │   │   │   │      │
│ └──────────────┘           │  │               │   │   │   │   │   │   │   │   │   │   │   │   │   │      │
│ ┌──────────────┐           │  │░░░░░░░░░░░░░░░│   │░░░░░░░░░░░░░░░░░░░░░░░░│   │░░░░░░░░░░░░░░░░░░░│      │
│ │[ ][M] drums  │           │  │░░░░░░░░░░░░░░░│   │░░░░░░░░░░░░░░░░░░░░░░░░│   │░░░░░░░░░░░░░░░░░░░│      │
│ │   ░░░░░░░░   │ Chorus    │  │               │   │                       │   │                     │      │
│ └──────────────┘           │  ▲ playhead                                                                 │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Inspector: Clip “arp_intro_01”  len=4 bars  transpose=0  humanize=5%  swing=54%  velScale=1.00  quant=1/16 │
│ Info: Split clip at playhead (S). Hold Shift for “split & duplicate”.                                      │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Mixer View
```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ MUSaiC  Mixer │ BPM 140 │ Master -11.2 LUFS │ Peak -0.3 dB │ Render: done (stems+mix)                       │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Track      │ M S │ Meter (pre)                 │ Fader (dB)            │ Pan │ FX Chain                     │
├────────────┼─────┼─────────────────────────────┼───────────────────────┼─────┼──────────────────────────────┤
│ arp        │ □ ■ │ ▏▂▃▄▅▆▇█▇▆▅▄▃▂▁ ▌peak        │   +6 ┆               │ L20 │ Iris → Reverb → Delay         │
│            │     │                             │      ┆     ■         │     │                              │
│            │     │                             │   -∞ ┴────────────── │     │                              │
├────────────┼─────┼─────────────────────────────┼───────────────────────┼─────┼──────────────────────────────┤
│ pad        │ □ □ │ ▏▁▂▂▃▄▅▆▆▆▅▄▃▂▁  ▌peak        │   +6 ┆               │ R05 │ Iris → Chorus → Reverb        │
│            │     │                             │      ┆   ■           │     │                              │
│            │     │                             │   -∞ ┴────────────── │     │                              │
├────────────┼─────┼─────────────────────────────┼───────────────────────┼─────┼──────────────────────────────┤
│ drums      │ ■ □ │ ▏▃▄▅▆▇███▇▆▅▄▃▂▁ ▌peak        │   +6 ┆               │ C   │ BreakTweaker → Comp → Limiter │
│            │     │                             │      ┆       ■       │     │                              │
│            │     │                             │   -∞ ┴────────────── │     │                              │
├────────────┴─────┴─────────────────────────────┴───────────────────────┴─────┴──────────────────────────────┤
│ Master bus:  Meter ▏▂▃▄▅▆▇█▇▆▅▄▃▂▁ ▌  |  Target: -10.0 LUFS  |  [T] post/pre  [G] group                     │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Piano Roll View
```text
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ MUSaiC  Piano Roll │ Track: arp │ Clip: arp_intro_01 │ Grid: 1/16 │ Scale: D mixo (highlight) │ Vel lane ON │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│      │1     2     3     4     │5     6     7     8     │9    10    11    12    │13   14   15   16         │
│ D5   │ ┆  ■■   ┆     ┆  ■■  ┆ │ ┆  ■■   ┆     ┆  ■■  ┆ │ ┆  ■■   ┆     ┆  ■■  ┆ │ ┆  ■■   ┆     ┆  ■■  ┆  │
│ C5   │ ┆      ┆  ■■ ┆      ┆ │ ┆      ┆  ■■ ┆      ┆ │ ┆      ┆  ■■ ┆      ┆ │ ┆      ┆  ■■ ┆      ┆      │
│ A4   │ ┆  ■■  ┆     ┆  ■■  ┆ │ ┆  ■■  ┆     ┆  ■■  ┆ │ ┆  ■■  ┆     ┆  ■■  ┆ │ ┆  ■■  ┆     ┆  ■■  ┆      │
│ E4   │ ┆      ┆  ■■ ┆      ┆ │ ┆      ┆  ■■ ┆      ┆ │ ┆      ┆  ■■ ┆      ┆ │ ┆      ┆  ■■ ┆      ┆      │
│ D4   │ ┆■■■■■■■■■■■■■■■■■■■■┆ │ ┆■■■■■■■■■■■■■■■■■■■■┆ │ ┆■■■■■■■■■■■■■■■■■■■■┆ │ ┆■■■■■■■■■■■■■■■■■■■■┆    │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Velocity: 127 ▏▇▇▇▆▆▅▅▄▃▃▂▂▁ 0    | Selected: D4 @1:01 len=1/8 vel=96  | [Q] quantize [H] humanize        │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

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
3) **Phase C: Plugin Hosting**
   - Standalone host integration for VST/VST3/AU instruments and FX.
4) **Phase D: Arrangement Engine**
   - Section-based composition and evolution over time.
5) **Phase E: Metadata Continuity**
   - Persistent metadata files for tempo/key/scale/notes across sessions and machines.
6) **Phase F: Loudness Pass (Done)**
   - `-MasterLimitDb <dB>` and `-MasterLufs` implemented.
   - Analysis reports `lufs_i` via `ebur128`.

7) **Phase G: Music Theory (Done)**
   - `cdp-theory.ps1`: Key/Mode detection, Chord analysis, Roman Numerals.
   - Audio Analysis upgrades: Crest factor, Onset density.

## Future: Polishing
- Improve analysis accuracy (pitch detection mode).
- TUI enhancements.

## Missing Systems (Shortlist)
See `docs/DAW_GAPS.md` and `docs/TICKETS.md` for the full backlog and tool choices. Highlights:
- Project state + asset catalog (Postgres).
- Render graph + job cache (hash-based).
- Plugin host backend (Carla).
- MIDI engine + tempo maps + automation envelopes.
- Analysis upgrade (Essentia/Aubio) and time/pitch (Rubber Band/SoundTouch).
- Sample library management, routing matrix, and undo history.

- Required output formats (WAV/MP3/stems/project file)?
