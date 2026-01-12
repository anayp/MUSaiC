-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Schema Migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    bpm INTEGER DEFAULT 120,
    time_signature_num INTEGER DEFAULT 4,
    time_signature_denom INTEGER DEFAULT 4,
    key_root TEXT,
    scale_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tracks Table
CREATE TABLE IF NOT EXISTS tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT CHECK (type IN ('AUDIO', 'MIDI')),
    gain_db REAL DEFAULT 0.0,
    pan REAL DEFAULT 0.0,
    index INTEGER,
    color TEXT
);

-- Assets Table (Global Catalog)
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_path TEXT UNIQUE NOT NULL,
    file_hash TEXT,
    duration REAL,
    sample_rate INTEGER,
    channels INTEGER,
    metadata JSONB,
    last_scanned TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Clips Table
CREATE TABLE IF NOT EXISTS clips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES assets(id),
    start_time REAL NOT NULL,
    duration REAL NOT NULL,
    offset REAL DEFAULT 0.0,
    name TEXT
);
