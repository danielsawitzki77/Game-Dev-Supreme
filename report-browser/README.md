# Test Report Browser

A lightweight local web app for browsing, filtering, viewing, and cleaning up test reports across all game projects.

## Quick Start

```batch
cd report-browser
start.bat
```

Opens `http://localhost:8090` in your default browser.

## Features

- **Auto-scan** — Discovers `.md` report files in all sibling project `test_output/` directories
- **Filter by project** — Dropdown to show reports from a specific game (TerrorForm, Zeitgeist Evolved, SDL_VisualTest, Super Civ 16)
- **Filter by type** — Visual Regression, Integration Test, Screenshot Capture, General Report
- **Free-text search** — Search by report name, directory, or project
- **Rendered markdown view** — Reports displayed with formatted headings, tables, code, and images
- **Delete individual reports** — 🗑 button on each report entry
- **Bulk delete by filter** — "Delete Filtered" button removes all reports matching the current filter selection
- **Refresh** — Re-scan project directories without restarting the server

## Report Types

Reports are classified by keywords in their file path:

| Type | Keywords | Badge Color |
|------|----------|-------------|
| Visual Regression | `visual` | Teal |
| Integration Test | `integration` | Yellow |
| Screenshot Capture | `screenshot` | Purple |
| General Report | (default) | Gray |

## Architecture

```
report-browser/
  server.py    — Python HTTP server (stdlib only, no dependencies)
  index.html   — Single-page frontend (vanilla JS, no build step)
  start.bat    — Launcher script
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/reports` | List all discovered reports (JSON) |
| GET | `/api/report-content?path=<rel>` | Get raw markdown content of a report |
| POST | `/api/delete-report` | Delete a report file `{"path": "<rel>"}` |

## Requirements

- Python 3.6+ (uses only standard library)
- Projects must store reports in a `test_output/` directory
- Report files must match the glob `report*.md`

## Configuration

Edit `server.py` constants to customize:

- `PORT` — Server port (default: 8090, override with `--port`)
- `PROJECTS` — Dictionary of project names → local paths to scan
