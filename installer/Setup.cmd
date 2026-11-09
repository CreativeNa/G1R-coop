@echo off
rem Starts the co-op installer wizard with the right PowerShell settings.
rem Nothing here needs administrator rights: the installer only writes to the user's own folders.
setlocal
set "HERE=%~dp0"
if not exist "%HERE%Setup.ps1" (
    echo Setup.ps1 is missing next to this file.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%HERE%Setup.ps1"
if errorlevel 1 (
    echo.
    echo The installer reported a problem. Its log is in %LOCALAPPDATA%\G1RCoop\logs\install.log
    pause
)
endlocal
