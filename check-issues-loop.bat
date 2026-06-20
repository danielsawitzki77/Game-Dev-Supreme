@echo off
REM If running under PowerShell, re-launch under cmd.exe
if defined PSModulePath if not defined __CMD_RELAUNCH (
    set "__CMD_RELAUNCH=1"
    cmd /c "%~f0" %*
    exit /b %errorlevel%
)
set "__CMD_RELAUNCH="
REM ============================================================
REM Kiro CLI - Periodic GitHub Issue Checker
REM Runs headless, checks all monitored repos indefinitely,
REM picks up and works on the highest-priority open issue.
REM Also checks existing open issues for new human follow-up comments.
REM Never terminates when out of work - keeps polling.
REM
REM Polling frequency:
REM   - 10 minutes (600s) during active hours (8am-10pm PST)
REM   - 30 minutes (1800s) during quiet hours (10pm-8am PST)
REM
REM During the countdown, press any key to force an immediate check.
REM If Kiro found and worked on an issue, the next check runs
REM immediately (no wait). Waits only when no work was found.
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
set INTERVAL_ACTIVE=600
set INTERVAL_QUIET=1800
set TAG_USER=danielsawitzki77-remote
set "MARKER_FILE=%TEMP%\kiro_no_work.tmp"

echo ============================================================
echo  Kiro Issue Worker - Adaptive Polling
echo  Active hours (8am-10pm PST): every %INTERVAL_ACTIVE%s
echo  Quiet hours (10pm-8am PST):  every %INTERVAL_QUIET%s
echo  Press any key during countdown to check immediately
echo  Working directory: %WORK_DIR%
echo  Press Ctrl+C to stop
echo ============================================================
echo.

cd /d "%WORK_DIR%"

:loop
REM Determine current hour for interval selection
set "TIMESTR=%time: =0%"
set "HOUR=%TIMESTR:~0,2%"
set /a HOUR=%HOUR%

REM Default to active interval
set INTERVAL_SEC=%INTERVAL_ACTIVE%

REM Quiet hours: 22:00 (10pm) through 07:59 (8am)
if %HOUR% GEQ 22 set INTERVAL_SEC=%INTERVAL_QUIET%
if %HOUR% LSS 8 set INTERVAL_SEC=%INTERVAL_QUIET%

REM --- Cleanup stale local branches across all repos ---
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Zeitgeist-Evolved"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Super Civ 16"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\TerrorForm"

echo [%date% %time%] Checking for open issues (interval: %INTERVAL_SEC%s)...
echo.

REM Delete marker file before running
if exist "%MARKER_FILE%" del "%MARKER_FILE%"

REM Run Kiro CLI. The prompt instructs Kiro to create a marker file when no work is found.
kiro-cli chat --no-interactive --trust-all-tools "Check all monitored GitHub repos for open issues. Run: gh issue list --repo danielsawitzki77/Zeitgeist-Evolved --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/SDL_VisualTest --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Super-Civ-16 --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/TerrorForm --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Game-Dev-Supreme --state open --json number,title,labels,assignees,createdAt. Pick the highest-priority open issue using this priority order: critical/high labels first, then medium, then no-label (treat as medium), then low. Within the same tier, oldest first. IMPORTANT: Deduce the correct target project from the issue title and body. An issue may be filed in one repo but describe changes for another. Map keywords: 'issue checker/hooks/polling/batch file/game dev supreme' to Game-Dev-Supreme, 'zeitgeist/evolved' to Zeitgeist-Evolved, 'SDL/visual test' to SDL_VisualTest, 'super civ/civ 16' to Super-Civ-16, 'terrorform' to TerrorForm. If ambiguous, default to the repo where the issue is filed. Apply changes to the correct repo and open the PR there. Only work on issues in repos whose workspace folders exist under c:\Users\Daniel Sawitzki\Desktop\github. For issues already being worked on (have a Kiro completion comment), check for new unprocessed human comments — human comments are those NOT prefixed with the robot emoji [Kiro] prefix. Unprocessed means no eyes reaction yet. If new human follow-up instructions are found, process each comment sequentially and post a separate reply for each one, then react with eyes to mark each as processed. If a human comment approves closure (e.g. looks good, approved, close this, done), close the issue. Do NOT auto-close issues — only close when a human explicitly approves. For new issues: assign to danielsawitzki77, comment that Kiro is picking it up (prefix all comments with robot emoji [Kiro]), create a feature branch, implement the fix, verify the build passes, commit, push, and create a PR. Post a completion comment but leave the issue open. If the project has a steering doc referencing SDL visual testing, run the SDL_VisualTest suite report generator and attach the MD report output as a comment on the GitHub issue using gh issue comment with --body-file. SCREENSHOTS: When reading issue bodies or comments, look for embedded images (img tags or ![alt](url) markdown). Download and analyze these screenshots using the image reading tool - they often contain error messages, UI state, or other critical context. Reference what you see in your reply so the human knows images were processed. TAGGING: Include @danielsawitzki77-remote at the end of every comment you post on GitHub issues so the user gets notified. If no actionable issues are found, just report that and stop. SIGNAL: If you found no actionable work, write the word NO_WORK to the file: %MARKER_FILE%"

echo.
echo [%date% %time%] Cycle complete.

REM Check if Kiro found no work — if marker exists, wait; otherwise re-run immediately
if exist "%MARKER_FILE%" (
    echo ============================================================
    echo  Kiro Issue Worker - Adaptive Polling
    echo  Active hours (8am-10pm PST): every %INTERVAL_ACTIVE%s
    echo  Quiet hours (10pm-8am PST):  every %INTERVAL_QUIET%s
    echo  Press any key during countdown to check immediately
    echo  Working directory: %WORK_DIR%
    echo  Press Ctrl+C to stop
    echo ============================================================
    echo.
    echo No actionable issues found. Waiting %INTERVAL_SEC% seconds...
    echo Press any key to check immediately.
    echo.
    timeout /t %INTERVAL_SEC%
) else (
    echo Work was processed! Re-checking immediately for more issues...
    echo.
)
goto loop

REM ============================================================
REM Subroutine: cleanup_branches
REM Prunes remote tracking refs and deletes local branches
REM whose upstream is gone (already merged/deleted on remote),
REM as well as local-only branches with no upstream that are
REM already merged into main. Never deletes main/master or
REM the currently checked-out branch. Uses -d (safe delete)
REM which only works if the branch is fully merged.
REM ============================================================
:cleanup_branches
set "REPO_PATH=%~1"
if not exist "%REPO_PATH%\.git" goto :eof

pushd "%REPO_PATH%"
echo [Cleanup] %REPO_PATH%

REM Fetch and prune stale remote tracking branches
git fetch --prune >nul 2>&1

REM Delete local branches whose upstream is gone (merged PRs, deleted remotes)
for /f "tokens=1" %%b in ('git branch -vv 2^>nul ^| findstr ": gone]"') do (
    if /i not "%%b"=="main" if /i not "%%b"=="master" if not "%%b"=="*" (
        echo   Deleting stale branch: %%b
        git branch -d "%%b" >nul 2>&1
        if errorlevel 1 (
            echo   [skipped - not fully merged: %%b]
        )
    )
)

REM Delete local branches that were never published (no upstream) and are merged into main
for /f "tokens=1" %%b in ('git branch --merged main 2^>nul') do (
    if /i not "%%b"=="main" if /i not "%%b"=="master" if not "%%b"=="*" (
        echo   Deleting merged local branch: %%b
        git branch -d "%%b" >nul 2>&1
    )
)

popd
goto :eof
