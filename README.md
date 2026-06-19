# Game-Dev-Supreme

Central workspace hub for autonomous GitHub issue-driven development across all danielsawitzki77 game repositories.

## What This Does

This repo contains Kiro configuration (hooks, steering docs, polling scripts) for autonomous issue processing. When active, Kiro will:

1. Check all monitored repos for open GitHub issues
2. Pick up the highest-priority issue (assign, comment, start work)
3. Communicate via issue comments (questions, progress, completion)
4. Create PRs and leave issues open for human review
5. Chain to the next issue until the queue is empty

## Monitored Repositories

- Zeitgeist-Evolved
- SDL_VisualTest
- Super-Civ-16
- TerrorForm
- Game-Dev-Supreme

## Structure

```
.kiro/
  hooks/                  # Kiro IDE hooks (agentStop, manual trigger)
  steering/               # Workflow steering doc (source of truth)
.github/
  ISSUE_TEMPLATE/         # Issue templates for all repos
check-issues-loop.bat     # Headless polling script (AFK mode)
install.bat               # Installs steering doc to ~/.kiro/steering/
Game-Dev-Supreme.code-workspace  # Multi-root VS Code workspace
```

## Usage

### IDE Hooks

- **Automatic:** `agentStop` hook fires after every Kiro task
- **Manual:** Click "Check Issues Now" in Kiro Agent Hooks panel

### Headless Polling (AFK mode)

Run `check-issues-loop.bat` to poll every 60 seconds and work issues autonomously.

#### Prerequisites

1. Kiro CLI: `irm 'https://cli.kiro.dev/install.ps1' | iex`
2. Kiro Pro subscription (headless mode requires API key)
3. API key from [app.kiro.dev/settings/account](https://app.kiro.dev/settings/account)
4. GitHub CLI (`gh`) installed and authenticated

#### Setup

Set `KIRO_API_KEY` in `check-issues-loop.bat`, then run it.

### Installation

Run `install.bat` to copy the steering doc to `~/.kiro/steering/` (needed for global Kiro recognition).

## Issue Lifecycle

1. Kiro picks up an issue → assigns it, posts `🤖 [Kiro]` comment
2. Work is completed → PR created, summary comment posted, issue stays OPEN
3. Human reviews → adds comments with follow-up or approval
4. Kiro processes follow-ups → acts on human comments, marks with 👀
5. Human approves closure → only then does Kiro close the issue

## Note on Kiro-Tooling

The `Kiro-Tooling` repository is deprecated. All tooling configuration now lives here in Game-Dev-Supreme.
