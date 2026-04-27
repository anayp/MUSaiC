# Changelog

All notable changes to MUSaiC are documented here.

## [0.2.0] - 2026-01-17
- **Analysis**: Mixing Guide and Stem Analysis tool (`stem-analyze.ps1`).
- **Preview**: Debug mode and consistent sample rate enforcement.
- **Scaffolding**: CLI stubs for segmentation (`musaic-segment`) and stem separation (`musaic-stems`).
- **Docs**: Planning docs removed from git tracking; defined `github_upload_protocol`.

## Unreleased
- QoL: Added `musaic-cli.ps1` as a single command router for listing examples, score inspection, render/preview, timeline, and doctor checks.
- QoL: Improved `cdp-wrapper.ps1` with non-interactive `-Index` support and fixed argument forwarding to the sequencer.
- Portability: Added cross-platform CDP tool resolution (`tool` and `tool.exe`), plus broader playback command detection (`paplay`, `afplay`, `ffplay`).
- TUI: Added `musaic-tui.ps1` with arranger/mixer/piano ASCII views and a lightweight interactive mode.
- TUI UX: Added a persistent info line with current view + selected track focus and track-navigation keys (`j`/`k`).
- Examples: Added `examples/classical_30s_12voices.json` (30-second, 12-voice classical stress test score).
- Testing Artifacts: Added `examples/sprint_last_features_test_results_2026-04-27.json` with static/data-level smoke checks for recent sprint features.
- Docs: Updated README and CLI guide with the new convenience workflow.
- Core sequencer with JSON-driven synth/sample rendering.
- Metadata workflow (`cdp-meta.ps1`) and score fallback support.
- Analysis v2 (tempo candidates, beat grid, pitch histograms, key/chords, LUFS).
- Theory analysis for scores (`cdp-theory.ps1`) with Roman numerals.
- Loudness pass (`-MasterLufs`, `-MasterLimitDb`).
- SF2 rendering bridge (`musaic-sf2.ps1`).
- Plugin registry (`musaic-plugins.ps1`) for VST/VST3/AU/SF2 discovery.
- TUI timeline viewer (`cdp-timeline.ps1`).
- **Decision**: Postgres adopted for project state & asset catalog.
- **Decision**: Carla adopted for plugin hosting.
- **Removed**: Reaper integration and artifacts.
