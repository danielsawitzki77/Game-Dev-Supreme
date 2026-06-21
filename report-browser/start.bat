@echo off
cd /d "%~dp0"
echo Starting Test Report Browser at http://localhost:8090/game-dev-supreme/testing/reports
echo Press Ctrl+C or use the Quit button in the browser to stop.
echo.
start http://localhost:8090/game-dev-supreme/testing/reports
python server.py %*
