# Agent-Farm Design

## Overview

Agent-Farm is the infrastructure for running and coordinating multiple Claude Code agents. It provides Docker-based isolation, web-based terminal access, and a markdown-based coordination protocol.

## Conceptual Model

Agent-Farm has three integrated components:

```
┌─────────────────────────────────────────────────────────────┐
│                        AGENT-FARM                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │  Web Dashboard  │  │ Worker Containers│  │   Agent     │ │
│  │                 │  │                 │  │ Coordination │ │
│  │ • Manage workers│  │ • Isolated envs │  │             │ │
│  │ • Terminal UI   │  │ • Claude Code   │  │ • Hierarchy │ │
│  │ • Status view   │  │ • .NET, Node    │  │ • Messaging │ │
│  │                 │  │ • Git access    │  │ • State     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│         ▲                    ▲                    ▲        │
│         │                    │                    │        │
│    localhost:8080      claude-worker-*      /shared/state/ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| Component | What it is | Where it lives |
|-----------|------------|----------------|
| **Web Dashboard** | Browser UI for managing workers and terminal access | `claude-farm-dashboard` container, port 8080 |
| **Worker Containers** | Isolated Claude Code environments | `claude-worker-<name>` containers |
| **Agent Coordination** | Markdown-based governance and messaging | `/shared/state/agents/` volume |

**Key distinction:** Workers are infrastructure (containers). Agents are governance roles that run IN workers.

## Agent Coordination Protocol

This section describes the file-based communication system for coordinating agents. Agents are organized hierarchically with parent-child relationships, communicating via markdown files in a shared volume.

## Architecture

```
/shared/state/
├── system.md                             <- Global conventions (all agents read this)
│
└── agents/
    └── <top-level>/                      <- e.g., cto, ops
        ├── meta.md                       <- Agent identity
        ├── init.md                       <- Initiating task (empty for root)
        ├── governing.md                  <- Rules from parent
        ├── repos.md                      <- Repos this tree can access
        ├── rules.md                      <- Operating rules for children
        ├── report.md                     <- Progress summary
        ├── design.md                     <- Design work, code references
        ├── inbox/                        <- Messages TO this agent
        │
        └── children/
            └── <child-agent>/            <- Nested child
                ├── meta.md
                ├── init.md               <- Task from parent
                ├── governing.md          <- Rules from parent
                ├── report.md
                ├── design.md
                ├── inbox/
                └── children/             <- Max 4 levels deep
```

## Standard Files

| File | Written By | Purpose |
|------|------------|---------|
| `meta.md` | Self | Identity: name, created, status, parent path |
| `init.md` | Parent | Initiating task/prompt that spawned this agent |
| `governing.md` | Parent | Rules, constraints (parent can update anytime) |
| `repos.md` | Top-level only | Repos this agent tree can access |
| `rules.md` | Top-level only | Operating rules inherited by children |
| `report.md` | Self | Progress summary, task tracking, objective status |
| `design.md` | Self | Design details, decisions, code references |

## Naming Rules

- **Folder names:** Short, lowercase, hyphenated (e.g., `registry-hin`, `nuget-build`)
- **Max depth:** 4 levels under `agents/`
- **No spaces, no special characters**

## Communication Protocol

### Child → Parent Messages

Child writes to parent's inbox:
```
../../inbox/<child-name>-YYYY-MM-DD-HHMM.md
```

Example: `/shared/state/agents/cto/inbox/nuget-build-2026-02-02-1430.md`

### Parent → Child Control

Parent writes to child's inbox:
```
children/<child-name>/inbox/control-YYYY-MM-DD-HHMM.md
```

### Control Message Types

| Control | Meaning |
|---------|---------|
| `finish` | Wrap up gracefully, write final report |
| `pause` | Stop active work, await further instructions |
| `resume` | Continue from where you paused |
| `abort` | Stop immediately, something is wrong |

### Control Message Format

```markdown
# Control: <type>

<instructions>

## Reason
<why this control was issued>

## Action Required
<specific steps to take>
```

## Agent Lifecycle

### Creating a Child Agent

1. Parent creates directory: `children/<child-name>/`
2. Parent writes `init.md` with the task
3. Parent writes `governing.md` with rules
4. Parent updates own `meta.md` to list new child
5. Human starts Claude session in appropriate worker
6. Human changes into agent directory and starts Claude Code
7. Human pastes activation prompt to start the agent

### Agent Startup

**IMPORTANT:** Before starting Claude Code, the human must change into the agent's directory:

```bash
cd /shared/state/agents/<path-to-agent>
claude
```

This ensures Claude Code starts with the agent's files (init.md, report.md, inbox/) in the local directory.

Then paste the activation prompt:

```
You are the **<agent-name>** agent. Read your initialization files:
1. Read `/shared/state/system.md` for system conventions
2. Read `init.md` for your task
3. Read `governing.md` for rules from your parent
4. Walk up the tree to find `repos.md` for available repositories

