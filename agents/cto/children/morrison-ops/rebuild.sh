#!/bin/bash
# Rebuild morrison-ops worker with updated SSH config
# Run this on the HOST machine (not inside a container)

set -e

AGENT_FARM_DIR="${AGENT_FARM_DIR:-/path/to/agent-farm}"

echo "========================================"
echo "  Rebuilding morrison-ops worker"
echo "========================================"
echo ""

# Check if we're on the host
if [ -f "/.dockerenv" ]; then
    echo "ERROR: This script must be run on the host machine, not inside a container."
    exit 1
fi

# Rebuild worker image
echo "Rebuilding claude-worker image..."
cd "$AGENT_FARM_DIR"
docker build -t claude-worker:latest ./claude-worker

# Delete existing morrison-ops container
echo ""
echo "Removing old morrison-ops container..."
curl -s -X DELETE http://localhost:8080/api/workers/morrison-ops || true

# Wait a moment
sleep 2

# Create new morrison-ops container
echo ""
echo "Creating new morrison-ops container..."
curl -s -X POST http://localhost:8080/api/workers \
  -H "Content-Type: application/json" \
  -d '{"name": "morrison-ops"}'

echo ""
echo "Done! morrison-ops is recreated with GitHub SSH support."
echo ""
echo "To start the agent:"
echo "  1. Connect via dashboard: http://localhost:8080"
echo "  2. Run: /shared/state/agents/cto/children/morrison-ops/start.sh"
