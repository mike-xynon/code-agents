# Agent System

You are a Claude Code agent operating within a hierarchical multi-agent system. This document explains the conventions you must follow.

## Volume Structure

```
/shared/state/     <- Agent coordination (markdown files ONLY)
/home/claude/      <- Your private working directory
```

**IMPORTANT:**
- `/shared/state/` is for agent coordination markdown files ONLY
- Git repositories belong in your private home directory: `/home/claude/repos/`
- `/shared/repos/` exists but is reserved for future use — do NOT use without explicit permission

## Your Location

Your agent files are in a folder under `/shared/state/agents/`. Your path indicates your position in the hierarchy.

## Your Files

| File | You Write | Purpose |
|------|-----------|---------|
| `meta.md` | Yes | Your identity: name, status, parent path |
| `init.md` | No | Your task (written by parent) |
| `governing.md` | No | Rules from parent (parent updates this) |
| `report.md` | Yes | Your progress summary |
| `design.md` | Yes | Your design work and code references |
| `inbox/` | Read | Messages TO you |
| `children/` | Create | Your child agents |

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

To find available repositories, walk up the tree until you find `repos.md`.

## Finding Resources

- **Your parent:** `../..` from your folder (in `children/` of parent)
- **Repos config:** Walk up tree until you find `repos.md`
- **Operating rules:** Walk up tree until you find `rules.md`

## Communication

### To message your parent:
Write to `../../inbox/<your-name>-YYYY-MM-DD-HHMM.md`

### To control a child:
Write to `children/<child-name>/inbox/control-YYYY-MM-DD-HHMM.md`

### Control types:
- `finish` - Child should wrap up and report
- `pause` - Child should stop and wait
- `resume` - Child should continue
- `abort` - Child should stop immediately

## Spawning Children

1. Create `children/<child-name>/` directory with `inbox/`, `children/`
2. Write `init.md` with the task
3. Write `governing.md` with rules
4. Human will start the child agent session

## Code References

Format: `<repo>:<file>:<line>`
Example: `registry:src/Hin/Transfer.cs:142`

## Inbox Checking

Periodically check your `inbox/` folder. Comply with control messages promptly.

## Rules

- Max 4 levels deep
- Folder names: short, lowercase, hyphenated
- Never write outside your agent folder (except parent inbox messages)
- Always update report.md when you complete work or hit blockers
- Repositories go in `/home/claude/repos/`, NOT in `/shared/`
- Only markdown coordination files go in `/shared/state/`
