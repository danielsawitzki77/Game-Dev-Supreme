---
name: 'Work request: Particluar'
about: Do a change affecting Particluar (engine, renderer, map system, CLI tools, web editor)
title: 'Work request for Particluar: '
labels: ''
assignees: danielsawitzki77

---

We need a change or fix or improvement to be made in Particluar. This is the particle-based game engine project with the 2D Map System module (Renderer static library, WFC generator, CLI tools, web-based tileset/level editor). Changes land in the `danielsawitzki77/Particluar` repo.

**Components that may be affected:**
- `renderer/` — Static library (TileRenderer, Camera, Viewport, WFC, MapLoader, TilesetLoader, GlobalConfig, JsonUtil)
- `src/main.cpp` — Application PoC
- `tools/mapgen/` — Offline CLI map generator
- `tools/tilename/` — Tile naming CLI tool
- `tools/tileset-editor/` — Node.js/TypeScript web editor (Tileset Configurator + Level Editor)
- `scripts/` — PowerShell GUI wrapper
- `assets/tilesets/` — Tileset data (PNG + JSON sidecar)
- `assets/maps/` — Map files

**Visual Testing & Verification (if applicable):**
- If changes affect rendering, verify with the WASD scrolling PoC and/or G-key WFC generation.
- Attach screenshots or recordings demonstrating visual changes.

Here comes the actual ask of what needs to be done/fixed/extended:

