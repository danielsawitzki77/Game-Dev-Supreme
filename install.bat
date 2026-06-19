@echo off
REM Installs Kiro global steering doc from Game-Dev-Supreme (the central workspace hub).
REM Run this once from any terminal.

set KIRO_HOME=%USERPROFILE%\.kiro

echo Installing global steering doc...
if not exist "%KIRO_HOME%\steering" mkdir "%KIRO_HOME%\steering"
copy /Y "%~dp0.kiro\steering\github-issue-workflow.md" "%KIRO_HOME%\steering\github-issue-workflow.md"

echo.
echo Done! Restart Kiro for changes to take effect.
echo Run check-issues-loop.bat for headless polling.
