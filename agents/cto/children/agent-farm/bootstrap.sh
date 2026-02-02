#!/bin/bash
# Bootstrap script to create workers for all configured repositories
# Reads from repos.json and creates a worker for each

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS_FILE="${SCRIPT_DIR}/repos.json"
API_URL="${API_URL:-http://localhost:8080}"

echo "=== Claude Worker Farm Bootstrap ==="
echo "API: ${API_URL}"
echo ""

# Check if repos.json exists
if [ ! -f "${REPOS_FILE}" ]; then
    echo "Error: repos.json not found at ${REPOS_FILE}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    echo "Install with: apt-get install jq (Linux) or brew install jq (Mac)"
    exit 1
fi

# Check if API is reachable
if ! curl -s "${API_URL}/health" > /dev/null 2>&1; then
    echo "Error: Cannot reach API at ${API_URL}"
    echo "Make sure docker-compose is running: docker-compose up -d"
    exit 1
fi

echo "Reading repositories from repos.json..."
echo ""

# Get current workers
EXISTING=$(curl -s "${API_URL}/api/workers" | jq -r '.[].name')

# Read repos and create workers
jq -c '.repositories[]' "${REPOS_FILE}" | while read -r repo; do
    name=$(echo "$repo" | jq -r '.name')
    display_name=$(echo "$repo" | jq -r '.display_name')
    git_url=$(echo "$repo" | jq -r '.git_url')
    description=$(echo "$repo" | jq -r '.description')

    # Check if worker already exists
    if echo "${EXISTING}" | grep -q "^${name}$"; then
        echo "[SKIP] ${name} - worker already exists"
        continue
    fi

    echo "[CREATE] ${name} (${display_name})"
    echo "         Repo: ${git_url}"

    result=$(curl -s -X POST "${API_URL}/api/workers" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${name}\", \"git_repo\": \"${git_url}\"}")

    status=$(echo "$result" | jq -r '.status // .error // "created"')
    echo "         Status: ${status}"
    echo ""

    # Small delay between creations
    sleep 2
done

echo "=== Bootstrap Complete ==="
echo ""
echo "Workers:"
curl -s "${API_URL}/api/workers" | jq -r '.[] | "  - \(.name): \(.status)"'
echo ""
echo "Dashboard: ${API_URL}"
