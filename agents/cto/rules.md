# Operating Rules for CTO Children

These rules apply to all agents under the CTO hierarchy.

## Repository Isolation

**Critical:** Each agent works in their own private directory.

```
/home/claude/repos/    <- Clone and work here (PRIVATE to your container)
/shared/state/         <- Agent coordination markdown ONLY
/shared/repos/         <- Reserved for future use — DO NOT USE
```

When starting work:
```bash
mkdir -p ~/repos
cd ~/repos
git clone git@bitbucket.org:xynon/<repo-name>.git
cd <repo-name>
```

This ensures your work is isolated from other agents. Never work directly in `/shared/repos/`.

## Workflow

All implementation work follows this pattern:

```
1. FAMILIARISATION
   - Explore repositories, code structures, existing markdown
   - Understand what exists before proposing new things

2. DESIGN PHASE
   - Create a markdown design document
   - Document findings, proposed architecture, open questions
   - Do NOT implement yet

3. CONFIRMATION CHECKPOINT
   - Present design to Mike for review
   - Get concept approval before proceeding

4. IMPLEMENTATION (only after approval)
   - Build incrementally
   - Check in regularly
```

## Code Standards

1. **Test before committing** — All changes should be tested
2. **Small, focused changes** — One concern per commit
3. **Update documentation** — Keep design.md current as you work
4. **No over-engineering** — Solve the current problem, not hypothetical future ones

## Communication

1. **Update report.md** — After completing work or hitting blockers
2. **Message parent inbox** — When blocked, when complete, or for decisions
3. **Check your inbox** — Periodically, for control messages
4. **Ask before major decisions** — Don't assume, confirm with Mike

## Code References

When referencing code, use format: `<repo>:<file>:<line>`

Example: `registry:src/Hin/Transfer.cs:142`

## Repository Access

Agents can only access repos listed in `repos.md` (walk up tree to find it).

Clone from Bitbucket into your private home directory:

| Name | Bitbucket Repo | Purpose |
|------|----------------|---------|
| nuget | `xynon/nq-nugetlibraries` | Shared NuGet packages |
| portal | `xynon/portal` | Main portal application |
| registry | `xynon/nq.trading` | Trading registry |
| registry-web | `xynon/nq.trading.backoffice.web` | Registry admin UI |
| platform | `xynon/nq.platform` | Core platform services |
| reporting | `xynon/nq.reporting` | Reporting services |
| devops | `xynon/nq.devops` | DevOps infrastructure |
| morrison | `xynon/nq.morrison` | Morrison integration |

Example:
```bash
cd ~/repos
git clone git@bitbucket.org:xynon/nq.trading.git registry
```

## Boundaries

1. **Max 4 levels deep** — Don't create deeply nested agent hierarchies
2. **Stay in your lane** — Only modify repos relevant to your mission
3. **No destructive actions** — Don't delete data, force push, or similar without explicit approval
4. **Secrets stay secret** — Never commit API keys, passwords, or credentials
