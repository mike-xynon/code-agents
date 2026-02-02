#!/bin/bash
# Claude Worker Farm - Quick Start Script

set -e

echo "========================================"
echo "  Claude Worker Farm - Quick Start"
echo "========================================"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env from template..."
    cp .env.example .env
    echo ""
    echo "IMPORTANT: Please edit .env and add your ANTHROPIC_API_KEY"
    echo "Then run this script again."
    exit 1
fi

# Check if ANTHROPIC_API_KEY is set
source .env
if [ -z "$ANTHROPIC_API_KEY" ] || [ "$ANTHROPIC_API_KEY" = "your-api-key-here" ]; then
    echo "WARNING: ANTHROPIC_API_KEY is not set in .env"
    echo "Claude Code will not work without it."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build the worker image
echo ""
echo "Building claude-worker image..."
docker build -t claude-worker:latest ./claude-worker

# Create network if it doesn't exist
echo ""
echo "Creating Docker network..."
docker network create claude-farm-network 2>/dev/null || true

# Build and start services
echo ""
echo "Starting services with docker-compose..."
docker-compose up -d --build

# Wait for services to be ready
echo ""
echo "Waiting for services to start..."
sleep 5

# Check if dashboard is responding
echo ""
echo "Checking dashboard health..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "Dashboard is ready!"
        break
    fi
    echo "Waiting for dashboard... ($i/30)"
    sleep 2
done

# Show status
echo ""
echo "========================================"
echo "  Claude Worker Farm is running!"
echo "========================================"
echo ""
echo "Dashboard URL: http://localhost:8080"
echo ""
echo "To view logs:     docker-compose logs -f"
echo "To stop:          docker-compose down"
echo "To restart:       docker-compose restart"
echo ""
echo "Quick commands:"
echo "  Create worker:  curl -X POST http://localhost:8080/api/workers -H 'Content-Type: application/json' -d '{\"name\": \"My Worker\"}'"
echo "  List workers:   curl http://localhost:8080/api/workers"
echo ""

# Open browser on macOS/Linux
if command -v open &> /dev/null; then
    open http://localhost:8080
elif command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:8080
fi
