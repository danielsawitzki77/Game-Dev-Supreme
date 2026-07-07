# CLI Agent Pitfalls — Mandatory Patterns

These rules apply specifically to headless kiro-cli runs on Windows CMD. Following them avoids recurring time-wasting failures.

---

## Shell Commands

**The kiro-cli shell tool uses PowerShell by default on Windows.** Do NOT use CMD syntax (`&&`, `&`, `cd /d`). Instead:

- Chain commands with `;` (PowerShell separator)
- Use `Set-Location` or provide `cwd` parameter if available
- For commands that MUST run in CMD (e.g., batch files), wrap with: `cmd /c "command here"`
- When wrapping CMD commands that contain paths with spaces, use short-path or single-command invocations

**Never use `curl`** — it's aliased to `Invoke-WebRequest` on Windows. Use:
```powershell
Invoke-WebRequest -Uri 'https://...' -OutFile 'path'
```

---

## PowerShell Variables

**Never pass PowerShell code with `$variables` inline in a shell command.** The `$` will be stripped or misinterpreted.

**Always:**
1. Write a `.ps1` temp file using the file-writing tool
2. Execute it: `powershell -ExecutionPolicy Bypass -File "C:\path\to\script.ps1"`
3. Delete the temp file after

This applies to ANY PowerShell that uses variables, string interpolation, or complex expressions.

---

## Git Operations

### Commit Messages

**Always use `-F <file>` for commit messages.** Never use `-m "..."` because:
- `#` characters are interpreted by shells
- Paths with spaces break quoting
- Multi-line messages are impossible in CMD

Pattern:
1. Write message to `commit_msg.txt` in the repo root
2. `git add <files>`  (verify this succeeds!)
3. `git commit -F commit_msg.txt`
4. `del commit_msg.txt` (or `git checkout -- commit_msg.txt`)

### Staging

**Always verify staging succeeded before committing.** If the `git add` was part of a failed command chain, files won't be staged. Use `git status` or just use `git commit -a -F <file>` when all modified tracked files should be included.

### Chained Git Commands

For multi-step git operations (fetch, checkout, pull), run them as **separate sequential shell calls**, not chained. Each command depends on the previous one succeeding.

---

## GitHub API: Comment IDs

The `gh issue view --json comments` command returns **node_ids** (format: `IC_kwDO...`). These DO NOT work with REST API endpoints like `/issues/comments/<id>/reactions`.

**Always fetch numeric comment IDs using:**
```
gh api repos/<owner>/<repo>/issues/<number>/comments --jq "[.[] | {id, body: (.body | .[0:80]), user: .user.login}]"
```

The `.id` field from this response is the numeric ID that works with REST endpoints.

---

## File Encoding / Non-ASCII Content

**Never use str_replace on files with encoding issues or non-ASCII content.** The tool may not match byte sequences correctly across encodings.

For fixing mojibake, broken emoji, or any non-ASCII replacements:
1. Write a PowerShell .ps1 script that reads the file as bytes or with explicit encoding
2. Perform replacements in PowerShell
3. Write back with explicit UTF-8 encoding (no BOM): `[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))`

---

## GitHub Comment Posting

**Always use `--body-file` for GitHub comments and PR bodies.** Never use `--body "..."` with newlines — CMD doesn't interpret `\n`.

Pattern:
1. Write comment content to a temp file using the file-writing tool
2. `gh issue comment <N> --repo <repo> --body-file <temp-file>`
3. Delete the temp file

---

## Image URLs from Issues

When extracting image URLs from GitHub issue bodies/comments (e.g., from `<img src="...">` or `![alt](url)` markdown), the URL may get corrupted with backslashes on Windows (`https:\github.com\...` instead of `https://github.com/...`).

**Before using any extracted URL:**
- Verify it starts with `https://` (forward slashes)
- If backslashes are present, replace them: the URL should be `https://github.com/user-attachments/assets/<id>`
- When passing the URL to image-viewing tools, ensure forward slashes are used
- **Do NOT attempt the image-reading tool directly on GitHub user-attachment URLs** — they often fail validation. Instead, download to a temp file first, then read the local file.

**For downloading images:** Always write a .ps1 script (per the PowerShell variables rule) rather than using inline `$env:TEMP`:
```powershell
$url = 'https://github.com/user-attachments/assets/abc123'
$out = Join-Path $env:TEMP 'screenshot.png'
Invoke-WebRequest -Uri $url -OutFile $out
Write-Host $out
```

---

## Already-Complete Issues

When scanning issues, if a Kiro completion comment (`✅ Work complete`) already exists AND there are no unprocessed human comments, **skip the issue immediately**. Do not re-read the full issue body or check PR comments unless there's evidence of new activity (unprocessed human comments without 👀 reactions).

Check for completion efficiently:
```
gh api repos/<owner>/<repo>/issues/<number>/comments --jq "[.[] | select(.body | startswith(\"🤖 [Kiro]\") | not) | select(.reactions.eyes == 0)] | length"
```
If this returns 0, there's nothing to do — move on.
