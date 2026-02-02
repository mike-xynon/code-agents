# Agent Farm - Status Report

**Agent:** agent-farm
**Parent:** cto
**Status:** Active
**Last Updated:** 2026-02-03
**Location:** /shared/state/agents/cto/children/agent-farm

## Summary

Agent-farm infrastructure is operational. Recent session (2026-02-03) focused on:
- Clarifying conceptual model (workers vs agents)
- Cleaning up naming confusion (removed "webfarm" references)
- Documenting the three components: Dashboard, Workers, Agent Coordination
- Setting up clean worker instances (cto, claude-farm, agent-farm)

## Recent Changes (2026-02-03)

### Documentation
- Updated DESIGN.md with "Conceptual Model" section
- Clarified distinction: workers are infrastructure, agents are governance roles
- Removed "webfarm" references from examples
- Added typical worker setup table

### Infrastructure
- Rebuilt worker image with sudo and p7zip-full
- Created clean worker set: cto, claude-farm, agent-farm
- Verified claude-config.tar.gz extraction (pre-authentication working)
- Browser tab title now shows "Agent: WorkerName"

## Current Worker Setup

| Worker | Port | Purpose |
|--------|------|---------|
| `claude-worker-cto` | 7681 | Top-level governance agent |
| `claude-worker-claude-farm` | 7682 | Dashboard/infrastructure dev |
| `claude-worker-agent-farm` | 7683 | Agent coordination dev |

## Outstanding Gaps

### Dashboard UI (API exists, no UI buttons)
| Feature | API Endpoint | Status |
|---------|--------------|--------|
| Restart Worker | `POST /api/workers/<id>/restart` | No UI button |
| Git Pull | `POST /api/workers/<id>/pull` | No UI button |
| Bootstrap All | `POST /api/bootstrap` | No UI button |

### Agent Communication UI (documented but not implemented)
- No inbox message count display
- No control message buttons (finish, pause, resume, abort)
- No report.md status display
- No message history viewer

### Worker Container
| Feature | Status |
|---------|--------|
| Resource limits (memory/CPU) | Not configured |
| Health check endpoint | Not present |
| Orphaned container cleanup | Manual only |

## Key Files

| File | Purpose |
|------|---------|
| `DESIGN.md` | Complete agent-farm design and protocol |
| `CLAUDE.md` | Quick start and feature overview |
| `dashboard/app.py` | Flask backend (377 lines) |
| `dashboard/templates/index.html` | Frontend UI (808 lines) |
| `claude-worker/Dockerfile` | Worker image definition |
| `claude-worker/startup.sh` | Worker initialization |

## Next Actions

When resuming development:
1. Add missing UI buttons (Restart, Pull, Bootstrap)
2. Implement agent status visualization
3. Add worker resource management
