## Mission (MUSaiC Next Steps)
Move from raw score rendering to a session-level composer, tighten analysis outputs, and remove strict-mode escapes.

## Required fixes (blockers)
1) **Remove StrictMode off**
   - Refactor the sample looping block so `Set-StrictMode -Off` is no longer needed.
   - Initialize variables properly and keep strict mode enabled for the whole script.

2) **Analysis output hygiene**
   - Update `cdp-analyze.ps1` to write:
     - JSON output: `output/analysis/<basename>-<mode>.json`
     - Text summary: `output/analysis/<basename>-<mode>.txt`
   - Do not leave temp files (e.g., `bpm_err.txt`) in repo root.
   - Include a short human-readable summary block in the text output (BPM, duration, peak, etc.).

## New feature work (required)
3) **Session-level composer**
   - Add `music-session.ps1` that reads `examples/musaic_session.json` and generates a CDP score file.
   - Session input should include: `tempo`, `timeUnits`, `sections` (intro/verse), `key/mode`, and instrumentation intent.
   - Output a generated `examples/musaic_session_score.json` suitable for `cdp-sequencer.ps1`.

4) **Advanced transform config**
   - Extend `cdp-transform.ps1` to accept `-ConfigPath` with a JSON config that can specify:
     - `mode` (tempo/pitch)
     - `method` (fast/pvoc)
     - `amount`
     - `params` for advanced pvoc arguments (document supported params).
   - Provide an example config in `examples/transform_pvoc.json`.

## Docs + skill updates (required)
5) **CDP_CLI.md**
   - Document `music-session.ps1`, analysis outputs, and transform config usage.
   - Include a 2-step example: session -> score -> render.

6) **skills/cdp-cli/SKILL.md**
   - Add `music-session.ps1` and analysis/transform outputs to the quick usage.
   - Note where analysis outputs are stored (`output/analysis/`).

## Logging requirement
- Append a new entry to `done_by_antigravity.md` with date/time, files touched, and a bullet list of changes.

## Constraints
- ASCII only.
- Prefer `rg` for search.
- No network needed.
