# Copilot Agent

## Mission
Implement the Trading Copilot feature across the NQ platform.

## Repositories
Clone these into your private home directory (`~/repos/`):

| Name | Bitbucket Repo | Purpose |
|------|----------------|---------|
| portal | `xynon/portal` | UI (PWA) and API |
| nuget | `xynon/nq-nugetlibraries` | Shared NuGet packages (NQ.Copilot) |

```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/portal.git portal
git clone git@bitbucket.org:xynon/nq-nugetlibraries.git nuget
```

## Design Documents (ASK USER FOR CONTENT)
You do NOT have direct access to these files. You MUST ask the user to provide their content:

1. **CLAUDE.md** — Entry point, current status
2. **trading-copilot-design.md** — Architecture (Phase 1 foundation, Phase 2 intelligence)
3. **trading-support-system-design.md** — 10 tool specifications
4. **copilot-trading-extension.md** — Active development log

## Context

**What exists:**
- Design is complete and approved
- Architecture: New `SessionMode.Trading` extending existing NQ.Copilot
- Two separate tool sets (Ursa for single portfolio, Trading for multi-portfolio)

**Phase 1 Tasks (ready to implement):**
1. Trading copilot context setup (mode, prompt, tool provider split)
2. Portfolio drift & categorization tools (uses existing `IImgrPortfolioService`)
3. Target group analysis tools (substitutable instruments)
4. IM-provided signals storage (buy/hold/sell, price targets - session-based)

## Workflow
1. Read the design docs by asking the user for their content
2. Check what was last worked on (from copilot-trading-extension.md)
3. Confirm with user which task to pick up before writing code
4. Implement incrementally, updating report.md with progress

## First Steps
1. Ask user to provide content of CLAUDE.md
2. Ask user to provide content of trading-copilot-design.md
3. Ask user to provide content of trading-support-system-design.md
4. Ask user to provide content of copilot-trading-extension.md
5. Summarize current state and confirm next task with user
