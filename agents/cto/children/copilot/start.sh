#!/bin/bash
# Copilot Agent Startup Script
# Run this in the copilot worker terminal to start the agent

set -e

echo "=== Copilot Agent Startup ==="
echo ""

# Step 1: Pull latest state
echo "Pulling latest state..."
cd /shared/state && git pull

# Step 2: Clone/update repos
echo "Setting up repositories..."
mkdir -p ~/repos && cd ~/repos
if [ -d "nuget" ]; then
    echo "  nuget: pulling latest..."
    cd nuget && git pull && cd ..
else
    echo "  nuget: cloning..."
    git clone git@bitbucket.org:xynon/nq-nugetlibraries.git nuget
fi
if [ -d "portal" ]; then
    echo "  portal: pulling latest..."
    cd portal && git pull && cd ..
else
    echo "  portal: cloning..."
    git clone git@bitbucket.org:xynon/portal.git portal
fi

# Step 3: Change to agent directory
echo "Changing to agent directory..."
cd /shared/state/agents/cto/children/copilot

echo ""
echo "=========================================="
echo "  ACTIVATION PROMPT - Copy and paste this"
echo "=========================================="
echo ""
cat << 'PROMPT'
You are the **copilot** agent — implementing the Trading Copilot for NQ/Xynon.

Read your initialization files:
1. Read `/shared/state/system.md` for system conventions
2. Read `init.md` for your mission and scope
3. Read `governing.md` for rules from your parent
4. Read `report.md` for current status and uncommitted changes
5. Read `design.md` for architecture decisions
6. Check `inbox/` for any messages

Your repos are at ~/repos/nuget (NQ.Copilot) and ~/repos/portal (UI/API).

Start by reading your files, checking for uncommitted work, and updating report.md.
PROMPT
echo ""
echo "=========================================="
echo ""
echo "Starting Claude Code interactively..."
echo "Paste the prompt above to activate the agent."
echo ""

# Step 4: Start Claude Code interactively
exec claude
