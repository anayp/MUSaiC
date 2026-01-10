# Composer Desktop Setup Roles

## Mission
- Download and install the Composer Desktop project in the repo root, then enable programmatic music creation and control via the CLI.

## Ground Rules
- Work in the repo root. Keep edits ASCII-only unless required.
- Network is restricted; request approval before any download or install that reaches the internet.
- Favor `rg` for search; avoid destructive git commands.

## Roles
- **Acquisition Engineer**: Locate the Composer Desktop source (repo/archive), request network approval, and download it into the repo root. Verify integrity (hash/signature if provided).
- **Build & Setup Specialist**: Identify project tech stack, install prerequisites, and run project setup/install scripts. Document commands used and environment variables needed.
- **CLI Music Programmer**: Expose a CLI workflow to create/arrange/play music programmatically (e.g., MIDI generation, sequencing, rendering). Add scripts or commands that accept declarative inputs (JSON/YAML) and produce audio/MIDI outputs.
- **Integration Tester**: Create quick checks (e.g., `--version`, sample render/play command) to confirm the install and CLI music pipeline work end-to-end.
- **Release Notes Scribe**: Record steps taken, prerequisites, and how to run the CLI music commands in this repo’s README or a dedicated setup guide.

## Next Moves (initial)
1) Request approval to fetch the Composer Desktop project source (specify URL or repo once known).
2) Inspect the project (README/package config) to determine build/runtime deps; install them with approval.
3) Add or verify CLI entrypoints for music generation/playback and provide a sample command + expected output.
4) Run smoke tests (build + sample render/play) and note outcomes.
