#!/bin/bash
# Claude Worker Startup Script
# Initializes the worker environment, clones repos, starts tmux + ttyd

set -e

echo "=== Claude Worker Starting ==="
echo "Worker ID: ${WORKER_ID}"
echo "Worker Name: ${WORKER_NAME:-$WORKER_ID}"
echo "Git Repo: ${GIT_REPO_URL:-none}"

# Extract Claude config archive if available (pre-authenticated session with all settings)
if [ -f "/secrets/api/claude-config.tar.gz" ]; then
    echo "Extracting Claude config archive..."
    cd /home/claude
    tar xzf /secrets/api/claude-config.tar.gz
    chown -R claude:claude /home/claude/.claude /home/claude/.claude.json
    chmod 700 /home/claude/.claude
    chmod 600 /home/claude/.claude.json
    echo "Claude config extracted"
fi

# Use WORKER_NAME for directory (allows repo reuse across container restarts)
REPO_NAME="${WORKER_NAME:-$WORKER_ID}"

# Set up SSH keys FIRST if secrets are mounted (needed for git clone)
if [ -d "/secrets/ssh" ] && [ "$(ls -A /secrets/ssh 2>/dev/null)" ]; then
    echo "Setting up SSH keys..."
    mkdir -p /home/claude/.ssh
    chmod 700 /home/claude/.ssh

    # Copy all SSH keys
    cp /secrets/ssh/* /home/claude/.ssh/ 2>/dev/null || true

    # Set correct permissions on private keys
    find /home/claude/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
    find /home/claude/.ssh -type f -name "*.pub" -exec chmod 644 {} \;

    # Create SSH config for Bitbucket if key exists
    if [ -f "/home/claude/.ssh/id_rsa_bitbucket" ]; then
        cat > /home/claude/.ssh/config << 'SSHEOF'
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_rsa_bitbucket
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
SSHEOF
        chmod 600 /home/claude/.ssh/config
    fi

    chown -R claude:claude /home/claude/.ssh
    echo "SSH keys configured"
fi

# Configure git safe.directory to avoid ownership warnings with shared volumes
su - claude -c "git config --global --add safe.directory '*'"

# Set up workspace based on whether a git repo is specified
if [ -n "${GIT_REPO_URL}" ]; then
    # Git repo specified - clone to private home directory ~/repos/<name>
    REPOS_DIR="/home/claude/repos"
    mkdir -p "${REPOS_DIR}"
    chown -R claude:claude "${REPOS_DIR}"

    WORKER_DIR="${REPOS_DIR}/${REPO_NAME}"

    echo "Cloning repository: ${GIT_REPO_URL}"
    if [ ! -d "${WORKER_DIR}/.git" ]; then
        su - claude -c "git clone '${GIT_REPO_URL}' '${WORKER_DIR}' 2>&1" || {
            echo "Warning: Git clone failed, continuing anyway..."
        }
    else
        echo "Repository already exists, pulling latest..."
        su - claude -c "cd '${WORKER_DIR}' && git pull 2>&1" || {
            echo "Warning: Git pull failed, continuing anyway..."
        }
    fi
else
    # No git repo - use home directory as workspace
    WORKER_DIR="/home/claude"
    echo "No git repo specified, using home directory as workspace"
fi

# Symlink /workspace to the working directory for convenience
rm -rf /workspace 2>/dev/null || true
ln -sf "${WORKER_DIR}" /workspace
chown -h claude:claude /workspace

# Set workspace to worker directory
cd "${WORKER_DIR}"

# Ensure proper ownership of shared state (for agent coordination)
chown -R claude:claude /shared/state 2>/dev/null || true
chown -R claude:claude /workspace

# Create tmux configuration for better terminal experience
cat > /home/claude/.tmux.conf << 'EOF'
# Enable mouse mode for scrollback (hold Shift to select text for copy)
set -g mouse on

# Set larger scrollback buffer
set -g history-limit 50000

# Override wheel behavior: always scroll tmux history, never pass to application
# This prevents Claude Code from capturing wheel for input history cycling
bind-key -T root WheelUpPane copy-mode -e \; send-keys -M
bind-key -T root WheelDownPane send-keys -M

# Set terminal color
set -g default-terminal "screen-256color"

# Status bar
set -g status-bg colour235
set -g status-fg colour136
set -g status-left '#[fg=green]#S '
set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1
EOF
chown claude:claude /home/claude/.tmux.conf

# Create a shell profile with helpful aliases
cat > /home/claude/.bashrc << EOF
# Claude Worker Environment
export PS1='\[\033[01;32m\]\u@${REPO_NAME}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export WORKER_NAME="${REPO_NAME}"

# Terminal settings for Claude Code compatibility
export TERM=xterm-256color
export COLORTERM=truecolor
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Helpful aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'

# Claude Code alias
alias cc='claude'

# Load ANTHROPIC_API_KEY from secrets file
if [ -f "/secrets/api/anthropic_key" ]; then
    export ANTHROPIC_API_KEY="\$(cat /secrets/api/anthropic_key | tr -d '\n\r')"
fi

# Welcome message
echo ""
echo "==================================="
echo "  Claude Worker: ${REPO_NAME}"
echo "==================================="
echo ""
echo "Workspace: \$(pwd)"
echo "Claude Code: \$(claude --version 2>/dev/null || echo 'not found')"
echo ".NET SDK: \$(dotnet --version 2>/dev/null || echo 'not found')"
echo ""
echo "Quick commands:"
echo "  claude        - Start Claude Code"
echo "  dotnet build  - Build .NET project"
echo "  gs            - Git status"
echo "  ll            - List files"
echo ""
EOF
chown claude:claude /home/claude/.bashrc

# Kill any existing tmux session with this name
su - claude -c "tmux kill-session -t ${WORKER_ID} 2>/dev/null || true"

# Start tmux session as claude user
echo "Starting tmux session: ${WORKER_ID}"
su - claude -c "cd '${WORKER_DIR}' && ANTHROPIC_API_KEY='${ANTHROPIC_API_KEY}' tmux new-session -d -s '${WORKER_ID}' -x 300 -y 50"

# Set environment in tmux session
su - claude -c "tmux set-environment -t '${WORKER_ID}' ANTHROPIC_API_KEY '${ANTHROPIC_API_KEY}'"

# Give tmux a moment to start
sleep 1

# Start ttyd attached to the tmux session
# -W: Allow write from clients
# -p: Port
# Terminal options for better cursor visibility
echo "Starting ttyd on port 7681..."
exec ttyd \
    --port 7681 \
    --writable \
    --max-clients 10 \
    --ping-interval 30 \
    -t cursorStyle=block \
    -t cursorBlink=true \
    -t fontSize=13 \
    -t scrollback=50000 \
    -t scrollSensitivity=3 \
    -t 'theme={"background": "#1e1e1e", "foreground": "#d4d4d4", "cursor": "#ffffff", "cursorAccent": "#000000"}' \
    -t enableClipboard=true \
    su - claude -c "WORKER_ID='${WORKER_ID}' ANTHROPIC_API_KEY='${ANTHROPIC_API_KEY}' tmux attach-session -t '${WORKER_ID}'"
