# MUSaiC Missing Systems (Gap Analysis)

This document lists the subsystems that CDP does not provide, along with simple,
robust solutions MUSaiC can adopt to become a cohesive DAW.

## 1) Project State + Asset Catalog
**Gap**: No canonical storage for projects, tracks, clips, renders, and assets.
**Impact**: Hard to search, dedupe, or resume on another machine.
**Simple fix**:
- **Postgres** (Chosen Solution): Robust multi-user and long-term scaling.
**Minimal tables**: `projects`, `tracks`, `clips`, `assets`, `analysis`,
`renders`, `plugins`, `presets`, `jobs`.

## 2) Render Graph + Job Cache
**Gap**: No dependency-aware render pipeline or cache.
**Impact**: Re-renders everything even when inputs are unchanged.
**Simple fix**:
- Build a render DAG (nodes with input hashes).
- Cache output artifacts by hash and skip unchanged renders.

## 3) Plugin Hosting Backend
**Gap**: Plugins are indexed but not hosted.
**Impact**: VST/VST3/AU instruments and FX cannot render.
**Simple fix**:
- **Carla** CLI (Chosen Solution): Mature, scriptable host backend.
**Note**: Keep plugin paths external and user-supplied.

## 4) MIDI Engine + Tempo Maps
**Gap**: No standard MIDI import/export or tempo map system.
**Impact**: Poor interoperability and timing accuracy.
**Simple fix**:
- Add a MIDI layer (writer + reader) and explicit tempo maps.
- Store tempo changes in `session.json` or DB.

## 5) Automation Envelopes
**Gap**: No unified automation format for parameters or CC.
**Impact**: Limited expressiveness and no offline modulation.
**Simple fix**:
- Define automation curves in session model.
- Apply to CDP effects or host plugin params.

## 6) Analysis Engine (Higher Accuracy)
**Gap**: Current analysis is heuristic and fragile.
**Impact**: Key/tempo detection can drift on real music.
**Simple fix**:
- **Essentia** or **Aubio** for tempo, key, pitch, onsets.
- Cache results in `analysis` table.

## 7) Time/Pitch (Quality + Stability)
**Gap**: CDP is powerful but not always stable for casual users.
**Impact**: Failed transforms or inconsistent results.
**Simple fix**:
- **Rubber Band** (high quality) or **SoundTouch** (fast) as fallback.

## 8) Sample Library Management
**Gap**: No index of samples with key/tempo metadata.
**Impact**: Hard to reuse loops intelligently.
**Simple fix**:
- Store sample metadata in DB.
- Add fingerprint or spectral hash for dedupe.

## 9) Routing Matrix + Sends/Returns
**Gap**: No first-class buses/sends/returns system.
**Impact**: Mix workflow is limited.
**Simple fix**:
- Add bus routing data to session.
- Render graph applies sends/returns with per-track levels.

## 10) Undo/Redo + Revision History
**Gap**: No durable edit history.
**Impact**: Changes are hard to roll back.
**Simple fix**:
- Store revisions in DB (immutable snapshots or diffs).
- Expose CLI for rollback to prior revision.

## Recommended DSP Stack (Shortlist)
- **Essentia** or **Aubio**: tempo/key/pitch/onsets.
- **Rubber Band** or **SoundTouch**: time/pitch.
- **libsamplerate**: resampling quality.
- **libsndfile**: stable audio I/O (if needed beyond ffmpeg).
- **zita-convolver**: convolution reverb (optional).

## Data Layer Recommendation
- **Postgres**: Chosen for robustness and shared catalog capabilities.
- See `docs/POSTGRES_PLAN.md` for the schema and migration plan.
