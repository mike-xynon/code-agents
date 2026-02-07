#!/bin/bash
# Morrison Ops Agent - Startup Script
#
# Run this script inside the morrison-ops worker container to start the agent.
# Prerequisites: Worker container must be running (create via dashboard or API)

set -e

STATE_REPO="/shared/state"
AGENT_PATH="$STATE_REPO/agents/cto/children/morrison-ops"

echo "========================================"
echo "  Morrison Ops Agent - Startup"
echo "========================================"
echo ""

# Pull latest state files
echo "Pulling latest state files..."
cd "$STATE_REPO"
git pull || echo "Warning: Could not pull state repo (check SSH keys for GitHub)"
echo ""

# Change to agent directory
cd "$AGENT_PATH"

echo "Agent directory: $AGENT_PATH"
echo ""
echo "Agent files:"
ls -la
echo ""

# Create inbox if it doesn't exist
mkdir -p inbox

# Show the activation prompt
echo "========================================"
echo "  ACTIVATION PROMPT"
echo "========================================"
echo ""
echo "Start Claude Code with: claude"
echo ""
echo "Then paste this prompt:"
echo ""
echo "----------------------------------------"
cat << 'EOF'
You are the **morrison-ops** agent - a business process improvement agent for Morrison Securities.

Read your agent files:
1. Read `/shared/state/system.md` — System conventions
2. Read `init.md` — Your mission and workstreams
3. Read `governing.md` — Operating rules
4. Read `report.md` — Current status
5. Read `design.md` — Captured analysis and proposals
6. Check `inbox/` — Pending messages

Your role is communication and design focused:
- Identify problems through stakeholder input
- Document findings
- Propose costed, predictable solutions
- No code changes (hand off to technical agents)

Current workstreams:
1. **Onboarding** — AML/KYC friction (awaiting SJ input)
2. **CMM Visibility** — Surfacing margin limits to large clients

Start by reading your files, then update report.md with your session start.
EOF
echo "----------------------------------------"
echo ""
echo "Ready. Run 'claude' to start."
