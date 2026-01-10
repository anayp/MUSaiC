# Memory Map Context System (Schema v2)

This repo uses a lightweight context map file at:

- `mem_map/data/context-data.json`

The UI files are intentionally omitted. Use the JSON file directly or via the
minimal API server in `mem_map/server.js`.

## Schema v2 (content/view separation)

Top-level:

```json
{
  "schema_version": 2,
  "updated_at": "2026-01-10T22:00:00Z",
  "repo": {
    "name": "CDP",
    "root": "F:/CDP"
  },
  "content": {
    "nodes": [],
    "edges": []
  },
  "views": []
}
```

### content.nodes
- `id`: string (unique)
- `type`: string (file, folder, module, script, doc, note)
- `path`: string (repo-relative or absolute)
- `summary`: string (short description)
- `tags`: string[] (optional)

### content.edges
- `from`: string (node id)
- `to`: string (node id)
- `relation`: string (depends_on, generates, documents, tests, owns)

### views
- `id`: string
- `name`: string
- `filters`: object (optional)
- `notes`: string (optional)

## Minimal API (no UI)

The server exposes:
- `GET /api/context` -> returns JSON
- `POST /api/context` -> replaces JSON
- `POST /api/scan` -> not implemented (returns 501)

Environment variables:
- `HOST` (default: 127.0.0.1)
- `PORT` (default: 4500)
- `MEMMAP_TOKEN` (optional)

Use `x-memmap-token` header if `MEMMAP_TOKEN` is set.
