@echo off
REM ============================================================
REM Kiro CLI - Periodic GitHub Issue Checker
REM Runs headless, checks all monitored repos indefinitely,
REM picks up and works on the highest-priority open issue.
REM Also checks existing open issues for new human follow-up comments.
REM Never terminates when out of work - keeps polling.
REM
REM Polling frequency:
REM   - 3 minutes (180s) during active hours (8am-10pm PST)
REM   - 30 minutes (1800s) during quiet hours (10pm-8am PST)
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
set INTERVAL_ACTIVE=180
set INTERVAL_QUIET=1800
set TAG_USER=danielsawitzki77-remote

echo ============================================================
echo  Kiro Issue Worker - Adaptive Polling
echo  Active hours (8am-10pm PST): every %INTERVAL_ACTIVE% seconds
echo  Quiet hours (10pm-8am PST):  every %INTERVAL_QUIET% seconds
echo  Working directory: %WORK_DIR%
echo  Press Ctrl+C to stop
echo ============================================================
echo.

cd /d "%WORK_DIR%"

:loop
REM Determine current hour for interval selection
REM %time% may have a leading space for single-digit hours; trim it
set "TIMESTR=%time: =0%"
set "HOUR=%TIMESTR:~0,2%"
set /a HOUR=%HOUR%

REM Default to active interval
set INTERVAL_SEC=%INTERVAL_ACTIVE%

REM Quiet hours: 22:00 (10pm) through 07:59 (8am)
if %HOUR% GEQ 22 set INTERVAL_SEC=%INTERVAL_QUIET%
if %HOUR% LSS 8 set INTERVAL_SEC=%INTERVAL_QUIET%

echo [%date% %time%] Checking for open issues (interval: %INTERVAL_SEC%s)...
echo.

kiro-cli chat --no-interactive --trust-all-tools "Check all monitored GitHub repos for open issues. Run: gh issue list --repo danielsawitzki77/Zeitgeist-Evolved --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/SDL_VisualTest --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Super-Civ-16 --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/TerrorForm --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Game-Dev-Supreme --state open --json number,title,labels,assignees,createdAt. Pick the highest-priority open issue using this priority order: critical/high labels first, then medium, then no-label (treat as medium), then low. Within the same tier, oldest first. IMPORTANT: Deduce the correct target project from the issue title and body. An issue may be filed in one repo but describe changes for another. Map keywords: 'issue checker/hooks/polling/batch file/game dev supreme' to Game-Dev-Supreme, 'zeitgeist/evolved' to Zeitgeist-Evolved, 'SDL/visual test' to SDL_VisualTest, 'super civ/civ 16' to Super-Civ-16, 'terrorform' to TerrorForm. If ambiguous, default to the repo where the issue is filed. Apply changes to the correct repo and open the PR there. Only work on issues in repos whose workspace folders exist under c:\Users\Daniel Sawitzki\Desktop\github. For issues already being worked on (have a Kiro completion comment), check for new unprocessed human comments — human comments are those NOT prefixed with the robot emoji [Kiro] prefix. Unprocessed means no eyes reaction yet. If new human follow-up instructions are found, process each comment sequentially and post a separate reply for each one, then react with eyes to mark each as processed. If a human comment approves closure (e.g. looks good, approved, close this, done), close the issue. Do NOT auto-close issues — only close when a human explicitly approves. For new issues: assign to danielsawitzki77, comment that Kiro is picking it up (prefix all comments with robot emoji [Kiro]), create a feature branch, implement the fix, verify the build passes, commit, push, and create a PR. Post a completion comment but leave the issue open. If the project has a steering doc referencing SDL visual testing, run the SDL_VisualTest suite report generator and attach the MD report output as a comment on the GitHub issue using gh issue comment with --body-file. TAGGING: Include @danielsawitzki77-remote at the end of every comment you post on GitHub issues so the user gets notified. If no actionable issues are found, just report that and stop."

echo.
echo [%date% %time%] Cycle complete. Waiting %INTERVAL_SEC% seconds...
echo.
timeout /t %INTERVAL_SEC% /nobreak
goto loop
