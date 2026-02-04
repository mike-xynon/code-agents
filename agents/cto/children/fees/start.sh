#\!/bin/bash
# Fees Agent Startup Script

AGENT_DIR="/shared/state/agents/cto/children/fees"

# Change to agent directory
cd "$AGENT_DIR" || exit 1

# Pull latest shared state
echo "Pulling latest shared state..."
cd /shared/state && git pull
cd "$AGENT_DIR"

# Clone required repos if not present
echo "Setting up repositories..."
mkdir -p ~/repos

if [ \! -d ~/repos/registry/.git ]; then
    echo "Cloning registry repo..."
    git clone git@bitbucket.org:xynon/nq.trading.git ~/repos/registry
else
    echo "Registry repo exists, pulling..."
    cd ~/repos/registry && git pull
fi

if [ \! -d ~/repos/oms/.git ]; then
    echo "Cloning oms repo..."
    git clone git@bitbucket.org:xynon/nq.morrison.git ~/repos/oms
else
    echo "OMS repo exists, pulling..."
    cd ~/repos/oms && git pull
fi

if [ \! -d ~/repos/nuget/.git ]; then
    echo "Cloning nuget repo..."
    git clone git@bitbucket.org:xynon/nq-nugetlibraries.git ~/repos/nuget
else
    echo "Nuget repo exists, pulling..."
    cd ~/repos/nuget && git pull
fi

if [ \! -d ~/repos/reporting/.git ]; then
    echo "Cloning reporting repo..."
    git clone git@bitbucket.org:xynon/nq.reporting.git ~/repos/reporting
else
    echo "Reporting repo exists, pulling..."
    cd ~/repos/reporting && git pull
fi

# Return to agent directory and start claude
cd "$AGENT_DIR"
echo ""
echo "Ready\! Starting Claude..."
echo ""
exec claude
