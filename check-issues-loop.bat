@echo off
REM ============================================================
REM Kiro CLI - Periodic GitHub Issue Checker
REM Runs headless, checks all monitored repos every 60 seconds,
REM picks up and works on the highest-priority open issue.
REM Also checks existing open issues for new human follow-up comments.
REM
REM Prerequisites:
REM   1. Install Kiro CLI: irm 'https://cli.kiro.dev/install.ps1' | iex
REM   2. Authenticate:     kiro-cli login
REM   3. Set API key:      set KIRO_API_KEY=your-api-key-here
REM      (or set it as a system environment variable)
REM
REM Usage: Just double-click this file or run from a terminal.
REM        Press Ctrl+C to stop.
REM ============================================================

set KIRO_API_KEY=ksk_ZNG5mUlKiZW1Wn8dDdOkpNcJ8dWBsYD9
set WORK_DIR=c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme
set INTERVAL_SEC=60

echo ============================================================
echo  Kiro Issue Worker - Checking every %INTERVAL_SEC% seconds
echo  Working directory: %WORK_DIR%
echo  Press Ctrl+C to stop
echo ============================================================
echo.

cd /d "%WORK_DIR%"

:loop
echo [%date% %time%] Checking for open issues...
echo.

kiro-cli chat --no-interactive --trust-all-tools "Check all monitored GitHub repos for open issues. Run: gh issue list --repo danielsawitzki77/Zeitgeist-Evolved --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/SDL_VisualTest --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Super-Civ-16 --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/TerrorForm --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Game-Dev-Supreme --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Kiro-Tooling --state open --json number,title,labels,assignees,createdAt. Pick the highest-priority open issue using this priority order: critical/high labels first, then medium, then no-label (treat as medium), then low. Within the same tier, oldest first. IMPORTANT: Deduce the correct target project from the issue title and body. An issue may be filed in one repo but describe changes for another. Map keywords: 'kiro tooling/issue checker/hooks/polling/batch file' to Kiro-Tooling, 'zeitgeist/evolved' to Zeitgeist-Evolved, 'SDL/visual test' to SDL_VisualTest, 'super civ/civ 16' to Super-Civ-16, 'terrorform' to TerrorForm, 'game dev supreme' to Game-Dev-Supreme. If ambiguous, default to the repo where the issue is filed. Apply changes to the correct repo and open the PR there. Only work on issues in repos whose workspace folders exist under c:\Users\Daniel Sawitzki\Desktop\github. For issues already being worked on (have a Kiro completion comment), check for new unprocessed human comments — human comments are those NOT prefixed with the robot emoji [Kiro] prefix. Unprocessed means no eyes reaction yet. If new human follow-up instructions are found, act on them and react with eyes to mark as processed. If a human comment approves closure (e.g. looks good, approved, close this, done), close the issue. Do NOT auto-close issues — only close when a human explicitly approves. For new issues: assign to danielsawitzki77, comment that Kiro is picking it up (prefix all comments with robot emoji [Kiro]), create a feature branch, implement the fix, verify the build passes, commit, push, and create a PR. Post a completion comment but leave the issue open. If the project has a steering doc referencing SDL visual testing, run the SDL_VisualTest suite report generator and attach the MD report output as a comment on the GitHub issue using gh issue comment with --body-file. If no actionable issues are found, just report that and stop."

echo.
echo [%date% %time%] Cycle complete. Waiting %INTERVAL_SEC% seconds...
echo.
timeout /t %INTERVAL_SEC% /nobreak
goto loop
