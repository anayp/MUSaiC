-- Render Edges Table (Dependency Graph)
CREATE TABLE IF NOT EXISTS render_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_node_id UUID REFERENCES render_nodes(id) ON DELETE CASCADE,
    to_node_id UUID REFERENCES render_nodes(id) ON DELETE CASCADE,
    type TEXT, -- e.g., 'data_flow', 'control_flow'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Render Artifacts Table (Outputs)
CREATE TABLE IF NOT EXISTS render_artifacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    node_id UUID REFERENCES render_nodes(id) ON DELETE CASCADE,
    path TEXT NOT NULL,
    hash TEXT,
    size_bytes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
