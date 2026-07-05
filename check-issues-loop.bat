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
REM     C = force an immediate check (unlimited items)
REM     P = PAUSE polling (suspends all activity)
REM     Q = quit gracefully
REM     1-9 = set max items for THIS cycle, then pause for confirmation
REM   While paused (after number selection or P):
REM     C = check now (unlimited)
REM     Q = quit gracefully
REM     1-9 = set max count for this cycle and check
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
REM ============================================================

set KIRO_API_KEY=ksk_ZNG5mUlKiZW1Wn8dDdOkpNcJ8dWBsYD9
set WORK_DIR=c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme
set INTERVAL_ACTIVE=600
set INTERVAL_QUIET=1800
set TAG_USER=danielsawitzki77-remote
set "MARKER_FILE=%TEMP%\kiro_no_work.tmp"

REM MAX_ITEMS is set per-cycle. 0 = unlimited (default each cycle)
set "MAX_ITEMS=0"

REM Compute short display path: .../github/... with forward slashes
set "GITHUB_ROOT=c:\Users\Daniel Sawitzki\Desktop\github"
call :make_display_path "%WORK_DIR%"

call :print_banner
echo.

cd /d "%WORK_DIR%"

REM Initialize state
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
call :cleanup_branches "c:\Users\Daniel Sawitzki\Desktop\github\Particluar"

REM --- Rebuild combined steering docs from all repos ---
echo [%date% %time%] Rebuilding CLI steering context...
call "%WORK_DIR%\build-cli-steering.bat"
echo.

REM Build the pickup instruction based on MAX_ITEMS
if "%MAX_ITEMS%"=="0" (
    set "PICKUP_INSTRUCTION=Pick up ALL highest-priority open issues (excluding any with the Draft label) and work on them following the full workflow from the steering docs. Process them sequentially, one at a time."
    set "MAX_DISPLAY=unlimited"
) else (
    set "PICKUP_INSTRUCTION=Pick up to %MAX_ITEMS% highest-priority open issues (excluding any with the Draft label) and work on them following the full workflow from the steering docs. Process them sequentially, one at a time."
    set "MAX_DISPLAY=%MAX_ITEMS%"
)

echo [%date% %time%] Checking for open issues (interval: %INTERVAL_SEC%s, max items: %MAX_DISPLAY%)...
echo.

REM Delete marker file before running
if exist "%MARKER_FILE%" del "%MARKER_FILE%"

REM Run Kiro CLI with instruction to read the combined steering file first.
kiro-cli chat --no-interactive --trust-all-tools "FIRST: Read the file c:\Users\Daniel Sawitzki\Desktop\github\Game-Dev-Supreme\cli-steering-combined.md — it contains all project steering docs (issue workflow, visual testing pipeline, SDL/picojson library context, game design docs). Follow ALL instructions in that file as your operational guide. THEN: Check all monitored GitHub repos for open issues. Run: gh issue list --repo danielsawitzki77/Zeitgeist-Evolved --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/SDL_VisualTest --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Super-Civ-16 --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/TerrorForm --state open --json number,title,labels,assignees,createdAt, then gh issue list --repo danielsawitzki77/Game-Dev-Supreme --state open --json number,title,labels,assignees,createdAt. %PICKUP_INSTRUCTION% If no actionable issues are found, just report that and stop. SIGNAL: If you found no actionable work, write the word NO_WORK to the file: %MARKER_FILE%"

echo.
echo [%date% %time%] Cycle complete.

REM Reset max items after use — next cycle defaults to unlimited unless user picks again
set "MAX_ITEMS=0"
set "DO_QUIT=0"
set "PAUSED=0"

REM Check if Kiro found no work — if marker exists, wait; otherwise re-run immediately
if exist "%MARKER_FILE%" (
    call :print_banner
    echo.
    echo No actionable issues found. Waiting %INTERVAL_SEC% seconds...
    echo Press C=check now, P=pause, Q=quit, 1-9=set max items ^(pauses^).
    echo.
    call :wait_with_input %INTERVAL_SEC%
) else (
    echo Work was processed! Re-checking immediately for more issues...
    echo.
)

REM Check exit/pause flags
if "%DO_QUIT%"=="1" goto :quit
if "%PAUSED%"=="1" goto :paused
goto loop

:paused
echo.
echo ============================================================
echo  *** PAUSED ***  Polling is suspended.
echo  C = check now ^(unlimited^)    Q = quit
echo  1-9 = set max items and check
echo ============================================================
echo.
call :pause_choice
if "%DO_QUIT%"=="1" goto :quit
echo [%date% %time%] Resumed! Triggering check (max items: %MAX_ITEMS%)...
echo.
goto loop

