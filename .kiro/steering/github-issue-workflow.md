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
- `danielsawitzki77/Particluar`

## Issue Pickup Logic

### Exclusion Filter

- **Skip issues with the `Draft` label.** These are not ready for automated pickup. Do not assign, comment, or work on them. Treat them as invisible during issue scanning.
- **Only pick up issues that have the `Ready for Pickup` label.** Issues without this label are not eligible for automated work, even if they have no `Draft` label. Treat unlabeled issues as invisible during scanning.

In summary, an issue is eligible for pickup if and only if:
1. It does NOT have the `Draft` label, AND
2. It DOES have the `Ready for Pickup` label.

### Priority Order

1. Issues with `priority: critical` or `priority: high` labels
2. Issues with `priority: medium` label
3. Issues with no priority label (treat as medium)
4. Issues with `priority: low` label
5. Within the same priority tier: oldest issue first (FIFO)

### On Pickup

When picking up an issue:

1. **Assign it** to `danielsawitzki77` if not already assigned: `gh issue edit <number> --repo <repo> --add-assignee danielsawitzki77`
2. **React with 👀** on the issue itself to signal processing has started: `gh api repos/<owner>/<repo>/issues/<number>/reactions -f content=eyes`
3. **Post a comment** indicating work has started: `gh issue comment <number> --repo <repo> --body "🤖 [Kiro] Picking up this issue and starting work."`
4. **Read the full issue body** to understand the task
5. **Fill in missing fields** by common sense (labels, milestone if obvious)
6. **After work is complete**, add a 👍 reaction on the issue to signal completion: `gh api repos/<owner>/<repo>/issues/<number>/reactions -f content=+1`

The two-phase reaction pattern (👀 → 👍) lets observers see at a glance whether an issue is being actively worked on or is finished.

## Working on an Issue

### Communication

- **All machine-generated comments** must be prefixed with `🤖 [Kiro]` so they can be identified as non-human.
- **Tag the user**: Every comment must end with a blank line followed by `cc @danielsawitzki77-remote` so the user receives a GitHub notification.
- **Questions/blockers**: Post as a comment on the issue (see Comment Posting below)
- **Progress updates**: Post as comments when reaching significant milestones
- **Completion**: Post a summary comment (do NOT close the issue — see Issue Lifecycle below)

### Comment Posting (--body-file)

**Always use `--body-file` with a temp file for GitHub comments and PR bodies.** Never use `--body "...\n..."` — Windows CMD does not interpret `\n` as newlines, resulting in literal `\n` text in comments.

Workflow for posting any comment:

1. Write the comment content to a temp file (e.g., `%TEMP%\gh_comment.md`)
2. Post using: `gh issue comment <number> --repo <repo> --body-file <temp-file>`
3. Delete the temp file

Example:
```batch
echo 🤖 [Kiro] Picking up this issue.> %TEMP%\gh_comment.md
echo.>> %TEMP%\gh_comment.md
echo cc @danielsawitzki77-remote>> %TEMP%\gh_comment.md
gh issue comment <number> --repo <repo> --body-file %TEMP%\gh_comment.md
del %TEMP%\gh_comment.md
```

For Kiro CLI (non-batch context), write the temp file using the file-writing tool, then invoke `gh issue comment --body-file`. This guarantees correct newlines on all platforms.

### Issue Lifecycle

Issues follow a managed lifecycle rather than being auto-closed:

1. **Issues stay open** after work is completed. Do NOT close issues automatically.
2. **After completing work**, post a summary comment (using `--body-file`): `🤖 [Kiro] ✅ Work complete. <summary of what was done>. PR: <link>. Awaiting human approval to close.`
3. **Check for new human comments** on open issues each cycle. Human comments are any comments NOT prefixed with `🤖 [Kiro]`. If new human comments contain follow-up instructions, treat them as additional work items on that issue.
4. **Mark processed comments with a reaction** to track progress: `gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -f content=eyes` — use the 👀 reaction to indicate the comment has been read and acted upon.
5. **Only close an issue** when a human comment explicitly approves closure (e.g., "looks good", "approved", "close this", "done"). Then close with: `gh issue close <number> --repo <repo> --comment "🤖 [Kiro] Closing as approved."`

### Detecting Human Comments

When checking open issues for follow-up:

