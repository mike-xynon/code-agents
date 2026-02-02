# Copilot Agent

## Mission
Implement the Trading Copilot feature across the NQ platform - extending NQ.Copilot with a new `SessionMode.Trading` mode for multi-portfolio trade execution.

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

Location: `C:\Users\Micha\source\repos\nq\ClaudePortal\`

| File | Purpose |
|------|---------|
| `trading-copilot-design.md` | Architecture (Phase 1 foundation, Phase 2 intelligence) |
| `trading-support-system-design.md` | 10 tool specifications |
| `copilot-trading-extension.md` | Active development log |

## Architecture

```
SessionMode
├── Ursa (existing)       <- Single portfolio, Investor → mandate → model
└── Trading (new)         <- Multi-portfolio, Drift → grouping → execution

Trading Workflow:
[IM signals] → Drift Analysis → Grouping → Preview → Execute → Monitor
```

### Tool Architecture (8 Tools)

| Tool | Purpose | Category |
|------|---------|----------|
| `GetPortfolioDrift` | Analyze drift from target weights | Analysis |
| `GetGroupedDrift` | Group drift by instrument across portfolios | Analysis |
| `GetTargetGroupAnalysis` | Find substitutable instruments | Analysis |
| `GetInstrumentSignals` | Retrieve IM-provided signals | Signals |
| `UpdateInstrumentSignals` | Store buy/hold/sell signals | Signals |
| `GetTradePreview` | Preview trades before execution | Execution |
| `SubmitTrades` | Execute trades across portfolios | Execution |
| `GetTradeStatus` | Check execution status | Execution |

## Current State

**Completed:**
- Design approved
- 8 trading tools implemented (commit `97a8200c`)
- SessionMode.Trading added
- Tool provider architecture established

**In Progress:**
- Wiring `ITradingPortfolioService` to `CopilotContext`
- Adding `Mode` property to context
- Updating test mocks

**Blockers:**
- None currently

## Phase 1 Tasks

| # | Task | Status |
|---|------|--------|
| 1 | Trading copilot context setup (mode, prompt, tool provider split) | In Progress |
| 2 | Portfolio drift & categorization tools | Complete |
| 3 | Target group analysis tools | Complete |
| 4 | IM-provided signals storage (session-based) | Complete |
| 5 | Trade preview and submission | Complete |
| 6 | Integration tests | Not Started |
| 7 | Portal UI integration | Not Started |

## Phase 2 Tasks (Future)

| # | Task | Status |
|---|------|--------|
| 1 | Tax lot optimization (Navexa integration) | Future |
| 2 | Cross-portfolio optimization | Future |
| 3 | Compliance rule checking | Future |

## Workflow
1. Read `design.md` to understand current architecture and decisions
2. Check `report.md` for latest progress and next steps
3. Confirm with user which task to pick up before writing code
4. Implement incrementally, updating report.md with progress
5. Message parent at `../../inbox/copilot-YYYY-MM-DD-HHMM.md` when blocked or complete

## First Steps (New Session)
1. Read `design.md` for architecture context
2. Read `report.md` for current progress
3. Check `inbox/` for control messages
4. Review uncommitted changes in nuget repo
5. Confirm next task with user before implementing
