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
