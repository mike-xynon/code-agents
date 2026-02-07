# Development Status Report

**Last Updated:** 2026-02-05

## Executive Summary

Technology is focused on five workstreams:
1. **Trading & Registry** — Core trading infrastructure and position truth
2. **Copilot** — AI assistant modes for mandates, models, and trading
3. **Corporate Actions** — Digitise elections (DRP, rights, buybacks, votes)
4. **Portal Baseline** — Unified client view (summaries, tax, options, billing)
5. **Tech Standards** — Logging, static analysis, security, code quality

Unit tests passing ≠ business readiness. Each workstream tracks progression through environments.

---

## Workstream 1: Trading & Registry

**Goal:** Reliable trading execution with accurate position truth

| Milestone | Unit Tests | Local | UAT | Prod Test | Real Accounts |
|-----------|------------|-------|-----|-----------|---------------|
| Registry API running | ✓ | ✓ | — | — | — |
| Migrations applied | ✓ | ✓ | — | — | — |
| Auth integration | ✓ | ✓ | — | — | — |
| Trade execution | 52/60 | — | — | — | — |
| Integration suite | 33/34 | ✓ | — | — | — |

**Current Status:** Local dev infrastructure complete. 33/34 integration tests passing.

**Known Issues:**
- 8 unit test failures (actual code bugs, not config)
- Container memory warning after ~20 requests (workaround: restart)
- Deposit allocation API has EF async bug

**Next:** Push to UAT environment, address code bugs

---

## Workstream 2: Copilot (AI Assistant)

**Goal:** AI assistant modes for mandates, models, and trading

| Mode | Purpose | Design | Code | Local | UAT | Prod |
|------|---------|--------|------|-------|-----|------|
| Ursa (Mandates) | Client mandate Q&A | ✓ | ✓ | ✓ | ✓ | ✓ |
| Models | Portfolio model analysis | — | — | — | — | — |
| Trading | Multi-portfolio trade execution | ✓ | ✓ | — | — | — |

**Current Status:**
- Ursa (mandates) live in production
- Trading mode: 8 tools implemented, wiring in progress
- Models mode: not started

**Trading Tools Implemented:**
- GetPortfolioDrift, GetGroupedDrift, GetTargetGroupAnalysis
- GetInstrumentSignals, UpdateInstrumentSignals
- GetTradePreview, SubmitTrades, GetTradeStatus

**Next:** Complete Trading mode wiring, begin Portal UI integration

---

## Workstream 3: Corporate Actions

**Goal:** Digitise corporate action elections (DRP, rights issues, buybacks, takeovers, votes)

| Milestone | Status | Notes |
|-----------|--------|-------|
| Data model design | ✓ | Interface hierarchy, JSON storage |
| LSEG evaluation | ✓ | Need DSS API, SDK is dead end |
| EF Core entities | — | Ready to implement |
| Ingestion service | — | Blocked on LSEG license |
| Manual entry MVP | — | Can proceed without LSEG |
| Election submission | — | Blocked on Morrison API capability |

**Current Status:** Design complete, blocked on external dependencies

**Blockers:**
- LSEG license confirmation (email drafted to Wes)
- Morrison election submission API capability unknown
- ASX ReferencePoint subscription check needed

**Next:** If LSEG blocked, implement manual entry MVP

---

## Workstream 4: Portal Baseline

**Goal:** Unified client view — summaries, tax, options, billing

| Capability | Design | Code | Local | UAT | Prod | Notes |
|------------|--------|------|-------|-----|------|-------|
| Equities summaries | ✓ | ✓ | ✓ | ✓ | ✓ | Live |
| Options display | — | — | — | — | — | Need data source |
| Tax reporting | — | — | — | — | — | Navexa decision |
| Billing | — | — | — | — | — | Need fee structure |

**Current Status:** Equities summaries live. Options, tax, billing blocked on decisions.

**Decisions Needed:**
1. Options data source integration approach
2. Tax approach — Navexa integration vs build
3. Fee structure (especially for options)
4. Which clients for UAT pilot

---

## Workstream 5: Tech Standards

**Goal:** Maintain baseline technical quality — logging, analysis, security

| Area | Status | Notes |
|------|--------|-------|
| Logging standards | — | Meeting logging, structured logs |
| Static analysis | In progress | CS8618 warnings (~1,123 remaining) |
| Security | — | Dependency scanning, secrets management |
| Build warnings | In progress | Patterns established, 57 files done |

**Current Status:** Build warnings work in progress. Other areas need definition.

**Build Warning Progress:**
| Project | Warnings | Status |
|---------|----------|--------|
| NQ.AssetModels | 0 | ✓ Complete |
| NQ.Facts.Model.Core | 0 | ✓ Complete |
| NQ.Trading.Models | 653 | In progress |
| NQ.Copilot | 290 | Not started |
| NQ.Hosting | 180 | Not started |

**Next:** Define logging standards, continue static analysis cleanup

---

## AI Agent Operations

Agents support the above workstreams:

| Agent | Workstream | Status |
|-------|------------|--------|
| registry | Trading & Registry | Active — Local dev complete |
| copilot | Copilot | Active — Trading mode in progress |
| corporate-actions | Corporate Actions | Design complete, blocked on LSEG |
| fees | Portal Baseline | New — Setting up |
| build-warnings | Tech Standards | Active — Static analysis in progress |

Infrastructure (agent-farm) is operational.

---

## Decisions Required

| Decision | Owner | Impact |
|----------|-------|--------|
| LSEG license | Wes | Corporate Actions implementation |
| Morrison election API | Mike | Corporate Actions submission |
| Options data source | Mike | Portal Baseline — options display |
| Tax approach | Mike | Portal Baseline — Navexa integration? |
| Fee structure | Business | Portal Baseline — billing |
| UAT pilot clients | Business | Portal Baseline — rollout |

---

## Change Log

### 2026-02-05
- Restructured report to strategic workstream format
- Workstream 4: Portal Baseline (summaries, tax, options, billing)
- Added Copilot workstream with all 3 modes (Ursa, Models, Trading)
- Restored Corporate Actions workstream with blocker details
- Created tracking guide in design.md for correlating workstreams with agents, staff, Jira, emails
- Key staff: Mike + Radek on Trading & Registry

### 2026-02-03
- Registry: 33/34 integration tests passing
- Copilot: 8 trading tools implemented
- Agent farm: Service port allocation added

### 2026-02-02
- Registry: PR #3 merged (local dev setup)
- Infrastructure: .NET 9 SDK, pre-auth, git improvements
