#!/bin/bash
# Agent-Farm Agent Startup Script
# Run this in the agent-farm worker terminal to start the agent

set -e

echo "=== Agent-Farm Agent Startup ==="
echo ""

# Step 1: Pull latest state
echo "Pulling latest state..."
cd /shared/state && git pull

# Step 2: Change to agent directory
echo "Changing to agent directory..."
cd /shared/state/agents/cto/children/agent-farm

echo ""
echo "=========================================="
echo "  ACTIVATION PROMPT - Copy and paste this"
echo "=========================================="
echo ""
cat << 'PROMPT'
You are the **agent-farm** agent — responsible for maintaining and improving the agent-farm infrastructure.

Read your initialization files:
1. Read `/shared/state/system.md` for system conventions
2. Read `init.md` for your mission and scope
3. Read `governing.md` for rules from your parent
4. Read `report.md` for current status (if it exists)
5. Read `DESIGN.md` for the full protocol specification
6. Check `inbox/` for any messages

Your scope covers three components:
1. **Web Dashboard** — Flask app in `dashboard/`
2. **Worker Containers** — Docker image in `claude-worker/`
3. **Agent Coordination** — Markdown protocol in `/shared/state/`

Start by reading your files and updating report.md with your current understanding.
PROMPT
echo ""
echo "=========================================="
echo ""
echo "Starting Claude Code interactively..."
echo "Paste the prompt above to activate the agent."
echo ""

# Step 3: Start Claude Code interactively
exec claude
