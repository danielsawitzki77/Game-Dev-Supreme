@echo off
REM ============================================================================
REM update_vendor.bat — Centralized vendor updater (Game-Dev-Supreme)
REM
REM Call this from any game project directory:
REM   ..\Game-Dev-Supreme\update_vendor.bat
REM
REM It auto-detects the calling directory and updates its vendor\ folder
REM from sibling source repos (SDL, SDL_image, picojson, stb).
REM Each copy has its .git directory removed so the vendor folder can be
REM committed directly without nested-repo warnings.
REM
REM Source repos expected as siblings of the calling directory:
REM   ..\SDL
REM   ..\SDL_image
REM   ..\picojson
REM   ..\stb
REM ============================================================================

setlocal enabledelayedexpansion

REM Use the caller's working directory (not the script's location)
set "PROJECT_DIR=%CD%"
set "VENDOR_DIR=%PROJECT_DIR%\vendor"
set "PARENT_DIR=%PROJECT_DIR%\.."

echo.
echo === Updating vendor dependencies ===
echo    Project: %PROJECT_DIR%
echo.

REM --- SDL ---
echo [1/4] Updating SDL...
if not exist "%PARENT_DIR%\SDL" (
    echo ERROR: Source repo not found at %PARENT_DIR%\SDL
    goto :error
)
if exist "%VENDOR_DIR%\SDL" (
    echo       Removing old copy...
    rmdir /s /q "%VENDOR_DIR%\SDL"
)
echo       Copying from %PARENT_DIR%\SDL ...
xcopy "%PARENT_DIR%\SDL" "%VENDOR_DIR%\SDL\" /E /I /Q /H /Y >nul
if errorlevel 1 goto :error
if exist "%VENDOR_DIR%\SDL\.git" rmdir /s /q "%VENDOR_DIR%\SDL\.git"
echo       Done.

REM --- SDL_image ---
echo [2/4] Updating SDL_image...
if not exist "%PARENT_DIR%\SDL_image" (
    echo ERROR: Source repo not found at %PARENT_DIR%\SDL_image
    goto :error
)
if exist "%VENDOR_DIR%\SDL_image" (
    echo       Removing old copy...
    rmdir /s /q "%VENDOR_DIR%\SDL_image"
)
echo       Copying from %PARENT_DIR%\SDL_image ...
xcopy "%PARENT_DIR%\SDL_image" "%VENDOR_DIR%\SDL_image\" /E /I /Q /H /Y >nul
if errorlevel 1 goto :error
if exist "%VENDOR_DIR%\SDL_image\.git" rmdir /s /q "%VENDOR_DIR%\SDL_image\.git"
echo       Done.

REM --- picojson ---
echo [3/4] Updating picojson...
if not exist "%PARENT_DIR%\picojson" (
    echo ERROR: Source repo not found at %PARENT_DIR%\picojson
    goto :error
)
if exist "%VENDOR_DIR%\picojson" (
    echo       Removing old copy...
    rmdir /s /q "%VENDOR_DIR%\picojson"
)
echo       Copying from %PARENT_DIR%\picojson ...
xcopy "%PARENT_DIR%\picojson" "%VENDOR_DIR%\picojson\" /E /I /Q /H /Y >nul
if errorlevel 1 goto :error
if exist "%VENDOR_DIR%\picojson\.git" rmdir /s /q "%VENDOR_DIR%\picojson\.git"
echo       Done.

REM --- stb ---
echo [4/4] Updating stb...
if not exist "%PARENT_DIR%\stb" (
    echo ERROR: Source repo not found at %PARENT_DIR%\stb
    goto :error
)
if exist "%VENDOR_DIR%\stb" (
    echo       Removing old copy...
    rmdir /s /q "%VENDOR_DIR%\stb"
)
echo       Copying from %PARENT_DIR%\stb ...
xcopy "%PARENT_DIR%\stb" "%VENDOR_DIR%\stb\" /E /I /Q /H /Y >nul
if errorlevel 1 goto :error
if exist "%VENDOR_DIR%\stb\.git" rmdir /s /q "%VENDOR_DIR%\stb\.git"
echo       Done.

echo.
echo === All vendor dependencies updated successfully ===
echo.
goto :end

:error
echo.
echo === ERROR: Vendor update failed ===
echo.
exit /b 1

:end
endlocal
