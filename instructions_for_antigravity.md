## Mission (MUSaiC Sprint 9)
Fix missing outputs and doc inconsistencies, then prepare a clean Git push.

## Memory Map (No UI)
- Use the Memory Map system only (no HTML/JS/CSS).
- Update `mem_map/data/context-data.json` with file/folder notes after each task.
- Add/modify nodes for files touched and edges for dependencies.
- Keep entries concise and accurate.

## Required Fixes
1) Re-run missing tests and capture outputs
   - .\cdp-sequencer.ps1 -ScorePath examples\sample_loop_demo.json -OutWav output\sample_loop_demo_test.wav
   - .\cdp-transform.ps1 -Mode tempo -Method pvoc -In examples\kick.wav -Out output\tempo_test.wav -Amount 110
   - .\cdp-transform.ps1 -Mode pitch -Method pvoc -In examples\kick.wav -Out output\pitch_test.wav -Amount 2
   - .\cdp-sequencer.ps1 -ScorePath examples\mixer_demo.json -OutWav output\mixer_demo_s9.wav
   - Verify timestamps are current for all outputs above.

2) Documentation/Skill alignment
   - README.md and docs/MUSaiC.md must mention:
     - Synth amp is folded into gainDb (amp -> dB at mix time).
     - Mixer pan uses parser-safe arithmetic.
     - Temp files auto-clean; -KeepTemp preserves.
     - PVOC method now prioritizes stretch/strans before modify speed fallback.
   - CDP_CLI.md: update pvoc description to match new behavior (no legacy pvoc anal).
   - skills/cdp-cli/SKILL.md: mention pvoc uses stretch/strans first; amp folded into gain.

3) Changelog update
   - Append a new entry noting:
     - Which missing tests were re-run.
     - Output files produced (with timestamps).
     - Doc/skill updates made.
     - Remove or correct any prior "full verification suite" claims if not fully rerun.

4) Git setup + push
   - Initialize git repo if not present.
   - Add a .gitignore if missing (ignore output/tmp_sequencer, output/*.wav, output/*.mp3, output/analysis, and any *.zip installers).
   - Commit message: "Sprint 9: verify outputs, docs, and pvoc behavior".
   - Add remote (ask for URL if needed).
   - Push to default branch.

## Constraints
- ASCII only.
- Prefer rg for search.
- No network until push step.