1. Fetch comments: `gh api repos/<owner>/<repo>/issues/<number>/comments --jq '.[] | {id, body, user: .user.login, reactions: .reactions}'`
2. A comment is **human** if its body does NOT start with `🤖 [Kiro]`
3. A comment is **unprocessed** if it has no 👀 (eyes) reaction from the bot
4. Process unprocessed human comments **sequentially** using the two-phase reaction pattern:
   - **Immediately** react with 👀 on the comment to signal processing has started: `gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -f content=eyes`
   - Read and act on the comment's instructions
   - Post a reply
   - **After replying**, add a 👍 reaction to signal processing is complete: `gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -f content=+1`

The two-phase pattern (👀 → 👍) on comments mirrors the issue-level pattern and lets observers distinguish "being worked on" from "done".

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
- "particluar", "particle" → `Particluar`

### Local Path Mapping

GitHub repo names do NOT always match local folder names. **Never clone a repo if a folder for it already exists** — use this mapping to find the correct local path:

| GitHub Repo Slug | Local Folder Name | Full Local Path |
|---|---|---|
| `Zeitgeist-Evolved` | `Zeitgeist Evolved` | `c:\Users\Daniel Sawitzki\Desktop\github\Zeitgeist Evolved` |
| `SDL_VisualTest` | `SDL_VisualTest` | `c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest` |
| `Super-Civ-16` | `Super Civ 16` | `c:\Users\Daniel Sawitzki\Desktop\github\Super Civ 16` |
| `TerrorForm` | `TerrorForm` | `c:\Users\Daniel Sawitzki\Desktop\github\TerrorForm` |
| `Game-Dev-Supreme` | `Game-Dev-Supreme` | `c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme` |
| `Particluar` | `Particluar` | `c:\Users\Daniel Sawitzki\Desktop\github\Particluar` |

**Critical rule:** When determining if a repo is "available in the workspace", check this mapping table — do NOT rely on the GitHub repo slug matching a folder name exactly. A mismatch (e.g., hyphen vs space) does not mean the repo is missing. If the mapped local path exists, use it. Never `git clone` a repo that already has a local folder listed here.

### Scope Rules

- Only work on repos whose workspace folder exists under `c:\Users\Daniel Sawitzki\Desktop\github`
- If the highest-priority issue is in a repo not available on disk, skip it and note that in a comment: "🤖 [Kiro] Cannot work on this — repo not available in current workspace. Skipping to next issue."
- If no issues are workable (all in unavailable repos), report that and stop

### Cross-Repo References

**Critical:** GitHub interprets `#<number>` relative to the repo where the comment or PR lives. When working across repos, ALWAYS use fully-qualified references.

**Rules by context:**

| Where you're posting | How to reference an issue | How to reference a PR |
|---|---|---|
| **PR body** (in target repo) | `danielsawitzki77/<issue-repo>#<number>` | N/A (it IS the PR) |
| **Issue comment** (in issue repo) | `#<number>` (same repo, OK) | Full URL: `https://github.com/danielsawitzki77/<pr-repo>/pull/<number>` |
| **PR comment** (in target repo) | `danielsawitzki77/<issue-repo>#<number>` | `#<number>` (same repo, OK) |
| **Commit message** (in target repo) | `danielsawitzki77/<issue-repo>#<number>` | N/A |

**Key principle:** Use bare `#<number>` ONLY when referencing something in the SAME repo where the text will appear. For anything cross-repo, use either:
- Fully-qualified: `danielsawitzki77/<repo>#<number>` (for issues)
- Full URL: `https://github.com/danielsawitzki77/<repo>/pull/<number>` (for PRs — always use full URL for PRs since `danielsawitzki77/<repo>#<number>` links to the issue with that number, not the PR)

**Concrete examples:**

Issue filed in `Game-Dev-Supreme#60`, PR created in `Zeitgeist-Evolved`:
- PR body: `Addresses danielsawitzki77/Game-Dev-Supreme#60`
- Issue completion comment: `PR: https://github.com/danielsawitzki77/Zeitgeist-Evolved/pull/42`
- Commit message: `fix: menu navigation (danielsawitzki77/Game-Dev-Supreme#60)`

Issue filed in `Game-Dev-Supreme#61`, PR created in `SDL_VisualTest`:
- PR body: `Addresses danielsawitzki77/Game-Dev-Supreme#61`
- Issue completion comment: `PR: https://github.com/danielsawitzki77/SDL_VisualTest/pull/19`
- Commit message: `feat: add spec (danielsawitzki77/Game-Dev-Supreme#61)`