After reading, update your `report.md` with current status and check your `inbox/` for messages.
```

When an agent starts, it should:
1. Read `/shared/state/system.md` to understand conventions
2. Read its own `init.md` to understand its task
3. Read `governing.md` for parent's rules
4. Find `repos.md` by walking up the tree
5. Create/update `meta.md` with its identity
6. Create/update `report.md` and `design.md`
7. Check `inbox/` for any pending messages

### Agent Operation

During operation, agent should:
1. Periodically check `inbox/` for control messages
2. Update `report.md` with progress
3. Update `design.md` with design decisions and code references
4. Message parent via inbox when blocked or complete

### Agent Completion

When finishing (or receiving `finish` control):
1. Save work in progress to `design.md`
2. Write final status to `report.md`
3. Write completion message to parent's inbox
4. Stop working

## Repository Access

**IMPORTANT:** Each agent clones repos into their private home directory (`~/repos/`).
The `/shared/repos/` volume is reserved for future use — do NOT use without explicit permission.

Clone command pattern:
```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/<repo>.git <local-name>
```

| Local Name | Bitbucket Repo | Description |
|------------|----------------|-------------|
| nuget | `xynon/nq-nugetlibraries` | Shared NuGet packages |
| portal | `xynon/portal` | Main portal application |
| registry | `xynon/nq.trading` | Trading registry (HIN, positions) |
| registry-web | `xynon/nq.trading.backoffice.web` | Registry admin interface |
| reporting | `xynon/nq.reporting` | Reporting services |
| devops | `xynon/nq.devops` | DevOps infrastructure |
| platform | `xynon/nq.platform` | Core platform services |
| morrison | `xynon/nq.morrison` | Morrison integration |

This pattern ensures:
- Agents have isolated working directories
- No git conflicts between agents
- Clean separation of concerns

## Code References

When referencing code changes, use format:
```
<repo>:<file>:<line>
```
Example: `registry:src/Hin/Transfer.cs:142`

## UI Integration

The dashboard can facilitate communication by:
1. Displaying inbox message counts per agent
2. Providing buttons to send control messages
3. Showing report.md status for each agent
4. Viewing message history

This keeps Claude interaction simple (reading/writing markdown) while the UI handles orchestration complexity.

## Docker Infrastructure

### Container Naming Convention

Worker containers are named using the friendly worker name:

```
claude-worker-<sanitized-name>
```

Examples:
- `claude-worker-cto`
- `claude-worker-agent-farm`
- `claude-worker-registry`
- `claude-worker-portal`

The sanitized name is:
- Lowercase
- Spaces replaced with hyphens
- Special characters removed
- Used as both the Docker container name and worker ID

### Worker Environment

Each worker container includes:

| Package | Purpose |
|---------|---------|
| `nodejs` | Required for Claude Code |
| `dotnet-sdk-9.0` | Building .NET projects |
| `git` | Version control |
| `sudo` | Passwordless sudo for claude user |
| `p7zip-full` | Archive extraction |
| `tmux` | Terminal multiplexing |
| `ttyd` | Web terminal access |

The `claude` user has passwordless sudo access:
```
claude ALL=(ALL) NOPASSWD:ALL
```

### Volume Mounts

| Container Path | Docker Volume | Purpose |
|---------------|---------------|---------|
| `/shared/repos` | `docker-claude-farm_shared-repos` | Reserved for future use |
| `/shared/state` | `docker-claude-farm_shared-state` | Agent coordination (markdown only) |
| `/secrets/ssh` | Host path (optional) | SSH keys for git |
| `/secrets/api` | Host path (optional) | API keys |
| `/home/claude` | Per-container | Private working directory (repos cloned here) |

### Dashboard UI

The web dashboard at `http://localhost:8080` provides:

- **Worker list** with status indicators
- **Create worker** form (name + optional git repo)
- **Single/Multi view** terminal modes
- **Browser tab title** updates to show `Agent: <WorkerName>` when connected
- **Auto-refresh** every 10 seconds

### Worker Name Recovery

When the dashboard restarts, worker names are recovered from the `WORKER_NAME` environment variable stored in each container. This ensures friendly names persist across dashboard restarts.

### Adding a New Worker

1. Enter name in dashboard (e.g., "registry")
2. Container created as `claude-worker-registry`
3. Worker ID becomes `registry`
4. Display name becomes `Registry`

Workers clone repositories into their private `~/repos/` directory on startup.

### Typical Worker Setup

| Worker | Purpose |
|--------|---------|
| `cto` | Top-level governance agent |
| `agent-farm` | Works on agent-farm infrastructure |
| `registry` | Works on registry codebase |
| `portal` | Works on portal codebase |
| `copilot` | Works on copilot features |

## Terminal Scrolling

The web terminal uses ttyd + tmux + xterm.js. Mouse wheel scrolling is configured to scroll tmux history rather than being passed to applications (which would interpret wheel as arrow keys).

### tmux Configuration

```bash
# Enable mouse mode
set -g mouse on

# 50,000 line scrollback buffer
set -g history-limit 50000

# Mouse wheel scrolls tmux history directly
# - WheelUp: enters copy-mode if needed, scrolls up 5 lines
# - WheelDown: scrolls down, auto-exits copy-mode at bottom (-e flag)
bind-key -T root WheelUpPane if-shell -F '#{pane_in_mode}' 'send-keys -X -N 5 scroll-up' 'copy-mode -e; send-keys -X -N 5 scroll-up'
bind-key -T root WheelDownPane if-shell -F '#{pane_in_mode}' 'send-keys -X -N 5 scroll-down' 'send-keys -X -N 5 scroll-down'
```

### Scroll Behavior

1. **Scroll up** - Enters tmux copy-mode and scrolls history
2. **Scroll down** - Scrolls down in copy-mode
3. **Reach bottom** - Auto-exits copy-mode (due to `-e` flag)
4. **Type normally** - Works once out of copy-mode
5. **Exit copy-mode manually** - Press `q` or `Escape`

### xterm.js Configuration

ttyd passes these options to xterm.js:
- `scrollback=50000` - Browser-side scrollback buffer
- `scrollSensitivity=3` - Scroll speed multiplier

### Custom ttyd Index

A custom `ttyd-index.html` is used with CSS fixes for the scrollbar:
```css
.xterm .xterm-screen {
    margin-right: 20px;  /* Prevent fit addon from covering scrollbar */
}
```

## Limitations

- Max 4 levels of nesting
- Agents cannot directly message siblings (must go through parent)
- No real-time messaging (file-based polling)
- Human facilitates agent startup (pastes init.md into Claude session)
