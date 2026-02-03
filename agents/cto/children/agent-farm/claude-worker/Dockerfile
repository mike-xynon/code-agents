# Claude Worker Container
# Provides isolated Claude Code environment with web terminal access

FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    tmux \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    jq \
    ca-certificates \
    gnupg \
    locales \
    sudo \
    p7zip-full \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

# Set up locale for proper terminal handling
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Node.js (required for claude-code)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 9 SDK (required for building NQ projects)
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-9.0 \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd for web terminal
RUN wget -O /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# Install Claude Code globally via npm
RUN npm install -g @anthropic-ai/claude-code

# Create shared directories
RUN mkdir -p /shared/repos /shared/state /shared/config /workspace

# Create non-root user with sudo access
RUN useradd -m -s /bin/bash claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R claude:claude /shared /workspace

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Copy custom ttyd index.html with scrollbar fix
COPY ttyd-index.html /ttyd-index.html

# Copy Claude Code settings (dark mode, etc.)
RUN mkdir -p /home/claude/.claude
COPY claude-settings.json /home/claude/.claude/settings.json
RUN chown -R claude:claude /home/claude/.claude

# Expose ttyd port
EXPOSE 7681

# Set working directory
WORKDIR /workspace

# Run as root initially to handle permissions, startup.sh will switch to claude user
USER root

# Environment variables (to be overridden at runtime)
ENV WORKER_ID=worker-default
ENV GIT_REPO_URL=""
ENV ANTHROPIC_API_KEY=""

# Start the worker
CMD ["/startup.sh"]
