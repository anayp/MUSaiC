# MUSaiC Mixing & Gain Staging Guide

This document outlines the gain staging strategy and mixing best practices for MUSaiC projects. Following these guidelines ensures consistent loudness, avoids clipping, and allows the analysis tools (BPM/Pitch) to function reliably.

## 1. Target Levels
Consistency is key for automated analysis and listening comfort.

- **Preview Target**: -18 LUFS (Integrated).
  - MUSaiC's preview mode defaults to this to ensure audible scratch renders.
- **Mix Evaluation**: -18 to -14 LUFS.
  - Leaves headroom for mastering limiters.
- **Release Target**: -14 to -10 LUFS (Genre dependent).
  - Use `-MasterLufs` and `-MasterLimitDb` flags during render to hit these targets.
- **True Peak**: -1.0 dBTP (Max).
  - Never exceed 0.0 dBFS to avoid inter-sample peaks during transcoding.

## 2. Track Headroom Strategy
Avoid "mixing into the limiter." Start with conservative levels at the source.

- **Source Material (Samples/Synths)**:
  - Aim for peaks around **-12 dBFS** to **-6 dBFS** raw.
  - If a sample is normalized to 0 dB, reduce its `amp` (e.g., `0.5`) or track gain (`-6.0`).
- **Summing**:
  - When summing 10 tracks, the bus level rises significantly.
  - If the master bus clips (peaks > 0 dB) *before* the limiter, distortion occurs.
  - Result: Keep individual tracks well below 0 dB.

## 3. Using MUSaiC Mixer Controls
Every track in `session.json` or `score.json` supports:

- **`gainDb`** (Float, default 0.0):
  - The primary mixing fader.
  - Example: `"gainDb": -3.5`
- **`amp`** (Float, default 1.0):
  - Source-level amplitude scalar.
  - **Best Practice**: Use `amp` to balance the raw source (e.g., quiet synth vs loud sample) and `gainDb` for the mix placement.
- **`pan`** (Float, -1.0 to 1.0):
  - Stereo field placement.
  - 0 = Center, -1 = Left, 1 = Right.

## 4. Master Bus Defaults
MUSaiC CLI tools provide safety rails:

- **`-MasterLimitDb`** (Default: -1.0 dB):
  - A brickwall limiter applied at the very end.
  - Prevents clipping but does not fix a bad mix balance.
- **`-MasterLufs`** (Optional):
  - Uses EBU R128 normalization to force the entire mix to a target loudness.
  - Great for quick consistency, but heavy reliance can crush dynamics if the mix is wildly off.

## 5. Suggested Starting Ranges
Typical gain settings for a balanced starting point:

| Role | Gain (approx) | Pan | Notes |
|---|---|---|---|
| **Kick** | -6.0 dB | C | Foundation. Should accurately trigger meters. |
| **Snare** | -6.0 dB | C | Often competes with kick for headroom. |
| **Bass** | -8.0 dB | C | Check low-end frequencies collision with kick. |
| **Pads/Keys** | -12.0 dB | L/R | Wider stereo spread, lower volume to fill space. |
| **Leads** | -8.0 dB | C/L/R | Front and center usage. |
| **FX/Atmos** | -18.0 dB | Wide | Background texture only. |

## 6. Validating Your Mix
Use the Stem Analyzer (`tools/stem-analyze.ps1`) to check if your gain staging is healthy.

```powershell
./tools/stem-analyze.ps1 -StemDir output/tmp_sequencer
```

It suggests `gainDb` adjustments to hit a -18 dB RMS target per track.
