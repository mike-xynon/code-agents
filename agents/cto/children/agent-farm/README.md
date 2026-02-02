# Claude Worker Farm

A Docker-based orchestration system for running multiple Claude Code instances in isolated containers, accessible via a web dashboard from any device.

## Features

- **Multi-Worker Management**: Create, manage, and monitor multiple Claude Code instances
- **Web Terminal Access**: Connect to any worker via browser using ttyd
- **Session Persistence**: tmux sessions persist when users disconnect
- **Multi-User Support**: Multiple users can connect to the same session simultaneously
- **Single & Multi-View Modes**: View one terminal at a time or all terminals in a grid
- **Mobile Responsive**: Access and use the dashboard from any device
- **Git Integration**: Clone repositories automatically when creating workers
- **Shared Storage**: All workers share common storage for repos and state

## Architecture

```
                    +------------------+
                    |   Nginx :8080    |
                    |  (entry point)   |
                    +--------+---------+
                             |
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
    +-----------+     +-----------+      +-----------+
    | Dashboard |     | Worker 1  |      | Worker N  |
    |   :5000   |     |   :7681   |      |   :768N   |
    +-----------+     +-----------+      +-----------+
          |                  |                  |
          +------------------+------------------+
                             |
                    +--------+--------+
                    |  Shared Volumes |
                    | /shared/repos   |
                    | /shared/state   |
                    +-----------------+
```

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- An Anthropic API key

### Installation

1. **Clone or download this repository**
   ```bash
   git clone <repository-url>
   cd docker-claude-farm
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env and add your ANTHROPIC_API_KEY
   ```

3. **Build the worker image**
   ```bash
   docker build -t claude-worker:latest ./claude-worker
   ```

4. **Start the system**
   ```bash
   docker-compose up -d
   ```

5. **Access the dashboard**
   Open http://localhost:8080 in your browser

## Usage

### Creating a Worker

1. Open the dashboard at http://localhost:8080
2. Enter a name for your worker (optional)
3. Enter a Git repository URL to clone (optional)
4. Click "Create Worker"
5. Wait for the worker to start (typically 5-10 seconds)
6. Click "Connect" to open the terminal

### Connecting to Workers

- **Single View**: Click on any worker card to view its terminal
- **Multi View**: Click "Multi View" toggle, then click multiple workers to add them to the grid
- **New Tab**: Click "Open in New Tab" to get a dedicated terminal window

### Using Claude Code

Once connected to a worker terminal, you can use Claude Code:

```bash
# Start Claude Code
claude

# Or with specific options
claude --help
```

### Session Persistence

- Sessions persist even when you close the browser
- Reconnect to see exactly where you left off
- Multiple users can connect to the same session and collaborate

### Accessing from Other Devices

1. Find your machine's IP address
2. Update `NGINX_HOST` in `.env` to your IP
3. Restart the services: `docker-compose restart`
4. Access from any device at `http://<your-ip>:8080`

## API Reference

### List Workers
```
GET /api/workers
```

### Create Worker
```
POST /api/workers
Content-Type: application/json

{
  "name": "My Worker",
  "git_repo": "https://github.com/user/repo.git"
}
```

### Delete Worker
```
DELETE /api/workers/{worker_id}
```

### Restart Worker
```
POST /api/workers/{worker_id}/restart
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key | (required) |
| `NGINX_HOST` | Host address for the dashboard | `localhost` |
| `MAX_WORKERS` | Maximum number of workers | `20` |
| `BASE_PORT` | Starting port for workers | `7681` |

### Volumes

| Volume | Purpose |
|--------|---------|
| `shared-repos` | Stores cloned repositories |
| `shared-state` | Stores worker state and config |
| `redis-data` | Redis persistence |

## Troubleshooting

### Worker won't start

1. Check Docker logs:
   ```bash
   docker logs claude-worker-<id>
   ```

2. Ensure the worker image is built:
   ```bash
   docker images | grep claude-worker
   ```

3. Check if ports are available:
   ```bash
   netstat -tlnp | grep 768
   ```

### Can't connect to terminal

1. Wait 10-20 seconds for ttyd to start
2. Check if the worker container is running:
   ```bash
   docker ps | grep claude-worker
   ```

3. Try accessing the terminal directly:
   ```bash
   curl http://localhost:7681/
   ```

### Dashboard shows no workers

1. Ensure Docker socket is mounted
2. Check dashboard logs:
   ```bash
   docker logs claude-farm-dashboard
   ```

### API key not working

1. Verify the key is set in `.env`
2. Restart the services:
   ```bash
   docker-compose restart
   ```

## Security Notes

This system is designed for development and internal use. For production:

1. Add authentication to the dashboard
2. Enable TLS/HTTPS via nginx
3. Restrict network access
4. Use Docker secrets for API keys
5. Enable Redis authentication

## Development

### Rebuilding images

```bash
# Rebuild worker image
docker build -t claude-worker:latest ./claude-worker

# Rebuild dashboard image
docker-compose build dashboard

# Restart with new images
docker-compose up -d
```

### Viewing logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dashboard

# Worker container
docker logs -f claude-worker-<id>
```

### Cleaning up

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove worker containers
docker rm -f $(docker ps -aq -f name=claude-worker-)
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.
