# MUSaiC Step-by-Step Optimization Plan (Test-Driven)

This plan converts `experts.md` into concrete sprints.
Every sprint has:
- scope,
- deliverables,
- verification commands,
- pass/fail criteria,
- evidence artifacts.

## Verification System Principles

1. **No merge without tests** for the sprint scope.
2. **Evidence-first**: every sprint stores logs/reports under `output/verification/<sprint-id>/`.
3. **Deterministic fixtures**: prefer stable example inputs with fixed settings.
4. **Two-level checks**:
   - **L1 fast checks** (syntax, config, schema)
   - **L2 functional checks** (render/analyze behavior and expected artifacts)

---

## Sprint 0 - Baseline and Harness

### Goal
Create a reusable verification harness and baseline report format.

### Deliverables
- `tools/verify-sprint.ps1` harness with standard report output.
- Baseline fixture list (examples used by all future sprints).
- Report schema (`docs/verification-report-schema.md` or equivalent section in script comments).

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S0 -Mode fast`
- `./tools/verify-sprint.ps1 -SprintId S0 -Mode full`

### Pass Criteria
- Command exits `0`.
- JSON report written and parseable.
- All baseline fixtures discovered.

### Evidence
- `output/verification/S0/report.json`
- `output/verification/S0/report.txt`

---

## Sprint 1 - CLI Contract Standardization

### Goal
Normalize command patterns and help output across primary scripts.

### Deliverables
- Unified usage/help style for `musaic-cli`, `cdp-sequencer`, `cdp-analyze`, `cdp-transform`, `musaic-cdp`.
- Common flags where applicable (`-Json`, `-Verbose`, `-DryRun`).

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S1 -Mode fast`
- Script help smoke:
  - `./musaic-cli.ps1 help`
  - `./musaic.ps1 doctor`
  - `./musaic-cdp.ps1 help`

### Pass Criteria
- Help output includes required sections: usage, commands, examples.
- No script exits non-zero for help path.

### Evidence
- `output/verification/S1/help/*.txt`
- `output/verification/S1/report.json`

---

## Sprint 2 - Schema + Semantic Validation Gate

### Goal
Block invalid scores before expensive rendering.

### Deliverables
- Score schema validation command.
- Semantic checks: tempo range, event times/durations, pitch bounds, missing sources.

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S2 -Mode full`
- Positive fixture: valid score must pass.
- Negative fixtures: invalid scores must fail with explicit reasons.

### Pass Criteria
- 100% expected pass/fail outcomes on validation fixture set.
- Error messages include track and event context.

### Evidence
- `output/verification/S2/validation-matrix.json`

---

## Sprint 3 - Render Determinism + Regression

### Goal
Ensure repeatable renders and detect behavior drift.

### Deliverables
- Deterministic render mode for test fixtures.
- Render regression comparison (hash + audio metrics tolerance).

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S3 -Mode full`
- Repeat render same fixture twice and compare outputs.

### Pass Criteria
- Binary hash match OR metrics within tolerance thresholds.
- No unexpected warnings.

### Evidence
- `output/verification/S3/regression.json`
- `output/verification/S3/artifacts/*`

---

## Sprint 4 - Performance + Caching

### Goal
Speed iterative CLI composition workflows.

### Deliverables
- Content-hash cache for reusable intermediates.
- Optional parallel track render where safe.

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S4 -Mode perf`

### Pass Criteria
- Warm-cache run improves median runtime by agreed threshold (target: >=25% on fixture pack).
- Cached runs preserve output equivalence.

### Evidence
- `output/verification/S4/perf.json`

---

## Sprint 5 - Cross-Platform Matrix Hardening

### Goal
Close portability gaps on Windows/macOS/Linux.

### Deliverables
- Platform-specific command/path tests.
- Tool discovery matrix documentation.

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S5 -Mode fast`
- CI matrix runs per platform.

### Pass Criteria
- Matrix green for required checks.
- Known platform caveats documented with workarounds.

### Evidence
- `output/verification/S5/matrix-summary.json`

---

## Sprint 6 - Release Readiness and Operator Docs

### Goal
Ship reliable, documented workflows for CLI producers.

### Deliverables
- Release checklist.
- Operator runbook + troubleshooting index.
- "draft/review/release" render profiles.

### Verification Commands
- `./tools/verify-sprint.ps1 -SprintId S6 -Mode release`

### Pass Criteria
- Checklist complete.
- All mandatory tests green.

### Evidence
- `output/verification/S6/release-checklist.json`

---

## Definition of Done (Applies to Every Sprint)

1. Scope implemented.
2. Verification commands executed and captured.
3. Reports stored under sprint evidence path.
4. Failing checks triaged with issue IDs.
5. Docs updated with user-visible behavior changes.

