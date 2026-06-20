# GitHub Issue-Driven Autonomous Workflow

## Overview

This steering doc defines how Kiro operates as an autonomous worker across multiple repositories owned by `danielsawitzki77`. When triggered (via hook or manual command), Kiro checks all repos for open issues, picks the highest-priority one, and works on it end-to-end.

## Repositories

The following repos are monitored for issues:

- `danielsawitzki77/Zeitgeist-Evolved`
- `danielsawitzki77/SDL_VisualTest`
- `danielsawitzki77/Super-Civ-16`
- `danielsawitzki77/TerrorForm`
- `danielsawitzki77/Game-Dev-Supreme`

## Issue Pickup Logic

### Priority Order

1. Issues with `priority: critical` or `priority: high` labels
2. Issues with `priority: medium` label
3. Issues with no priority label (treat as medium)
4. Issues with `priority: low` label
5. Within the same priority tier: oldest issue first (FIFO)

### On Pickup

When picking up an issue:

1. **Assign it** to `danielsawitzki77` if not already assigned: `gh issue edit <number> --repo <repo> --add-assignee danielsawitzki77`
2. **Post a comment** indicating work has started: `gh issue comment <number> --repo <repo> --body "🤖 [Kiro] Picking up this issue and starting work."`
3. **Read the full issue body** to understand the task
4. **Fill in missing fields** by common sense (labels, milestone if obvious)

## Working on an Issue

### Communication

- **All machine-generated comments** must be prefixed with `🤖 [Kiro]` so they can be identified as non-human.
- **Tag the user**: Every comment must end with `\n\ncc @danielsawitzki77-remote` so the user receives a GitHub notification.
- **Questions/blockers**: Post as a comment on the issue: `gh issue comment <number> --repo <repo> --body "🤖 [Kiro] <question>\n\ncc @danielsawitzki77-remote"`
- **Progress updates**: Post as comments when reaching significant milestones
- **Completion**: Post a summary comment (do NOT close the issue — see Issue Lifecycle below)

### Issue Lifecycle

Issues follow a managed lifecycle rather than being auto-closed:

1. **Issues stay open** after work is completed. Do NOT close issues automatically.
2. **After completing work**, post a summary comment: `gh issue comment <number> --repo <repo> --body "🤖 [Kiro] ✅ Work complete. <summary of what was done>. PR: <link>. Awaiting human approval to close."`
3. **Check for new human comments** on open issues each cycle. Human comments are any comments NOT prefixed with `🤖 [Kiro]`. If new human comments contain follow-up instructions, treat them as additional work items on that issue.
4. **Mark processed comments with a reaction** to track progress: `gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -f content=eyes` — use the 👀 reaction to indicate the comment has been read and acted upon.
5. **Only close an issue** when a human comment explicitly approves closure (e.g., "looks good", "approved", "close this", "done"). Then close with: `gh issue close <number> --repo <repo> --comment "🤖 [Kiro] Closing as approved."`

### Detecting Human Comments

When checking open issues for follow-up:

1. Fetch comments: `gh api repos/<owner>/<repo>/issues/<number>/comments --jq '.[] | {id, body, user: .user.login, reactions: .reactions}'`
2. A comment is **human** if its body does NOT start with `🤖 [Kiro]`
3. A comment is **unprocessed** if it has no 👀 (eyes) reaction from the bot
4. Process unprocessed human comments **sequentially**, posting a separate reply for each one, then react with 👀 on each after processing it.

### Processing Screenshots and Images

Issue bodies and comments often contain screenshots (embedded as `<img>` tags or `![alt](url)` markdown). These images provide critical context — bug reproductions, UI state, error dialogs, etc.

When reading an issue body or comment:

1. **Identify all image URLs** — look for `<img ... src="...">` tags and `![...](...)` markdown image syntax.
2. **Download and analyze each image** — use the image reading capability to view the screenshot content. Images hosted on `github.com/user-attachments/assets/` or `githubusercontent.com` are GitHub-hosted and safe to fetch.
3. **Use image content as context** — screenshots may show error messages, UI state, file listings, or other information that the text alone doesn't convey. Factor this into your understanding of the issue or follow-up request.
4. **Reference what you see** — when replying to a comment with a screenshot, acknowledge what the image shows so the human knows it was processed.

### Target Project Deduction

An issue may be filed in one repo but describe changes that belong to a different repo. Before starting work, **deduce the correct target project** from the issue title and body:

1. Look for explicit repo/project names in the title or body (e.g., "zeitgeist", "SDL_VisualTest", "Super-Civ-16", "TerrorForm", "Game-Dev-Supreme").
2. If the title or body references a specific project, the changes apply to that project's repo — not necessarily the repo where the issue was filed.
3. If ambiguous, default to the repo where the issue is filed.
4. Always open the PR in the **target project's repo**, not the issue's repo (unless they are the same).
5. In the pickup comment, state which repo will receive the changes: `🤖 [Kiro] Picking up this issue. Target repo: <owner/repo>.`

Mapping of common keywords to repos:
- "zeitgeist", "evolved" → `Zeitgeist-Evolved`
- "SDL", "visual test" → `SDL_VisualTest`
- "super civ", "civ 16" → `Super-Civ-16`
- "terrorform", "terraform" → `TerrorForm`
- "game dev supreme", "issue checker", "hooks", "polling", "batch file" → `Game-Dev-Supreme`

### Local Path Mapping

GitHub repo names do NOT always match local folder names. **Never clone a repo if a folder for it already exists** — use this mapping to find the correct local path:

