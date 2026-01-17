# Changelog

All notable changes to MUSaiC are documented here.

## [0.2.0] - 2026-01-17
- **Analysis**: Mixing Guide and Stem Analysis tool (`stem-analyze.ps1`).
- **Preview**: Debug mode and consistent sample rate enforcement.
- **Scaffolding**: CLI stubs for segmentation (`musaic-segment`) and stem separation (`musaic-stems`).
- **Docs**: Planning docs removed from git tracking; defined `github_upload_protocol`.

## Unreleased
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
