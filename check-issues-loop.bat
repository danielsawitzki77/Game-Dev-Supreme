@echo off
REM ============================================================
REM Kiro CLI - Periodic GitHub Issue Checker
REM Runs headless, checks all monitored repos indefinitely,
REM picks up and works on the highest-priority open issue.
REM Also checks existing open issues for new human follow-up comments.
REM Also checks referenced PRs for new human comments and change requests.
REM Never terminates when out of work - keeps polling.
REM
REM Polling frequency:
REM   - 10 minutes (600s) during active hours (8am-10pm PST)
REM   - 30 minutes (1800s) during quiet hours (10pm-8am PST)
REM
REM Controls:
REM   During countdown:
REM     C = force an immediate check
REM     P = PAUSE polling (suspends all activity)
REM   While paused:
REM     Any key = resume + trigger immediate check
REM
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
echo  During countdown: C=check now, P=pause polling
echo  While paused: any key resumes + triggers immediate check
echo  Working directory: %WORK_DIR%
echo  Press Ctrl+C to stop
echo ============================================================
echo.

cd /d "%WORK_DIR%"

REM Initialize pause state
set "PAUSED=0"

:loop
REM Determine current hour for interval selection
set "TIMESTR=%time: =0%"
set "HOUR=%TIMESTR:~0,2%"
REM Strip leading zero to prevent octal interpretation (08, 09 are invalid octal)
if "%HOUR:~0,1%"=="0" set "HOUR=%HOUR:~1%"
if "%HOUR%"=="" set "HOUR=0"
set /a HOUR=%HOUR%

REM Default to active interval
set INTERVAL_SEC=%INTERVAL_ACTIVE%

REM Quiet hours: 22:00 (10pm) through 07:59 (8am)
if %HOUR% GEQ 22 set INTERVAL_SEC=%INTERVAL_QUIET%
if %HOUR% LSS 8 set INTERVAL_SEC=%INTERVAL_QUIET%

REM --- Cleanup stale local branches across all repos ---
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Zeitgeist Evolved"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\SDL_VisualTest"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Super Civ 16"
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\TerrorForm"

REM --- Rebuild combined steering docs from all repos ---
echo [%date% %time%] Rebuilding CLI steering context...
call "%WORK_DIR%\build-cli-steering.bat"
echo.

echo [%date% %time%] Checking for open issues (interval: %INTERVAL_SEC%s)...
echo.

REM Delete marker file before running
if exist "%MARKER_FILE%" del "%MARKER_FILE%"

REM Run Kiro CLI with instruction to read the combined steering file first.
kiro-cli chat --no-interactive --trust-all-tools "FIRST: Read the file c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme\cli-steering-combined.md — it contains all project steering docs (issue workflow, visual testing pipeline, SDL/picojson library context, game design docs). Follow ALL instructions in that file as your operational guide. THEN: Check all monitored GitHub repos for open issues. Run: gh issue list --repo danielsawitzki77/Zeitgeist-Evolved --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/SDL_VisualTest --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Super-Civ-16 --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/TerrorForm --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Game-Dev-Supreme --state open --json number,title,labels,assignees,createdAt. Pick the highest-priority open issue (excluding any with the Draft label) and work on it following the full workflow from the steering docs. If no actionable issues are found, just report that and stop. SIGNAL: If you found no actionable work, write the word NO_WORK to the file: %MARKER_FILE%"

echo.
echo [%date% %time%] Cycle complete.

REM Check if Kiro found no work — if marker exists, wait; otherwise re-run immediately
if exist "%MARKER_FILE%" (
    echo ============================================================
    echo  Kiro Issue Worker - Adaptive Polling
    echo  Active hours ^(8am-10pm PST^): every %INTERVAL_ACTIVE%s
    echo  Quiet hours ^(10pm-8am PST^):  every %INTERVAL_QUIET%s
    echo  During countdown: C=check now, P=pause polling
    echo  While paused: any key resumes + triggers immediate check
    echo  Working directory: %WORK_DIR%
    echo  Press Ctrl+C to stop
    echo ============================================================
    echo.
    echo No actionable issues found. Waiting %INTERVAL_SEC% seconds...
    echo Press C to check immediately, or P to pause.
    echo.
    call :wait_with_pause %INTERVAL_SEC%
) else (
    echo Work was processed! Re-checking immediately for more issues...
    echo.
)

REM Check if we entered paused state
if "%PAUSED%"=="1" goto :paused
goto loop

:paused
echo.
echo ============================================================
echo  *** PAUSED *** Polling is suspended.
echo  Press any key to resume and trigger an immediate check...
echo ============================================================
echo.
pause >nul
set "PAUSED=0"
echo [%date% %time%] Resumed! Triggering immediate check...
echo.
goto loop

REM ============================================================
REM Subroutine: wait_with_pause
REM Waits for the specified number of seconds using 5-second
REM intervals with choice /T. If the user presses P, sets
REM PAUSED=1 and returns. If C is pressed, returns immediately
REM to trigger the next check. If the timeout elapses fully,
REM returns normally.
REM
REM Usage: call :wait_with_pause <seconds>
REM ============================================================
:wait_with_pause
set /a "WAIT_REMAINING=%~1"
:wait_loop
if %WAIT_REMAINING% LEQ 0 goto :eof
echo    [%WAIT_REMAINING%s remaining] P=pause, C=check now
choice /C PCN /N /T 5 /D N >nul 2>&1
if %errorlevel%==1 (
    REM P was pressed — enter pause mode
    set "PAUSED=1"
    goto :eof
)
if %errorlevel%==2 (
    REM C was pressed — user wants immediate check
    goto :eof
)
REM N was selected (timeout elapsed) — decrement and continue
set /a "WAIT_REMAINING=WAIT_REMAINING - 5"
goto :wait_loop

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
