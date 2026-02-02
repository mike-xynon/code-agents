@echo off
REM Bootstrap script to create workers for all configured repositories
REM Runs bootstrap.sh via Git Bash

setlocal

set SCRIPT_DIR=%~dp0
set API_URL=http://localhost:8080

echo === Claude Worker Farm Bootstrap ===
echo.

REM Check if Git Bash is available
where bash >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Git Bash not found. Please install Git for Windows.
    exit /b 1
)

REM Run the bash script
bash "%SCRIPT_DIR%bootstrap.sh"

endlocal