:quit
echo.
echo ============================================================
echo  Kiro Issue Worker shutting down gracefully.
echo  [%date% %time%]  Goodbye!
echo ============================================================
echo.
exit /b 0

REM ============================================================
REM Subroutine: print_banner
REM ============================================================
:print_banner
echo ============================================================
echo  Kiro Issue Worker - Adaptive Polling
echo  Active hours ^(8am-10pm PST^): every %INTERVAL_ACTIVE%s
echo  Quiet hours ^(10pm-8am PST^):  every %INTERVAL_QUIET%s
echo  Controls: C=check, P=pause, Q=quit, 1-9=max items ^(pauses^)
echo  Working directory: %DISPLAY_PATH%
echo ============================================================
goto :eof

REM ============================================================
REM Subroutine: wait_with_input
REM Waits for the specified number of seconds using 5-second
REM intervals with choice /T. Supports:
REM   P = pause, C = check now (unlimited), Q = quit,
REM   1-9 = set max items then enter pause for confirmation.
REM
REM Sets: PAUSED, DO_QUIT, MAX_ITEMS as appropriate.
REM Usage: call :wait_with_input <seconds>
REM ============================================================
:wait_with_input
set "DO_QUIT=0"
set "PAUSED=0"
set /a "WAIT_REMAINING=%~1"
:wait_loop
if %WAIT_REMAINING% LEQ 0 (
    echo.
    goto :eof
)
powershell -NoProfile -Command "Write-Host -NoNewline \"`r   [%WAIT_REMAINING%s remaining] C=check P=pause Q=quit 1-9=max   `r\""
choice /C PCQN123456789 /N /T 5 /D N >nul 2>&1
if %errorlevel%==1 (
    REM P — pause
    echo.
    set "PAUSED=1"
    goto :eof
)
if %errorlevel%==2 (
    REM C — immediate check, unlimited
    echo.
    set "MAX_ITEMS=0"
    goto :eof
)
if %errorlevel%==3 (
    REM Q — quit
    echo.
    set "DO_QUIT=1"
    goto :eof
)
if %errorlevel%==4 (
    REM N — timeout elapsed
    set /a "WAIT_REMAINING=WAIT_REMAINING - 5"
    goto :wait_loop
)
REM errorlevel 5-13 = keys 1-9
set /a "NUM_PRESSED=%errorlevel% - 4"
set "MAX_ITEMS=%NUM_PRESSED%"
echo.
echo  Selected max items: %MAX_ITEMS% — pausing for confirmation...
set "PAUSED=1"
goto :eof

REM ============================================================
REM Subroutine: pause_choice
REM After entering pause (either via P or after number selection),
REM the user picks: C = unlimited check, Q = quit, 1-9 = set max.
REM Blocks until a valid key is pressed.
REM
REM Sets: DO_QUIT, MAX_ITEMS, PAUSED
REM ============================================================
:pause_choice
:pause_choice_loop
choice /C CQ123456789 /N /M "  > "
if %errorlevel%==1 (
    REM C — unlimited
    set "MAX_ITEMS=0"
    set "PAUSED=0"
    goto :eof
)
if %errorlevel%==2 (
    REM Q — quit
    set "DO_QUIT=1"
    set "PAUSED=0"
    goto :eof
)
REM errorlevel 3-11 = keys 1-9
set /a "NUM_PRESSED=%errorlevel% - 2"
set "MAX_ITEMS=%NUM_PRESSED%"
set "PAUSED=0"
echo  Max items set to: %MAX_ITEMS%
goto :eof

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
call set "CB_REL=%%REPO_PATH:*\github\=%%"
set "CB_DISPLAY=.../github/%CB_REL:\=/%"
echo [Cleanup] %CB_DISPLAY%

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

REM ============================================================
REM Subroutine: make_display_path
REM Converts an absolute path to a short display path starting
REM at .../github/... with forward slashes.
REM Sets DISPLAY_PATH variable.
REM
REM Usage: call :make_display_path "c:\Users\...\github\MyRepo"
REM ============================================================
:make_display_path
set "FULL_PATH=%~1"
REM Extract the portion after the github root
call set "REL_PART=%%FULL_PATH:*\github\=%%"
REM Build display path with forward slashes
set "DISPLAY_PATH=.../github/%REL_PART:\=/%"
goto :eof
