## Mission (Sprint 16 Fixup v2)
Finish theory analysis so it works on real scores, and add a stronger mix/bus treatment to help tracks hit harder.

## A) Theory Analyzer (cdp-theory.ps1)
1) Accept any numeric pitch type
   - Treat Int64/Int32/Double as numeric. Use `[double]$p` and `[int][math]::Round($p)` for PC.
   - Do NOT drop notes just because type is Int64.

2) Always produce full outputs
   - `key_candidates` must be an array of top 3 objects (Root, Type, Score).
   - `pitch_class_histogram` must reflect actual note weights.
   - `scale_degree_histogram` must be computed (scale degrees 1..7 + accidentals count).
   - `out_of_key_notes` should include counts for each pitch class outside key.

3) Chord analysis must yield non-null results for cheesy_classical_16bars
   - Ensure windowing uses `time`/`dur` data and weights by overlap duration.
   - Output list of chords with Start/End/Name/Roman/Score.

4) Cadences
   - Add simple cadence detection: V->I, V7->I, ii->V->I, iv->I (minor).
   - Output cadence list with window indices or start beats.

5) Warnings
   - If histogram empty or no chords found, add explicit warnings.

## B) Audio Engineering Pass (cdp-sequencer.ps1)
Add optional `-MasterGlue` switch for a stronger, modern mixbus sound:
- If set, chain: `acompressor` -> `loudnorm` (if MasterLufs) -> `alimiter` (if MasterLimitDb).
- Use conservative defaults to avoid pumping:
  - `acompressor=threshold=-18dB:ratio=2:attack=5:release=50:makeup=2`
- Keep existing behavior when `-MasterGlue` is not set.
- Document this in README/CDP_CLI/MUSaiC/SKILL.

## C) Docs + Skills
- README.md, docs/MUSaiC.md, CDP_CLI.md, skills/cdp-cli/SKILL.md:
  - Document cdp-theory output schema in detail (key candidates, histograms, cadences).
  - Document MasterGlue and when to use it.

## D) mem_map refresh
- Update cdp-theory.ps1 and cdp-sequencer.ps1 nodes with new capability notes.
- Bump updated_at top-level + node-level.

## E) Tests (run & log)
1) Theory: `./cdp-theory.ps1 -ScorePath examples/cheesy_classical_16bars.json`
   - Expect non-empty histogram and chord list.
2) Mix: `./cdp-sequencer.ps1 -ScorePath examples/cheesy_classical_16bars.json -OutWav output/cheesy_classical_16bars_glue.wav -MasterGlue -MasterLufs -14 -MasterLimitDb -1`
3) Analyze: `./cdp-analyze.ps1 -InputFile output/cheesy_classical_16bars_glue_master.wav -TargetLufs -14`

## Logging
- Append a new entry in done_by_antigravity.md with files changed, commands run, outputs, warnings.

## Constraints
- ASCII only.
- Prefer rg for search.
- No network until push step.
