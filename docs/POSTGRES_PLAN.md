# MUSaiC Postgres Implementation Plan

## Overview
This document outlines the schema design and migration strategy for moving MUSaiC's project state and asset catalog to PostgreSQL.

## 1. Schema Design

### Core Tables

#### `projects`
Stores project-level metadata.
- `id`: UUID (Primary Key)
- `name`: TEXT (Unique)
- `bpm`: INTEGER (Default 120)
- `time_signature_num`: INTEGER (Default 4)
- `time_signature_denom`: INTEGER (Default 4)
- `key_root`: TEXT
- `scale_type`: TEXT
- `created_at`: TIMESTAMP WITH TIME ZONE (Default NOW())
- `updated_at`: TIMESTAMP WITH TIME ZONE (Default NOW())

#### `tracks`
Represents audio or MIDI tracks within a project.
- `id`: UUID (Primary Key)
- `project_id`: UUID (Foreign Key -> projects.id)
- `name`: TEXT
- `type`: TEXT (CHECK value IN ('AUDIO', 'MIDI'))
- `gain_db`: REAL (Default 0.0)
- `pan`: REAL (Default 0.0, Range -1.0 to 1.0)
- `index`: INTEGER (Ordering)
- `color`: TEXT (Hex code)

#### `clips`
Audio or MIDI regions placed on tracks.
- `id`: UUID (Primary Key)
- `track_id`: UUID (Foreign Key -> tracks.id)
- `asset_id`: UUID (Foreign Key -> assets.id, Nullable for MIDI)
- `start_time`: REAL (Seconds or Beats)
- `duration`: REAL
- `offset`: REAL (Source offset)
- `name`: TEXT

#### `assets`
Global catalog of audio samples and files.
- `id`: UUID (Primary Key)
- `file_path`: TEXT (Unique, Absolute path)
- `file_hash`: TEXT (SHA256, for duplicate detection)
- `duration`: REAL
- `sample_rate`: INTEGER
- `channels`: INTEGER
- `metadata`: JSONB (Tags, key, tempo, analysis data)
- `last_scanned`: TIMESTAMP WITH TIME ZONE

## 2. Key Relationships
- **1 Project** has **N Tracks**.
- **1 Track** has **N Clips**.
- **1 Clip** references **0 or 1 Asset**.
- **Assets** are shared across projects (catalog).

## 3. Implementation Strategy

### Decision: SQL Files vs Migration Tool
**Selected Approach: Raw SQL Files + PowerShell Wrapper**
- **Rationale**: Keeps dependency footprint low (no need for dedicated Python/Node migration CLI yet). PowerShell is already our primary task runner.
- **Structure**:
    - `sql/schema/001_initial_schema.sql`
    - `sql/migrations/`
    - `tools/db.ps1` (Helper script to init/reset/migrate)

### Migration Strategy
1.  **Init Script**: `tools/db.ps1 -Init` will run the base schema.
2.  **Versioning**: A `schema_migrations` table will track applied SQL files.
3.  **Data Persistence**: Postgres container volume will be mapped to a local `data/pg` folder (gitignored) for portability testing, or standard system install.
