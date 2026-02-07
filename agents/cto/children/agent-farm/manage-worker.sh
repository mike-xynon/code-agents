#!/bin/bash
# Claude Worker Farm - Worker Management Script
# Builds, creates, and configures worker containers
#
# Usage:
#   ./manage-worker.sh build                    # Build the Docker image only
#   ./manage-worker.sh create <worker-name>     # Create a new worker
#   ./manage-worker.sh rebuild <worker-name>    # Delete and recreate a worker
#   ./manage-worker.sh delete <worker-name>     # Delete a worker
#   ./manage-worker.sh status                   # Show all workers
#   ./manage-worker.sh logs <worker-name>       # Show worker logs

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:8080}"
IMAGE_NAME="claude-worker:latest"
STARTUP_WAIT_SECONDS=20

# Secrets paths (must match docker-compose.yml and .env)
SECRETS_BASE="${SECRETS_BASE:-C:/Users/Micha/AgentFarm/Secrets}"
SSH_SECRETS_PATH="${SECRETS_BASE}/ssh"
API_SECRETS_PATH="${SECRETS_BASE}/api"
AWS_SECRETS_PATH="${SECRETS_BASE}/aws"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    # Check Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi

    # Check claude-worker directory exists
    if [ ! -d "$SCRIPT_DIR/claude-worker" ]; then
        log_error "claude-worker directory not found at: $SCRIPT_DIR/claude-worker"
        exit 1
    fi

    # Check Dockerfile exists
    if [ ! -f "$SCRIPT_DIR/claude-worker/Dockerfile" ]; then
        log_error "Dockerfile not found at: $SCRIPT_DIR/claude-worker/Dockerfile"
        exit 1
    fi

    # Check startup.sh exists
    if [ ! -f "$SCRIPT_DIR/claude-worker/startup.sh" ]; then
        log_error "startup.sh not found at: $SCRIPT_DIR/claude-worker/startup.sh"
        exit 1
    fi

    # Check dashboard is reachable
    if ! curl -s "$DASHBOARD_URL/health" > /dev/null 2>&1; then
        log_error "Dashboard is not reachable at $DASHBOARD_URL"
        log_error "Make sure docker-compose is running: docker-compose up -d"
        exit 1
    fi

    # Check secrets directories exist
    log_info "Checking secrets paths..."

    # Convert Windows path if needed
    local ssh_path="${SSH_SECRETS_PATH}"
    local api_path="${API_SECRETS_PATH}"
    local aws_path="${AWS_SECRETS_PATH}"

    # Check SSH secrets
    if [ ! -d "$ssh_path" ]; then
        log_error "SSH secrets directory not found: $ssh_path"
        log_error "Expected: SSH key files (id_rsa_bitbucket, etc.)"
        exit 1
    fi

    # Check for SSH key
    if [ ! -f "$ssh_path/id_rsa_bitbucket" ]; then
        log_error "SSH key not found: $ssh_path/id_rsa_bitbucket"
        exit 1
    fi

    # Check API secrets
    if [ ! -d "$api_path" ]; then
        log_error "API secrets directory not found: $api_path"
        exit 1
    fi

    # Check for Claude config archive
    if [ ! -f "$api_path/claude-config.tar.gz" ]; then
        log_warn "Claude config archive not found: $api_path/claude-config.tar.gz"
        log_warn "Workers will start without pre-authenticated Claude session"
        log_warn ""
        log_warn "To create claude-config.tar.gz from your home directory:"
        log_warn "  cd ~"
        log_warn "  tar czf claude-config.tar.gz .claude.json .claude/"
        log_warn "  mv claude-config.tar.gz $api_path/"
        log_warn ""
    fi

    # Check for API key (can be in file or in claude-config.tar.gz)
    if [ ! -f "$api_path/anthropic_key" ]; then
        if [ -f "$api_path/claude-config.tar.gz" ]; then
            log_info "API key not in separate file, will use claude-config.tar.gz"
        else
            log_error "No API key found. Either:"
            log_error "  1. Create file: echo 'sk-ant-...' > $api_path/anthropic_key"
            log_error "  2. Or provide claude-config.tar.gz with authenticated session"
            exit 1
        fi
    fi

    # Check AWS secrets (optional but warn)
    if [ ! -d "$aws_path" ]; then
        log_warn "AWS secrets directory not found: $aws_path"
        log_warn "CodeArtifact login for NuGet packages will not work"
    fi

    log_info "Prerequisites OK"
}