**Common mistakes to avoid:**
- ❌ `PR: #42` in a Game-Dev-Supreme issue comment (links to Game-Dev-Supreme#42, not the PR)
- ❌ `Addresses #60` in a Zeitgeist-Evolved PR (links to Zeitgeist-Evolved#60, not Game-Dev-Supreme#60)
- ❌ `danielsawitzki77/Zeitgeist-Evolved#42` for a PR (links to issue #42, not PR #42 — use full URL instead)

### Pull Latest Before Working

Before starting any work on a repo, **always pull latest on ALL local repos** — not just the target. Dependency repos (SDL_VisualTest, SDL, SDL_image, etc.) may have been updated by previous PRs.

At the start of each work cycle (before creating a feature branch):

1. For **each repo** in the local path mapping table:
   - `cd <local-path>; git checkout main; git pull`
2. This ensures library code, build scripts, and shared tooling are up to date.
3. Only then proceed to create the feature branch in the target repo.

This prevents stale-dependency issues (e.g., missing classes from recently merged PRs).

### Work Execution

- Follow existing project conventions (steering docs, build systems, etc.)
- Create a feature branch for the work: `git checkout -b issue-<number>-<short-description>`
- Commit with conventional messages referencing the issue: `fix: <description> (danielsawitzki77/<issue-repo>#<number>)`
- Push to the branch and create a PR: `gh pr create --repo <target-repo> --title "<title>" --body-file <temp-file>` (write PR body to a temp file first to preserve newlines)
- Assign the PR to the issue's assignees: `gh pr edit <pr-number> --repo <target-repo> --add-assignee <assignee1>,<assignee2>`
- **Always assign `danielsawitzki77`** to the PR even if the issue has no assignees: `gh pr edit <pr-number> --repo <target-repo> --add-assignee danielsawitzki77`
- **Always request review from `danielsawitzki77-remote`** so the human gets a GitHub notification: `gh pr edit <pr-number> --repo <target-repo> --add-reviewer danielsawitzki77-remote`
- After PR creation, post a completion comment on the issue with the full PR URL (do NOT close it)

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

#### MANDATORY GIF REQUIREMENT

**CRITICAL:** If the issue body contains ANY of the following phrases, GIF recording and upload is MANDATORY — you MUST NOT post a completion comment or mark work as done until the GIF has been recorded, uploaded, and posted:

- "animated GIF"
- "SDL_VisualTest_GifRecorder"
- "capture an animated GIF"
- "Attach the GIF"
- "record a GIF"

**Enforcement:** Before posting any "✅ Work complete" comment, verify:
1. A GIF was recorded (file exists in `test_output/diverse_runs/run_seed<N>/gifs/`)
2. The GIF was uploaded via `upload_gif.bat` (not just referenced locally)
3. The upload comment is visible on the issue

If any of these are not satisfied and the issue body requires a GIF, DO NOT post the completion comment. Instead, go back and record/upload the GIF first.

#### Execution Steps

When visual testing applies (issue body requests it, OR the target project has a steering doc referencing SDL visual testing):

1. **Build and run tests** using `scripts/run_diverse_tests.bat` (Zeitgeist) or `tools/build_and_record.bat` (SDL_VisualTest). This produces screenshots, GIFs, and a Markdown report.
2. **Verify GIF exists** in `test_output/diverse_runs/run_seed<N>/gifs/`. If it doesn't exist, the test flow may not have the `--gif` flag — re-run with `--gif` explicitly.
3. **Attach the report** as a comment on the GitHub issue: `gh issue comment <number> --repo <repo> --body-file <path-to-report.md>`
4. **Upload GIFs as actual attachments** using `tools/upload_gif.bat` from SDL_VisualTest: `"c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest\tools\upload_gif.bat" <repo> <number> <gif_path> "<caption>"`. This uploads the GIF to a GitHub release asset and posts a comment with the embedded image URL so it renders inline. Do NOT just reference local file paths — GIFs must be uploaded and visible in the browser.
5. **Only then** proceed to post the completion comment and create/finalize the PR.

### Build Provenance Verification

Before uploading any GIF to a GitHub issue or PR, **verify build provenance** to ensure the recording reflects the current code:

1. **Read `build_info.txt`** from the test output directory (the directory containing the GIF or its parent). This file is written by the build script after each test run.

2. **Verify required fields exist.** The file must contain both a `commit` field and a `timestamp` field in `key=value` format. If `build_info.txt` does not exist:
   - Abort the upload
   - Post a comment on the issue: `🤖 [Kiro] GIF upload aborted: build_info.txt not found. Run tests before uploading.`
   - Do NOT proceed with the upload

3. **If `build_info.txt` exists but is missing `commit` or `timestamp` fields:**
   - Abort the upload
   - Post a comment on the issue: `🤖 [Kiro] GIF upload aborted: build_info.txt is malformed (missing required fields). Re-run tests before uploading.`
   - Do NOT proceed with the upload

4. **Verify the `commit` field matches current HEAD.** Get the full 40-character SHA of the currently checked-out branch (`git rev-parse HEAD`) and compare it against the `commit` field value. If they do not match:
   - Abort the upload
   - Post a comment on the issue: `🤖 [Kiro] GIF upload aborted: build_info.txt commit (<recorded>) does not match current HEAD (<actual>). Re-run tests before uploading.`
   - Replace `<recorded>` with the value from build_info.txt and `<actual>` with the current HEAD SHA
   - Do NOT proceed with the upload

5. **Check timestamp freshness.** Parse the `timestamp` field (ISO 8601 UTC format) and compare against the current system time. If the timestamp is older than 60 minutes:
   - Post a warning comment on the issue: `🤖 [Kiro] WARNING: Test results are over 60 minutes old`
   - **Allow the upload to proceed** (this is a warning only, not a blocker)

6. **If all checks pass** (build_info.txt exists, has required fields, commit matches HEAD), proceed with the GIF upload as normal.

### GIF Flow Selection (Default Behavior)

When recording a GIF for an issue, **always select the flow that exercises the issue's critical path**. This is the default behavior — no bespoke per-issue modifications should be needed.

Use the `--flow` argument to select the relevant test flow:

```bash
tests\test_integration_diverse.exe --seed 1 --runs 1 --gif --flow <flow-name>
```

**Flow name selection logic:** Deduce the correct flow from the issue title and body:

| Issue keywords | Flow name |
|---|---|
| stop, stop button, playback controls | `stop-button` |
| campaign, examples, level select | `campaign` |
| tutorial | `tutorials` |
| challenge | `challenges` |
| editor, sandbox, create level | `editor` |
| settings, preferences, options | `settings` |
| exit, quit, leave | `exit` |
| win, victory, complete | `win` |
| lose, fail, timeout, game over | `lose` |
| overlay, popup, dialog | `overlay` |

If no clear match, use `campaign` as the default flow (most common user path).

**Adding new flows:** When a new feature area needs GIF coverage:
1. Add a `BuildFlow<Name>(int seed)` function in `test_integration_diverse.cpp`
2. Add the name to the `g_namedFlows[]` lookup table
3. No other changes needed — Kiro will automatically select it based on issue keywords

### Checking PR Comments

Issues often reference PRs (created by Kiro or humans). These PRs may receive review comments, change requests, or general comments that need action. Each cycle, check referenced PRs for unprocessed comments:

1. **Identify referenced PRs** — When processing an open issue's comments, look for PR URLs in Kiro completion comments (format: `https://github.com/danielsawitzki77/<repo>/pull/<number>`). Also check `gh pr list --repo <repo> --state open --json number,title,headRefName` for branches matching issue patterns (e.g., `issue-<number>-*`).

2. **Fetch PR comments** — For each referenced PR, fetch both review comments and issue-style comments:
   ```bash
   # PR conversation comments (issue-style)
   gh api repos/<owner>/<repo>/issues/<pr-number>/comments --jq '.[] | {id, body, user: .user.login, reactions: .reactions}'
   # PR review comments (inline code review)
   gh api repos/<owner>/<repo>/pulls/<pr-number>/comments --jq '.[] | {id, body, path, user: .user.login, reactions: .reactions}'
   # PR reviews (approve/request changes/comment)
   gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews --jq '.[] | {id, body, state, user: .user.login}'
   ```

3. **Detect unprocessed human comments** — Same logic as issue comments:
   - A comment is **human** if its body does NOT start with `🤖 [Kiro]`
   - A comment is **unprocessed** if it has no 👀 (eyes) reaction
   - PR reviews with state `CHANGES_REQUESTED` that haven't been addressed count as unprocessed

4. **Act on PR comments** — When unprocessed human comments or change requests are found:
   - Read and understand the requested change
   - Check out the PR's branch: `git checkout <branch-name>`
   - Implement the requested changes
   - Commit with a message referencing the review: `fix: address review feedback (danielsawitzki77/<repo>#<issue-number>)`
   - Push to the same branch (the PR updates automatically)
   - Reply to the comment on the PR: `gh api repos/<owner>/<repo>/issues/<pr-number>/comments -f body="🤖 [Kiro] Addressed: <summary of change>\n\ncc @danielsawitzki77-remote"`
   - React with 👀 on the processed comment: `gh api repos/<owner>/<repo>/issues/comments/<comment-id>/reactions -f content=eyes`
   - For inline review comments: `gh api repos/<owner>/<repo>/pulls/comments/<comment-id>/reactions -f content=eyes`

5. **Priority** — PR comments are treated as follow-ups to their parent issue. They share the same priority tier as the issue. Process them during the same cycle as the issue check.

### After Completing Work on an Issue

After finishing work on one issue, **immediately check for the next issue** across all repos. This includes:
- New issues that haven't been picked up
- Existing open issues with new unprocessed human comments (follow-up instructions)
- Open PRs with new unprocessed review comments or change requests

Continue working until no more actionable items remain.

### Stale Branch Cleanup

At the start of each issue-checking cycle, prune stale local branches across all repos:

1. For each repo in the local path mapping:
   - Run `git fetch --prune` to remove stale remote tracking refs
   - Delete local branches whose upstream is marked `gone` (PR was merged and remote branch deleted): `git branch -d <branch>`
   - Never delete `main`, `master`, or the currently checked-out branch
   - Use `-d` (safe delete) — if the branch isn't fully merged locally (e.g., squash merges), use `-D` only when the remote tracking branch is confirmed gone
2. This prevents accumulation of stale feature branches from completed PRs

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

# Comment on an issue (always use --body-file for multi-line)
gh issue comment <number> --repo <owner/repo> --body-file <temp-file>

# Close an issue (only when human-approved)
gh issue close <number> --repo <owner/repo> --comment "🤖 [Kiro] Closing as approved."

# Assign an issue
gh issue edit <number> --repo <owner/repo> --add-assignee danielsawitzki77

# Create a PR (always use --body-file for multi-line)
gh pr create --repo <owner/repo> --title "<title>" --body-file <temp-file> --head <branch>

# Assign PR to issue assignees
gh pr edit <pr-number> --repo <owner/repo> --add-assignee <assignee1>,<assignee2>
```

## IDE-Triggered Work (Kiro IDE Sessions)

When work is triggered from the Kiro IDE (interactive chat sessions, as opposed to the CLI/issue-checker polling loop), it must be documented in GitHub the same way as issue-driven work.

### Issue Creation

1. **Always create a tracking issue** in `danielsawitzki77/Game-Dev-Supreme` for any IDE-triggered work session that results in code changes or meaningful actions.
2. **Issue title** must match the name of the IDE conversation (the user's initial prompt or conversation title).
3. **Issue body** should summarize the task/request from the conversation.
4. **Labels**: Add `ide-triggered` label to distinguish from manually filed issues. Add other relevant labels (project name, priority) as appropriate.

### Documentation Requirements

All the same communication rules apply as for issue-driven work:

- **All comments** prefixed with `🤖 [Kiro]`
- **Tag the user**: Every comment ends with a blank line followed by `cc @danielsawitzki77-remote`
- **Use `--body-file`** for all comments and PR bodies (never inline `--body` with newlines)
- **React with 👀** on the issue when starting work
- **React with 👍** on the issue when work is complete
- **Post progress updates** as comments when reaching significant milestones
- **Post a completion comment** summarizing what was done, linking any PRs created
- **Do NOT close the issue** — leave it open for human review/approval, same as any other issue

### PR Linking

If the IDE work results in a PR:

- Create the PR in the **target project's repo** (not necessarily Game-Dev-Supreme)
- Link the tracking issue in the PR body using fully-qualified references: `Addresses danielsawitzki77/Game-Dev-Supreme#<number>`
- Post the full PR URL back on the tracking issue
- Assign `danielsawitzki77` and request review from `danielsawitzki77-remote`

### When NOT to Create an Issue

Skip issue creation for:
- Pure Q&A / informational questions with no code changes
- Exploratory conversations that don't result in any action
- Conversations where the user explicitly says not to create an issue

### Workflow Summary

```
1. User starts IDE conversation
2. Kiro determines work will produce changes
3. Create issue in Game-Dev-Supreme with conversation name as title
4. React 👀 on the issue
5. Post pickup comment
6. Do the work (branch, commit, PR — same as issue-driven flow)
7. Post completion comment with PR link
8. React 👍 on the issue
9. Leave issue open for human approval
```

## Important Notes

- This workflow is non-interactive. Do not ask the user for confirmation during issue work.
- If an issue is ambiguous and cannot be resolved by common sense, post a clarifying question as a comment and move on to the next issue.
- Never force-push or modify `main`/`master` directly.
- Always verify the build passes before creating a PR.
- Issues are NEVER auto-closed. Only a human comment can authorize closure.
- All Kiro comments must be prefixed with `🤖 [Kiro]` for identification.
