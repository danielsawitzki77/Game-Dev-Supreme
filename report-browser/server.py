"""
Report Browser Server — lightweight local web server for browsing test reports
across all game projects under the parent github directory.

Usage: python server.py [--port 8090]
Then open http://localhost:8090/reports in a browser.
"""

import http.server
import json
import os
import signal
import sys
import threading
import urllib.parse
from pathlib import Path

PORT = int(sys.argv[sys.argv.index("--port") + 1]) if "--port" in sys.argv else 8090

# All monitored project directories (sibling to Game-Dev-Supreme)
GITHUB_DIR = Path(__file__).resolve().parent.parent.parent
PROJECTS = {
    "TerrorForm": GITHUB_DIR / "TerrorForm",
    "Zeitgeist Evolved": GITHUB_DIR / "Zeitgeist Evolved",
    "SDL_VisualTest": GITHUB_DIR / "SDL_VisualTest",
    "Super Civ 16": GITHUB_DIR / "Super Civ 16",
}


def classify_report(path: Path) -> str:
    s = str(path).lower()
    if "visual" in s:
        return "visual"
    if "integration" in s:
        return "integration"
    if "screenshot" in s:
        return "screenshots"
    return "general"


def scan_reports():
    """Scan all project test_output dirs for .md report files."""
    reports = []
    for project_name, project_path in PROJECTS.items():
        test_output = project_path / "test_output"
        if not test_output.exists():
            continue
        for md in test_output.rglob("report*.md"):
            stat = md.stat()
            reports.append({
                "project": project_name,
                "path": str(md.relative_to(GITHUB_DIR)),
                "abs_path": str(md),
                "name": md.name,
                "dir": str(md.parent.relative_to(test_output)),
                "type": classify_report(md),
                "size": stat.st_size,
                "modified": stat.st_mtime,
            })
    reports.sort(key=lambda r: r["modified"], reverse=True)
    return reports


class ReportHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(Path(__file__).parent), **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in ("/", "/reports"):
            self.path = "/index.html"
            super().do_GET()
        elif parsed.path == "/api/reports":
            self._json_response(scan_reports())
        elif parsed.path == "/api/report-content":
            qs = urllib.parse.parse_qs(parsed.query)
            file_path = qs.get("path", [""])[0]
            self._serve_report(file_path)
        elif parsed.path.startswith("/api/file/"):
            # Serve files (images, etc.) relative to GITHUB_DIR
            rel_path = urllib.parse.unquote(parsed.path[len("/api/file/"):])
            self._serve_file(rel_path)
        elif parsed.path == "/api/shutdown":
            self._json_response({"ok": True, "message": "Shutting down..."})
            threading.Thread(target=self._shutdown, daemon=True).start()
        else:
            super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/delete-report":
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length)) if length else {}
            self._delete_report(body.get("path", ""))
        elif parsed.path == "/api/shutdown":
            self._json_response({"ok": True, "message": "Shutting down..."})
            threading.Thread(target=self._shutdown, daemon=True).start()
        else:
            self.send_error(404)

    def _shutdown(self):
        import time
        time.sleep(0.5)
        os._exit(0)

    def _json_response(self, data):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def _serve_report(self, rel_path: str):
        full = GITHUB_DIR / rel_path
        if not full.exists() or not str(full.resolve()).startswith(str(GITHUB_DIR)):
            self.send_error(404)
            return
        content = full.read_text(encoding="utf-8", errors="replace")
        body = content.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def _serve_file(self, rel_path: str):
        full = GITHUB_DIR / rel_path
        if not full.exists() or not str(full.resolve()).startswith(str(GITHUB_DIR)):
            self.send_error(404)
            return
        # Determine content type
        ext = full.suffix.lower()
        content_types = {
            ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
            ".gif": "image/gif", ".bmp": "image/bmp", ".svg": "image/svg+xml",
            ".webp": "image/webp", ".ico": "image/x-icon",
        }
        ct = content_types.get(ext, "application/octet-stream")
        data = full.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", len(data))
        self.end_headers()
        self.wfile.write(data)

    def _delete_report(self, rel_path: str):
        full = GITHUB_DIR / rel_path
        if not full.exists() or not str(full.resolve()).startswith(str(GITHUB_DIR)):
            self._json_response({"ok": False, "error": "not found"})
            return
        full.unlink()
        self._json_response({"ok": True})

    def log_message(self, format, *args):
        pass  # suppress request logging


if __name__ == "__main__":
    print(f"Report Browser running at http://localhost:{PORT}/reports")
    print(f"Scanning projects under: {GITHUB_DIR}")
    print("Press Ctrl+C or use the Quit button in the browser to stop.")
    with http.server.HTTPServer(("", PORT), ReportHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down.")