# Fix line endings for shell scripts (Windows -> Unix)
fix_line_endings() {
    local file="$1"
    log_info "Fixing line endings for: $file"

    # Convert path for Docker volume mount (handle Git Bash/MSYS path mangling)
    local dir_path
    dir_path=$(cd "$(dirname "$file")" && pwd -W 2>/dev/null || pwd)

    # Use Docker to fix line endings (works on Windows)
    MSYS_NO_PATHCONV=1 docker run --rm -v "${dir_path}:/work" ubuntu:22.04 \
        sed -i 's/\r$//' "/work/$(basename "$file")" 2>/dev/null || {
        log_warn "Could not fix line endings automatically for $file"
    }
}

# Build the Docker image
build_image() {
    log_info "Building Docker image: $IMAGE_NAME"

    # Fix line endings on startup.sh before build
    fix_line_endings "$SCRIPT_DIR/claude-worker/startup.sh"

    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR/claude-worker"

    log_info "Docker image built successfully"
}

# Check if worker exists
worker_exists() {
    local worker_name="$1"
    curl -s "$DASHBOARD_URL/api/workers/$worker_name" | grep -q '"id"' 2>/dev/null
}

# Delete a worker
delete_worker() {
    local worker_name="$1"
    log_info "Deleting worker: $worker_name"

    local result=$(curl -s -X DELETE "$DASHBOARD_URL/api/workers/$worker_name")
    echo "$result"
}

# Create a worker
create_worker() {
    local worker_name="$1"
    local git_repo="${2:-}"

    log_info "Creating worker: $worker_name"

    local payload="{\"name\": \"$worker_name\""
    if [ -n "$git_repo" ]; then
        payload="$payload, \"git_repo\": \"$git_repo\""
    fi
    payload="$payload}"

    local result=$(curl -s -X POST "$DASHBOARD_URL/api/workers" \
        -H "Content-Type: application/json" \
        -d "$payload")

    echo "$result" | jq . 2>/dev/null || echo "$result"

    # Extract port from result
    local port=$(echo "$result" | jq -r '.port' 2>/dev/null)
    if [ -n "$port" ] && [ "$port" != "null" ]; then
        log_info "Worker will be available on port: $port"
    fi
}

# Wait for container to be ready
wait_for_container() {
    local container_name="$1"
    local max_wait="$STARTUP_WAIT_SECONDS"
    local waited=0

    log_info "Waiting for container to start (max ${max_wait}s)..."

    while [ $waited -lt $max_wait ]; do
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            # Container is running, check if ttyd started by looking at logs
            if docker logs "$container_name" 2>&1 | grep -q "Listening on port"; then
                log_info "Container is ready"
                return 0
            fi
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done
    echo ""

    # Check one more time if container is actually running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_info "Container is running (ready check may have been slow)"
        return 0
    fi

    log_error "Container did not start within ${max_wait}s"
    log_info "Checking logs..."
    docker logs "$container_name" --tail 30 2>/dev/null || true
    return 1
}

