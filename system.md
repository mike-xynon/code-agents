# Claude Agent Farm - System Conventions

## Shared Services

### PostgreSQL (Registry Database)

```
Host:     host.docker.internal
Port:     54320
Database: nq_registry_local
Username: postgres
Password: TestPass123!
```

Connection string:
```
Host=host.docker.internal;Port=54320;Database=nq_registry_local;Username=postgres;Password=TestPass123!
```

## Volume Structure

```
/shared/state/     <- Agent coordination (markdown files ONLY)
/home/claude/      <- Your private working directory
```

**IMPORTANT:**
- `/shared/state/` is for agent coordination markdown files ONLY
- Git repositories belong in your private home directory: `/home/claude/repos/`
- `/shared/repos/` exists but is reserved for future use — do NOT use without explicit permission

## Working with Repositories

Clone repositories into your private home directory:
```bash
mkdir -p ~/repos
cd ~/repos
git clone git@bitbucket.org:xynon/<repo>.git
```

This ensures:
- Your work is isolated from other agents
- No git conflicts between agents
- Clean separation of concerns

## Your Agent Files

Located in `/shared/state/agents/<path-to-you>/`:

| File | Purpose |
|------|---------|
| init.md | Your assigned task (read this first) |
| governing.md | Rules from your parent |
| report.md | Your progress (you write this) |
| design.md | Your decisions (you write this) |
| inbox/ | Messages to you (check periodically) |

To find available repositories, walk up the tree until you find `repos.md`.

## Communication

### Messaging Parent
Write to: `../../inbox/<your-name>-YYYY-MM-DD-HHMM.md`

### Control Messages
Parents send these to your inbox:
- `finish` — Wrap up and write final report
- `pause` — Stop and wait
- `resume` — Continue work
- `abort` — Stop immediately

### Initiating Agent Sessions
When sending a message to an agent's inbox, **always provide both**:
1. **Inbox message** — The markdown file in `inbox/`
2. **Startup sequence** — Commands and prompt to paste into the agent's Claude session

**Startup sequence format:**

1. First, cd to the agent's state folder:
```bash
cd /shared/state/agents/<path>
```

2. Pull latest state and clone required repos:
```bash
cd /shared/state && git pull
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/<repo1>.git <name1>
git clone git@bitbucket.org:xynon/<repo2>.git <name2>
cd /shared/state/agents/<path>
```

3. Then paste the startup prompt:
```
You are the <agent-name> agent. Read your agent files in this directory:

1. Read init.md — Your mission
2. Read design.md — Architecture decisions
3. Read report.md — Current progress
4. Check inbox/ — Pending messages

Start by reading report.md for where you left off.
```

### Progress Updates
Update `report.md` regularly:
- When you complete a task
- When you hit a blocker
- Before ending a session

## Code References

Format: `<repo>:<file>:<line>`

Example: `registry:src/Hin/Transfer.cs:142`

## Accessing Host Services

Agent containers can access services running on the host machine (outside Docker) using `host.docker.internal` as the hostname.

| Service | Host Port | Connection from Container |
|---------|-----------|---------------------------|
| PostgreSQL | 54320 | `Host=host.docker.internal;Port=54320;...` |
| SQL Edge | 14330 | `Server=host.docker.internal,14330;...` |

**Example connection strings:**
```
# PostgreSQL
Host=host.docker.internal;Port=54320;Database=nq_registry_local;Username=postgres;Password=TestPass123!

# SQL Edge
Server=host.docker.internal,14330;Database=InstrumentsTest;User Id=sa;Password=TestPass123!;TrustServerCertificate=True;
```

**Note:** Do NOT use `localhost` inside containers — it refers to the container itself, not the host.

## Branching Strategy

**Code repositories** (registry, portal, nuget, etc.):
- **Always work on a branch** — never commit directly to main/master
- Branch naming: `features/<feature-name>` (e.g., `features/fee-calculation-fix`)
- **Confirm with parent before creating a branch** — describe what you're doing and get approval
- Create PR when ready for review

**State repository** (/shared/state):
- Changes to your agent folder: commit directly to main
- Messages to parent inbox: commit directly to main
- No branch needed for agent coordination files

**Example workflow:**
```bash
# Work on main locally, pull periodically to stay current:
cd ~/repos/registry
git checkout main
git pull

# ... make changes on main ...

# When ready to commit - ask parent for branch name, then:
git pull                              # Pull again before branching
git checkout -b features/my-feature   # Create branch with your changes
git add .
git commit -m "Description of changes"
git push -u origin features/my-feature
```

## Key Rules

1. Repositories go in `/home/claude/repos/`, NOT in `/shared/`
2. Only markdown coordination files go in `/shared/state/`
3. Never modify files outside your agent folder (except parent inbox messages)
4. Update report.md before ending any session
5. Use `host.docker.internal` to access host services, not `localhost`
6. Always use feature branches for code changes — confirm branch name with parent first
