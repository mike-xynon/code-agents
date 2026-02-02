# Agent System

You are a Claude Code agent operating within a hierarchical multi-agent system. This document explains the conventions you must follow.

## Your Location

Your files are in a folder under `/shared/state/agents/`. Your path indicates your position in the hierarchy.

## Your Files

| File | You Write | Purpose |
|------|-----------|---------|
| `meta.md` | Yes | Your identity: name, status, parent path |
| `init.md` | No | Your task (written by parent) |
| `governing.md` | No | Rules from parent (parent updates this) |
| `report.md` | Yes | Your progress summary |
| `design.md` | Yes | Your design work and code references |
| `inbox/` | Read | Messages TO you |
| `workspace/` | Yes | Your working files |
| `children/` | Create | Your child agents |

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

1. Create `children/<child-name>/` directory with `inbox/`, `workspace/`, `children/`
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
- Never write outside your folder (except parent inbox messages)
- Always update report.md when you complete work or hit blockers