# Configure worker after creation
configure_worker() {
    local container_name="$1"

    log_info "Configuring worker..."

    # Pull latest state
    log_info "Pulling latest state from git..."
    docker exec "$container_name" su - claude -c "
        cd /shared/state 2>/dev/null || exit 0
        git config pull.rebase false
        git stash 2>/dev/null || true
        git fetch origin
        git reset --hard origin/main 2>/dev/null || git pull 2>/dev/null || true
    " 2>/dev/null || log_warn "Could not pull state (may be first run)"

    # Fix line endings and create symlinks for all agent start scripts
    log_info "Creating agent symlinks..."
    docker exec "$container_name" su - claude -c '
        for script in /shared/state/agents/cto/children/*/start.sh; do
            if [ -f "$script" ]; then
                agent_name=$(basename $(dirname "$script"))
                # Fix line endings
                sed -i "s/\r$//" "$script" 2>/dev/null || true
                chmod +x "$script"
                ln -sf "$script" "/home/claude/${agent_name}.sh"
                echo "  ~/${agent_name}.sh"
            fi
        done
    ' 2>/dev/null || log_warn "Could not create all symlinks"

    # Verify SSH access
    log_info "Verifying SSH access..."
    docker exec "$container_name" su - claude -c "ssh -T git@github.com 2>&1 | head -1" 2>/dev/null || log_warn "SSH verification inconclusive"
    docker exec "$container_name" su - claude -c "ssh -T git@bitbucket.org 2>&1 | head -1" 2>/dev/null || log_warn "SSH verification inconclusive"
}

# Show worker status
show_status() {
    log_info "Fetching worker status..."
    curl -s "$DASHBOARD_URL/api/workers" | jq . 2>/dev/null || {
        log_error "Could not fetch status"
        exit 1
    }
}

# Show worker logs
show_logs() {
    local worker_name="$1"
    local container_name="claude-worker-$worker_name"

    docker logs "$container_name" --tail 50 -f
}

# Main command handler
case "${1:-}" in
    build)
        check_prerequisites
        build_image
        ;;

    create)
        if [ -z "${2:-}" ]; then
            log_error "Usage: $0 create <worker-name> [git-repo-url]"
            exit 1
        fi
        check_prerequisites

        # Check if image exists, build if not
        if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
            log_warn "Docker image not found, building..."
            build_image
        fi

        WORKER_NAME="$2"
        GIT_REPO="${3:-}"
        CONTAINER_NAME="claude-worker-$WORKER_NAME"

        if worker_exists "$WORKER_NAME"; then
            log_error "Worker '$WORKER_NAME' already exists. Use 'rebuild' to recreate it."
            exit 1
        fi

        create_worker "$WORKER_NAME" "$GIT_REPO"
        wait_for_container "$CONTAINER_NAME"
        configure_worker "$CONTAINER_NAME"

        log_info "Worker '$WORKER_NAME' created successfully"
        echo ""
        echo "To activate an agent, connect to the terminal and run:"
        echo "  ~/<agent-name>.sh"
        ;;

    rebuild)
        if [ -z "${2:-}" ]; then
            log_error "Usage: $0 rebuild <worker-name> [git-repo-url]"
            exit 1
        fi
        check_prerequisites
        build_image

        WORKER_NAME="$2"
        GIT_REPO="${3:-}"
        CONTAINER_NAME="claude-worker-$WORKER_NAME"

        if worker_exists "$WORKER_NAME"; then
            delete_worker "$WORKER_NAME"
            sleep 3
        fi

        create_worker "$WORKER_NAME" "$GIT_REPO"
        wait_for_container "$CONTAINER_NAME"
        configure_worker "$CONTAINER_NAME"

        log_info "Worker '$WORKER_NAME' rebuilt successfully"
        echo ""
        echo "To activate an agent, connect to the terminal and run:"
        echo "  ~/<agent-name>.sh"
        ;;

    delete)
        if [ -z "${2:-}" ]; then
            log_error "Usage: $0 delete <worker-name>"
            exit 1
        fi
        check_prerequisites
        delete_worker "$2"
        log_info "Worker '$2' deleted"
        ;;

    status)
        check_prerequisites
        show_status
        ;;

    logs)
        if [ -z "${2:-}" ]; then
            log_error "Usage: $0 logs <worker-name>"
            exit 1
        fi
        show_logs "$2"
        ;;

    *)
        echo "Claude Worker Farm - Worker Management"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  build                     Build the Docker image"
        echo "  create <name> [repo]      Create a new worker"
        echo "  rebuild <name> [repo]     Delete and recreate a worker (rebuilds image)"
        echo "  delete <name>             Delete a worker"
        echo "  status                    Show all workers"
        echo "  logs <name>               Show worker logs (follows)"
        echo ""
        echo "Examples:"
        echo "  $0 build"
        echo "  $0 create morrison-ops"
        echo "  $0 rebuild registry git@bitbucket.org:xynon/nq.trading.git"
        echo "  $0 status"
        exit 1
        ;;
esac
