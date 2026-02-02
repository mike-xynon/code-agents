# Claude Worker Farm

## What This Does

A Docker-based orchestration system for running multiple Claude Code instances in isolated containers, accessible via a web dashboard. Each worker can clone and work on a different git repository, with SSH key support for private repos.

**Use cases:**
- Run parallel Claude Code agents on different codebases
- Isolate work on different projects in separate containers
- Access Claude Code from any device via web browser
- Share terminal sessions between team members

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
                    | /shared/state   |  <- Agent coordination (markdown)
                    | ~/repos/        |  <- Private repo clones (per-container)
                    +-----------------+
```

## Agent Coordination Model

Workers are **independent Claude Code environments**, not child agents of a parent. Each worker is a fresh session for a specific repository.

```
Parent Agent (Xynon repo - CTO governance)
    └── Tracks outcomes in docs/cto-data/subagent-tasks.md
    └── Mike relays status between parent and workers

Workers (independent, repo-specific):
    ├── nuget      → NQ-NugetLibraries
    ├── portal     → Portal
    ├── registry   → nq.trading
    ├── registry-web → nq.trading.backoffice.web
    ├── reporting  → nq.reporting
    ├── devops     → nq.devops
    ├── platform   → nq.platform
    └── morrison   → nq.morrison
```

**Coordination:**
- `/shared/state/` — Markdown files for loose agent-to-agent communication
- Each repo has its own `CLAUDE.md` as entry point
- Human (Mike) relays status between parent and workers
- No rigid protocol — prompts in, information out

**Starting an Agent Session:**
```bash
# 1. Open worker terminal via dashboard
# 2. Change into the agent's directory
cd /shared/state/agents/cto/children/<agent-name>

# 3. Start Claude Code
claude

# 4. Paste activation prompt (see DESIGN.md for template)
```

This ensures Claude starts with the agent's files (init.md, report.md, inbox/) as local paths.

## Quick Start

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env: add ANTHROPIC_API_KEY and SSH_SECRETS_HOST_PATH

# 2. Copy SSH keys for private repos
cp ~/.ssh/id_rsa_bitbucket secrets/ssh/

# 3. Build and start
docker build -t claude-worker:latest ./claude-worker
docker-compose up -d

# 4. Bootstrap all configured repos
./bootstrap.sh
# Or via API: curl -X POST http://localhost:8080/api/bootstrap

# 5. Open dashboard
open http://localhost:8080
```

## Configured Repositories

Defined in `repos.json`:

| Name | Repository | Description |
|------|------------|-------------|
| nuget | nq-nugetlibraries | Shared NuGet packages |
| portal | portal | Main portal application |
| registry | nq.trading | Trading registry - HIN, positions, transactions |
| registry-web | nq.trading.backoffice.web | Registry admin interface |
| reporting | nq.reporting | Reporting services |
| devops | nq.devops | DevOps infrastructure |
| platform | nq.platform | Core platform services |
| morrison | nq.morrison | Morrison integration |

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Dashboard UI |
| `/api/workers` | GET | List all workers |
| `/api/workers` | POST | Create worker |
| `/api/workers/{id}` | GET | Get worker details |
| `/api/workers/{id}` | DELETE | Delete worker |
| `/api/workers/{id}/restart` | POST | Restart worker |
| `/api/workers/{id}/pull` | POST | Git pull in worker |
| `/api/bootstrap` | POST | Create workers for all repos in repos.json |
| `/api/repos` | GET | List configured repositories |
| `/health` | GET | Health check |

## Features

- Web terminal access via ttyd (WebSocket-based)
- tmux for session persistence and multi-user sharing
- SSH key mounting for private repository access
- Automatic git pull on existing repos (reuses directories by name)
- Bootstrap script to create all configured workers at once
- Mobile-responsive dashboard
- Multi-view mode (grid of terminals)
- **.NET 9 SDK** for building and testing NQ projects
- **Claude Code** pre-installed in each worker

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main orchestration |
| `repos.json` | Repository configuration |
| `bootstrap.sh` | Create workers for all repos |
| `secrets/ssh/` | SSH keys (gitignored) |
| `.env` | Environment config |
| `claude-worker/` | Worker container image |
| `dashboard/` | Flask dashboard app |
| `nginx.conf` | Reverse proxy config |

## Implementation Status

### Completed
- [x] Worker container (Ubuntu + Python + tmux + ttyd + claude-code)
- [x] Dashboard with worker management
- [x] SSH key support for private repos
- [x] Git clone/pull on startup
- [x] Consistent repo directories (by name, not random ID)
- [x] Bootstrap API and script
- [x] Multi-view terminal grid
- [x] Session persistence
- [x] .NET 9 SDK in worker image
- [x] Git safe.directory fix for shared volumes
- [x] **Pre-authentication** - Workers start with Claude Code already logged in

### Recent Fixes (2026-02-02)
1. Added .NET 9 SDK to worker Dockerfile
2. Fixed git safe.directory warnings for shared volumes
3. Updated welcome message to show .NET version
4. Documented agent coordination model
5. Fixed startup.sh to not pollute /shared/repos when no git repo specified
6. Added locale support for proper terminal handling
7. Added terminal environment variables (TERM, COLORTERM, LANG)
8. Created DESIGN.md with full agent communication protocol
9. Fixed session persistence - tmux sessions survive browser disconnect
10. Disabled tmux mouse mode so copy/paste works in browser
11. Enabled ttyd clipboard support
12. Added Claude credentials pre-loading from secrets
13. **Fixed: Pre-authentication now works** - Workers start authenticated automatically

### Pre-Authentication Setup
Claude Code requires two files for pre-authentication (both in `secrets/api/`):
- `credentials.json` - OAuth tokens (access/refresh tokens)
- `claude.json` - OAuth account info (user ID, organization details)

To set up:
1. Start one worker and complete OAuth login manually
2. Copy the files from the authenticated container:
   ```bash
   docker exec <worker> cat /home/claude/.claude/.credentials.json > secrets/api/credentials.json
   docker exec <worker> cat /home/claude/.claude.json > secrets/api/claude.json
   ```
3. All new workers will use these credentials automatically

### Previous Fixes (2026-02-01)
1. Fixed `--once false` bug in startup.sh
2. Added SSH secrets mounting via host path
3. Reordered startup.sh to configure SSH before git clone
4. Added WORKER_NAME for consistent repo directories
5. Added bootstrap endpoint and repos.json config

### Future Improvements
- [ ] Authentication for dashboard
- [ ] TLS/HTTPS support
- [ ] Worker resource limits
- [ ] Task queue integration
- [ ] Automatic cleanup of orphaned containers
- [ ] Clean up old UUID directories in shared-repos volume
