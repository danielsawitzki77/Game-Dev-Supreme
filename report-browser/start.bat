@echo off
cd /d "%~dp0"
echo Starting Test Report Browser at http://localhost:8090
echo Press Ctrl+C to stop.
echo.
start http://localhost:8090
python server.py %*
