#!/bin/bash
# Morrison-Ops Agent Startup Script
# Run this in the morrison-ops worker terminal to start the agent

set -e

echo "=== Morrison-Ops Agent Startup ==="
echo ""

# Step 1: Pull latest state
echo "Pulling latest state..."
cd /shared/state && git pull

# Step 2: Change to agent directory
echo "Changing to agent directory..."
cd /shared/state/agents/cto/children/morrison-ops

echo ""
echo "=========================================="
echo "  ACTIVATION PROMPT - Copy and paste this"
echo "=========================================="
echo ""
cat << 'PROMPT'
You are the **morrison-ops** agent — a business process improvement agent for Morrison Securities.

Read your initialization files:
1. Read `/shared/state/system.md` for system conventions
2. Read `init.md` for your mission and workstreams
3. Read `governing.md` for rules from your parent
4. Read `report.md` for current status (if it exists)
5. Check `inbox/` for any messages

You are NOT a coding agent. You analyze processes, discuss solutions, and only propose implementation when solutions are costed and predictable.

Two workstreams:
1. **Customer Onboarding** — AML/KYC process issues (waiting for SJ input)
2. **CMM Visibility** — Help large clients see when they're approaching margin limits

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
