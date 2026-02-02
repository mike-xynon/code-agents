@echo off
REM Claude Worker Farm - Quick Start Script for Windows

echo ========================================
echo   Claude Worker Farm - Quick Start
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running. Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Check if .env exists
if not exist .env (
    echo Creating .env from template...
    copy .env.example .env
    echo.
    echo IMPORTANT: Please edit .env and add your ANTHROPIC_API_KEY
    echo Then run this script again.
    pause
    exit /b 1
)

REM Build the worker image
echo.
echo Building claude-worker image...
docker build -t claude-worker:latest ./claude-worker

REM Create network if it doesn't exist
echo.
echo Creating Docker network...
docker network create claude-farm-network 2>nul

REM Build and start services
echo.
echo Starting services with docker-compose...
docker-compose up -d --build

REM Wait for services to be ready
echo.
echo Waiting for services to start...
timeout /t 5 /nobreak >nul

REM Show status
echo.
echo ========================================
echo   Claude Worker Farm is running!
echo ========================================
echo.
echo Dashboard URL: http://localhost:8080
echo.
echo To view logs:     docker-compose logs -f
echo To stop:          docker-compose down
echo To restart:       docker-compose restart
echo.

REM Open browser
start http://localhost:8080

pause
