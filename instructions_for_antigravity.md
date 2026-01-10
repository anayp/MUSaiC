## Mission (MUSaiC Sprint 13)
Complete metadata integration and fix the Sprint 12 gaps. Then lay groundwork for the next sprint (loudness pass).

## Fix Sprint 12 Gaps
1) cdp-meta.ps1
   - Add dot-notation updates for nested fields.
   - Example: -Set "sections.0.name=intro" and "sections.0.length=16".
   - Keep top-level updates working as-is.

2) Docs
   - docs/MUSaiC.md: Add meta.json usage (init/show/update) and link to meta-schema.
   - CDP_CLI.md: Add cdp-meta.ps1 usage and -MetaPath note for cdp-sequencer.ps1.

3) Memory Map
   - Add nodes for docs/meta-schema.md, examples/musaic_meta.json, cdp-meta.ps1.
   - Link meta files to cdp-sequencer.ps1.
   - Update mem_map/data/context-data.json with these nodes/edges.

4) Verification
   - Run:
     - .\cdp-meta.ps1 -Init output\meta_new.json
     - .\cdp-meta.ps1 -Update output\meta_new.json -Set "sections.0.name=intro" -Set "sections.0.length=16"
     - .\cdp-meta.ps1 -Show output\meta_new.json
     - .\cdp-sequencer.ps1 -ScorePath output\meta_fallback_test.json -MetaPath output\meta_new.json
   - Capture outputs/timestamps in done_by_antigravity.md.

## Next Sprint Prep: Loudness Pass
- Add a brief plan section in README.md for a master loudness/limiter option in cdp-sequencer.ps1.
- Do NOT implement the loudness pass yet; just document the plan in README.md.

## Logging
- Append a new entry in done_by_antigravity.md with:
  - files modified
  - commands run
  - outputs produced
  - any failures or warnings

## Constraints
- ASCII only.
- Prefer rg for search.
- No network until push step.
