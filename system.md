# Claude Agent Farm - System Conventions

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

### Progress Updates
Update `report.md` regularly:
- When you complete a task
- When you hit a blocker
- Before ending a session

## Code References

Format: `<repo>:<file>:<line>`

Example: `registry:src/Hin/Transfer.cs:142`

## Key Rules

1. Repositories go in `/home/claude/repos/`, NOT in `/shared/`
2. Only markdown coordination files go in `/shared/state/`
3. Never modify files outside your agent folder (except parent inbox messages)
4. Update report.md before ending any session
