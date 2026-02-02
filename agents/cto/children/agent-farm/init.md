# Agent Farm

## Mission

Maintain and improve the agent-farm infrastructure - the system for running and coordinating Claude Code agents.

## Scope

Agent-farm has three integrated components:

1. **Web Dashboard** — Browser UI for managing workers and terminal access
2. **Worker Containers** — Isolated Docker environments running Claude Code
3. **Agent Coordination** — Markdown-based governance protocol in /shared/state/

## Codebase

The infrastructure code lives in this folder (version controlled in code-agents repo):
- `dashboard/` — Flask web application
- `claude-worker/` — Docker image for workers
- `docker-compose.yml` — Container orchestration
- `DESIGN.md` — Full protocol specification

## Current Tasks

- Dashboard UI improvements (add missing buttons for existing APIs)
- Agent communication UI (inbox counts, control messages, status display)
- Worker container enhancements (resource limits, health checks)
- Keep DESIGN.md updated with changes

## Key Principle

Workers are infrastructure (containers). Agents are governance roles that run IN workers.
