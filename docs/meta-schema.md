# MUSaiC Project Metadata Schema (`meta.json`)

## Purpose
Stores persistent musical context, arrangement logic, and project state to enable session continuity across different machines and render passes.

## Fields

### Core Identity
- `project_name` (string): Human-readable title.
- `version` (string): Semantic version of the project state (e.g., "1.0.0").
- `created_at` (iso-date): Inception date.
- `updated_at` (iso-date): Last modification.

### Musical Context
- `tempo` (number): Global BPM (e.g., 140).
- `timeUnits` (string): "beats" or "seconds" (Default: "beats").
- `key` (string): Root note (e.g., "D").
- `scale` (string): Scale type (e.g., "mixolydian", "minor").

### Arrangement
- `sections` (array): Ordered list of song sections.
  - `name` (string): "intro", "verse", etc.
  - `length` (number): Duration in `timeUnits`.
  - `notes` (string): Free-text description of intent or harmonic content.

### Sound Design
- `instrumentation` (array): List of active instruments/sources.
- `sound_palette` (string): Description of texture/timbre goals.

### System
- `linked_scores` (array): Paths to associated `score.json` files.
- `last_render` (string): Path to the most recent mixdown.

## Example
```json
{
  "project_name": "Neon City demo",
  "tempo": 128,
  "key": "A",
  "scale": "minor",
  "sections": [
    { "name": "intro", "length": 16, "notes": "Filter sweep pad" }
  ]
}
```
