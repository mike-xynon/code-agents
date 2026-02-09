# CTO Agent - Design & Architecture

## Agent Coordination Architecture

```
/shared/state/agents/
└── cto/                          <- This agent
    ├── meta.md                   <- Identity
    ├── init.md                   <- Mission
    ├── rules.md                  <- Rules for children
    ├── repos.md                  <- Available repos
    ├── report.md                 <- Status tracking
    ├── design.md                 <- This file
    ├── inbox/                    <- Messages from children
    └── children/
        ├── copilot/              <- Trading Copilot agent
        ├── registry/             <- Registry test system agent
        └── agent-farm/           <- Infrastructure agent
```

## Technology Vision Alignment

### Priority Framework

| Priority | Focus | Rationale |
|----------|-------|-----------|
| P0 | Registry System | Foundational - position truth enables everything else |
| P1 | Corporate Actions | Proves orchestration, Morrison integration showcase |
| P2 | Trading Copilot | Ultimate differentiator, requires P0 complete |

### Key Architectural Decisions

#### 1. Trading Copilot Architecture
- **Decision:** Extend NQ.Copilot with new `SessionMode.Trading`
- **Rationale:** Reuses existing infrastructure, clean separation from Ursa mode
- **Two tool sets:**
  - Ursa (existing): Single portfolio, Investor → mandate → model
  - Trading (new): Multi-portfolio, Drift → grouping → execution
- **Reference:** `ClaudePortal/trading-copilot-design.md`

#### 2. Registry System
- **Decision:** Focus on test infrastructure first
- **Rationale:** Tests provide safety net for refactoring, document expected behavior
- **Components:**
  - nq.trading — Core registry (HIN, positions, transactions)
  - nq.trading.backoffice.web — Admin interface
- **Infrastructure:** Docker + Postgres for local development

#### 3. Corporate Action Elections
- **Decision:** Digital capture with RG179 authority tracking
- **Architecture:**
  ```
  [Investor/Adviser]
      → [Xynon: UX, workflow, authentication, audit]
          → [Morrison: HIN sponsor, registry submission]
              → [Share Registry]
  ```
- **Key constraint:** Legal relationship is investor ↔ registry, not through adviser

#### 4. Agent Coordination
- **Decision:** File-based communication via /shared/state/
- **Rationale:** Simple, auditable, works with Claude Code's file tools
- **Protocol:**
  - Children message parent via `../../inbox/`
  - Parents control children via `children/<name>/inbox/`
  - All agents update `report.md` regularly

#### 5. Repository Isolation
- **Decision:** Each agent clones repos to private home directory (`~/repos/`)
- **Rationale:** Prevents git conflicts between agents, clean isolation
- **Rule:** `/shared/repos/` is reserved for future use — do not use without permission
- **Pattern:**
  ```bash
  mkdir -p ~/repos && cd ~/repos
  git clone git@bitbucket.org:xynon/<repo>.git <local-name>
  ```

## Repository Architecture

| Repo | Layer | Dependencies |
|------|-------|--------------|
| nuget | Shared libraries | None |
| platform | Core services | nuget |
| registry | Domain (trading) | nuget, platform |
| portal | UI + API | nuget, platform, registry |
| reporting | Analytics | nuget, platform |
| morrison | Integration | nuget, platform |
| devops | Infrastructure | — |

## Vision Document References

Detailed vision in Xynon repo:
- `xynon-technology-vision.md` — Strategic priorities, build sequence
- `wealth-management-complexity.md` — Problem domain, players, coordination
- `ai-agent-implementation-guide.md` — .NET agent patterns
- `orchestration-workflows.md` — Session lifecycle, message formats
- `llm-system-definition.md` — System prompts, tool definitions

## Open Architecture Questions

1. **Ursa naming** — "Ursa" is Adi's codename, need exec decision on official name
2. **Trade Planning UI** — Integration approach for trading copilot TBD
3. **Morrison API** — Need spec for digital election submission
4. **Navexa integration** — Tax lot data for trading decisions (Phase 2)

---

## Workstream Tracking Guide

This section documents how to correlate workstream status across different information sources.

### Information Sources

| Source | Location | What It Tells Us |
|--------|----------|------------------|
| AI Agents | `/shared/state/agents/cto/children/*/report.md` | Technical progress, blockers, code status |
| Staff (Developers) | Jira, emails, standups | Implementation work, bug fixes, feature delivery |
| Staff (Ops) | Jira, monitoring, incidents | Production health, deployment status |
| Jira | xynon.atlassian.net | Tasks, sprints, bugs, feature requests |
| Emails | Mike inbox, team threads | Decisions, external dependencies, stakeholder feedback |
| Git/PRs | Bitbucket PRs | Code reviews, merge status, what shipped |
| Xynon docs | `Xynon/docs/cto-data/` | Vision docs, task tracking, agent prompts |

### Workstream → Source Mapping

| Workstream | Primary Agent | Key Staff | Jira Project/Label | External Deps |
|------------|---------------|-----------|-------------------|---------------|
| Trading & Registry | registry | Mike, Radek | — | — |
| Copilot | copilot | Adi (design) | — | — |
| Corporate Actions | corporate-actions | — | — | Wes (LSEG), Morrison |
| Portal Baseline | fees | Daniel + team (from Jira) | — | Business (pricing, tax) |
| Tech Standards | build-warnings | — | — | — |

### How to Update Status

When updating `report.md`, gather from:

1. **Check agent reports** — Read `children/*/report.md` for each active agent
2. **Check inbox** — Read `inbox/*.md` for messages from children or parent
3. **Ask about Jira** — If connected to sprints, ask Mike for current sprint status
4. **Ask about emails** — External dependencies often blocked on email threads
5. **Check PRs** — Recent merges indicate shipped work

### Correlation Pattern

```
Workstream status =
  Agent progress (unit tests, local dev)
  + Staff work (Jira tickets completed)
  + Environment progression (UAT, Prod deployment)
  + External dependencies (emails, decisions)
```

**Key insight:** Unit tests passing (agent work) ≠ Business readiness (requires UAT + stakeholder sign-off)

### Standing Questions to Ask

When gathering status, ask Mike:
1. "Any Jira updates on [workstream]?"
2. "Any email threads blocking [workstream]?"
3. "Which environment is [feature] deployed to?"
4. "Any stakeholder feedback on [workstream]?"
