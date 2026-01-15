# MUSaiC Ticket Log

This backlog is mirrored to GitHub issues when requested. Keep this file in sync
with repo priorities.

| ID | Title | Type | Priority | Status | Issue | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| MUS-001 | Project state + asset catalog (Postgres) | Infra | P0 | Open | [#8](https://github.com/anayp/MUSaiC/issues/8) | Schema for projects, tracks, clips, assets, analysis, renders in Postgres. |
| MUS-002 | Render graph + job cache | Engine | P0 | Open | [#9](https://github.com/anayp/MUSaiC/issues/9) | Hash-based render DAG and cache invalidation. |
| MUS-003 | Plugin host backend (Carla) | Engine | P0 | Open | [#10](https://github.com/anayp/MUSaiC/issues/10) | Offline render path for VST/VST3/AU via Carla. |
| MUS-004 | MIDI engine + tempo maps | Core | P1 | Open | [#11](https://github.com/anayp/MUSaiC/issues/11) | Import/export + tempo change representation. |
| MUS-005 | Automation envelopes | Core | P1 | Open | [#12](https://github.com/anayp/MUSaiC/issues/12) | Parameter curves + CC automation. |
| MUS-006 | Analysis engine upgrade (Essentia/Aubio) | DSP | P1 | Open | [#13](https://github.com/anayp/MUSaiC/issues/13) | Replace/augment heuristic detection. |
| MUS-007 | Time/pitch fallback (Rubber Band/SoundTouch) | DSP | P1 | Open | [#14](https://github.com/anayp/MUSaiC/issues/14) | Higher quality and stability. |
| MUS-008 | Sample library index + tagging | Data | P1 | Open | [#15](https://github.com/anayp/MUSaiC/issues/15) | Store key/tempo/fingerprint metadata. |
| MUS-009 | Routing matrix + sends/returns | Engine | P1 | Open | [#16](https://github.com/anayp/MUSaiC/issues/16) | Bus routing model + render support. |
| MUS-010 | Undo/redo + revision history | Core | P2 | Open | [#17](https://github.com/anayp/MUSaiC/issues/17) | Persistent edit history. |
| MUS-011 | Plugin presets + metadata index | Core | P2 | Open | [#18](https://github.com/anayp/MUSaiC/issues/18) | Preset discovery and recall. |
| MUS-012 | TUI runtime (Textual) baseline | UI | P2 | Open | [#19](https://github.com/anayp/MUSaiC/issues/19) | Minimal interactive shell and views. |
| MUS-013 | Low-res playback preview | Core | P2 | Open | [#20](https://github.com/anayp/MUSaiC/issues/20) | Render a fast preview (lower sample rate/bit depth or simplified render) for quick listening during composition. |