| GitHub Repo Slug | Local Folder Name | Full Local Path |
|---|---|---|
| `Zeitgeist-Evolved` | `Zeitgeist Evolved` | `c:\Users\Daniel Sawitzki\Desktop\github\Zeitgeist Evolved` |
| `SDL_VisualTest` | `SDL_VisualTest` | `c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest` |
| `Super-Civ-16` | `Super Civ 16` | `c:\Users\Daniel Sawitzki\Desktop\github\Super Civ 16` |
| `TerrorForm` | `TerrorForm` | `c:\Users\Daniel Sawitzki\Desktop\github\TerrorForm` |
| `Game-Dev-Supreme` | `Game-Dev-Supreme` | `c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme` |

**Critical rule:** When determining if a repo is "available in the workspace", check this mapping table — do NOT rely on the GitHub repo slug matching a folder name exactly. A mismatch (e.g., hyphen vs space) does not mean the repo is missing. If the mapped local path exists, use it. Never `git clone` a repo that already has a local folder listed here.

### Scope Rules

- Only work on repos whose workspace folder exists under `c:\Users\Daniel Sawitzki\Desktop\github`
- If the highest-priority issue is in a repo not available on disk, skip it and note that in a comment: "🤖 [Kiro] Cannot work on this — repo not available in current workspace. Skipping to next issue."
- If no issues are workable (all in unavailable repos), report that and stop

### Work Execution

- Follow existing project conventions (steering docs, build systems, etc.)
- Create a feature branch for the work: `git checkout -b issue-<number>-<short-description>`
- Commit with conventional messages referencing the issue: `fix: <description> (#<number>)`
- Push to the branch and create a PR: `gh pr create --repo <repo> --title "<title>" --body "Addresses #<number>\n\n<description of changes>"`
- After PR creation, post a completion comment on the issue (do NOT close it)

### Handling Local Changes and Merge Conflicts

**Local Unstaged Changes:** Before creating a feature branch, check `git status`. If there are unstaged or uncommitted changes:

1. **Unrelated changes** — `git stash` before branching, restore with `git stash pop` after switching back.
2. **Related or uncertain changes** — incorporate into the feature branch commit if they align, or stash and note it in the comment for the human.
3. **Never run `git reset --hard` or `git clean -f`** without explicit human permission.

**Merge Conflicts:**

1. **Branch from latest main** — always `git checkout main; git pull` before creating the feature branch.
2. **Conflicts during PR** — note in the completion comment; resolve by rebasing or merging main into the feature branch.
3. **Concurrent branch conflicts** — resolve sequentially (finish one PR, then rebase the next).
4. **Never force-push** unless explicitly told to by a human.

### Vendor Dependency Updates

The `update_vendor.bat` script lives in Game-Dev-Supreme. Game projects call it via relative path:

```batch
..\Game-Dev-Supreme\update_vendor.bat
```

The script uses the caller's working directory (`%CD%`) to locate the project's `vendor\` folder and copies from sibling source repos (SDL, SDL_image, picojson, stb). Each copy has `.git` removed to avoid nested-repo warnings.

### Visual Testing (SDL Projects)

If the target project has a steering doc that references visual testing using the SDL visual testing solution:

1. After implementing changes, run the SDL_VisualTest suite report generator to execute tests and produce the Markdown report with screenshots.
2. Attach the generated report as a comment on the GitHub issue: `gh issue comment <number> --repo <repo> --body-file <path-to-report.md>`
3. This provides visual verification that the changes did not break rendering.

### After Completing Work on an Issue

After finishing work on one issue, **immediately check for the next issue** across all repos. This includes:
- New issues that haven't been picked up
- Existing open issues with new unprocessed human comments (follow-up instructions)

Continue working until no more actionable items remain.

## Command Reference

```bash
# List open issues across all repos (sorted by creation date, oldest first)
gh issue list --repo danielsawitzki77/Zeitgeist-Evolved --state open --json number,title,labels,assignees,createdAt
gh issue list --repo danielsawitzki77/SDL_VisualTest --state open --json number,title,labels,assignees,createdAt
gh issue list --repo danielsawitzki77/Super-Civ-16 --state open --json number,title,labels,assignees,createdAt
gh issue list --repo danielsawitzki77/TerrorForm --state open --json number,title,labels,assignees,createdAt
gh issue list --repo danielsawitzki77/Game-Dev-Supreme --state open --json number,title,labels,assignees,createdAt

# Read a specific issue
gh issue view <number> --repo <owner/repo> --json title,body,labels,assignees,comments

# Fetch comments with reaction data (for detecting unprocessed human comments)
gh api repos/<owner>/<repo>/issues/<number>/comments --jq '.[] | {id, body, user: .user.login, reactions: .reactions}'

# React to a comment (mark as processed)
gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -f content=eyes

# Comment on an issue
gh issue comment <number> --repo <owner/repo> --body "🤖 [Kiro] <message>\n\ncc @danielsawitzki77-remote"

# Close an issue (only when human-approved)
gh issue close <number> --repo <owner/repo> --comment "🤖 [Kiro] Closing as approved."

# Assign an issue
gh issue edit <number> --repo <owner/repo> --add-assignee danielsawitzki77

# Create a PR
gh pr create --repo <owner/repo> --title "<title>" --body "<body>" --head <branch>
```

## Important Notes

- This workflow is non-interactive. Do not ask the user for confirmation during issue work.
- If an issue is ambiguous and cannot be resolved by common sense, post a clarifying question as a comment and move on to the next issue.
- Never force-push or modify `main`/`master` directly.
- Always verify the build passes before creating a PR.
- Issues are NEVER auto-closed. Only a human comment can authorize closure.
- All Kiro comments must be prefixed with `🤖 [Kiro]` for identification.
