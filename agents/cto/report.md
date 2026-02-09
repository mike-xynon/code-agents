# Development Status Report

**Last Updated:** 2026-02-09

## Executive Summary

Technology is focused on six workstreams across 7 child agents. Key progress since last report: Registry tests now 60/60, Copilot API PR ready, Fees agent found production bug and verified end-to-end calculation, new Morrison-Ops agent initialized.

**Top Blockers:**
1. No UAT scenario document for Registry — blocks path to production
2. LSEG license (Wes) — blocks Corporate Actions implementation
3. Navexa options tax capability — unknown, blocks Portal Baseline completeness
4. Options fee structure decision — revenue at risk

---

## Workstream 1: Trading & Registry (P0)

**Goal:** Reliable trading execution with accurate position truth

| Milestone | Unit Tests | Local | UAT | Prod Test | Real Accounts |
|-----------|------------|-------|-----|-----------|---------------|
| Registry API running | ✓ | ✓ | — | — | — |
| Migrations applied | ✓ | ✓ | — | — | — |
| Auth integration | ✓ | ✓ | — | — | — |
| Trade execution | **60/60** | — | — | — | — |
| Integration suite | 33/34 | ✓ | — | — | — |

**Current Status:** All 60 unit tests passing (was 52/60). PR ready for `feature/order-update-workflow`.

**Changes Since Last Report:**
- Fixed all 8 remaining unit test failures (ConfigHelper Docker networking, settlement test setup, ANZ statement processing, order fulfilment workflow)
- 10 files changed, PR ready

**Known Issues:**
- Container memory warning after ~20 requests (workaround: restart)
- Deposit allocation API has EF async bug

**Next:** Define UAT scenario document, merge PR, push to UAT environment

---

## Workstream 2: Copilot (AI Assistant) (P2)

**Goal:** AI assistant modes for mandates, models, and trading

| Mode | Purpose | Design | Code | Local | UAT | Prod |
|------|---------|--------|------|-------|-----|------|
| Ursa (Mandates) | Client mandate Q&A | ✓ | ✓ | ✓ | ✓ | ✓ |
| Trading | Multi-portfolio trade execution | ✓ | ✓ | — | — | — |
| Models | Portfolio model analysis | — | — | — | — | — |

**Current Status:**
- Ursa (mandates) live in production
- Trading mode: API PR #369 ready for review (portal repo)
- UI PR #365 WIP

**Changes Since Last Report:**
- Redesigned from 8 granular tools → single `get_trading_overview` returning complete nested structure
- Local DTOs to avoid blocking on NQ.Copilot package publish
- Rebased onto latest master, builds clean

**Issue:** NuGet repo has uncommitted changes on main (copilot agent committed there by mistake — needs cleanup)

**Next:** Merge API PR, complete UI integration, publish NQ.Copilot package

---

## Workstream 3: Corporate Actions (P1)

**Goal:** Digitise corporate action elections (DRP, rights, buybacks, takeovers, votes)

| Milestone | Status | Notes |
|-----------|--------|-------|
| Data model design | ✓ | Interface hierarchy, JSON storage |
| LSEG evaluation | ✓ | Need DSS API, SDK is dead end |
| EF Core entities | — | Ready to implement |
| Ingestion service | — | Blocked on LSEG license |
| Manual entry MVP | — | Can proceed without LSEG |
| Election submission | — | Blocked on Morrison API capability |

**Current Status:** Design complete, blocked on external dependencies. No changes since 2026-02-05.

**Blockers:**
- LSEG license confirmation (email drafted to Wes — still waiting)
- Morrison election submission API capability unknown
- ASX ReferencePoint subscription check needed

**Recommendation:** If LSEG remains blocked, proceed with manual entry MVP

---

## Workstream 4: Portal Baseline (P0)

**Goal:** Unified client view — equities + options positions, transactions, tax

| Capability | Status | Notes |
|------------|--------|-------|
| Equities (holdings, txns, tax) | ✓ Live | Via Navexa for tax |
| Options holdings | Partial | Collateral table issues (XK-568) |
| Options transactions | In Progress | XK-833 building UI |
| Options valuations | Backlog | XK-516 pricing job needed |
| Options tax | **Unknown** | **Can Navexa do options tax?** |

**Key Question:** Does Navexa support options tax reporting? This determines whether Portal Baseline is near-complete or has a significant gap.

**Jira In Progress:** XK-833 (options txns UI), XK-832 (JNL categorization)

---

## Workstream 5: Options Billing & Fees (P1)

**Goal:** Correct fee configuration for options clients

**Changes Since Last Report (significant):**
- Fees agent completed sessions 7-9 with major progress
- Charge grouping by ServiceType implemented (only one frequency per ServiceType)
- Dependency validation working (Options Tax requires Tax Report)
- **Bug found:** `PortfolioChargeProvider.ChargesFor()` — null `offerPackage` breaks `.Concat()` chain, advice fees never included
- End-to-end fee calculation verified against database
- New production code: `EnsureMdaPremiumFees()`, `CalculateChargeRecordsFromHoldings()`
- **14/14 tests passing** (12 in-memory + 2 database integration)
- PR #175 on nq-nugetlibraries

**Verified Calculations:**
| Portfolio | Tax Report | Options Tax | Total |
|-----------|------------|-------------|-------|
| JR TAYLOR (1102155) | $75.95 | $19.73 | $95.67 |
| MARZOLI (1102917) | $88.60 | $23.01 | $111.62 |

**Decisions Needed:**
1. Is options trading a chargeable premium feature?
2. What fee structure applies to options clients?
3. Should the null offerPackage bug be fixed in production?

**Next:** Integrate charge grouping into `ChargesFor()` in `PortfolioChargeProvider`

---

## Workstream 6: Morrison Operations (NEW)

**Goal:** Business process improvement for Morrison Securities

| Workstream | Status | Blocker |
|------------|--------|---------|
| Customer Onboarding | Waiting | Need SJ's details on actual problems |
| CMM Visibility | Discovery | Need to identify data sources |

**Current Status:** Agent initialized 2026-02-07. Discovery phase, not a coding agent. Both sub-workstreams blocked on stakeholder input.

---

## Tech Standards

| Area | Status | Notes |
|------|--------|-------|
| Build warnings | In progress | 57 files done, ~1,123 CS8618 remaining |
| Logging standards | — | Not started |
| Security | — | Not started |

**Build Warning Progress:**
| Project | Warnings | Status |
|---------|----------|--------|
| NQ.AssetModels | 0 | ✓ Complete |
| NQ.Facts.Model.Core | 0 | ✓ Complete |
| NQ.Trading.Models | 653 | Next target |
| NQ.Copilot | 290 | Not started |
| NQ.Hosting | 180 | Not started |

---

## AI Agent Operations

| Agent | Workstream | Status | Last Active |
|-------|------------|--------|-------------|
| registry | Trading & Registry | 60/60 tests, PR ready | 2026-02-05 |
| copilot | Copilot | API PR #369 ready | 2026-02-05 |
| corporate-actions | Corporate Actions | Design complete, blocked | 2026-02-02 |
| fees | Options Billing | E2E verified, bug found | 2026-02-05 |
| morrison-ops | Morrison Operations | Initialized, discovery | 2026-02-07 |
| build-warnings | Tech Standards | In progress | 2026-02-03 |
| agent-farm | Infrastructure | Operational | 2026-02-08 |

Infrastructure (agent-farm) operational with manage-worker.sh CLI, per-agent activation, AWS integration.

---

## Decisions Required

| Decision | Owner | Impact | Urgency |
|----------|-------|--------|---------|
| UAT scenario document | Mike + Radek | Registry path to production | HIGH |
| LSEG license | Wes | Corporate Actions implementation | HIGH |
| Navexa options tax? | Mike/Navexa | Portal Baseline completeness | HIGH |
| Options fee structure | Mike/Product | Revenue — could be leaking | HIGH |
| Null offerPackage bug fix | Mike | Production fee accuracy | MEDIUM |
| Morrison election API | Mike | Corporate Actions submission | MEDIUM |
| NuGet repo cleanup | CTO | Copilot committed to main | LOW |

---

## Inbox Items Processed

| Message | Date | Status |
|---------|------|--------|
| mike-2026-02-03-1200 | 2026-02-03 | Reviewed — repo isolation changes look good |
| fees-2026-02-04-0430 | 2026-02-04 | Processed — test infrastructure complete |
| fees-update-2026-02-05 | 2026-02-05 | Processed — charge grouping + PR #175 |
| copilot-2026-02-05-0325 | 2026-02-05 | Processed — API PR #369 ready |
| registry-update-2026-02-05 | 2026-02-05 | Processed — 60/60 tests passing |
| fees-update-2026-02-05-b | 2026-02-05 | Processed — bug found in ChargesFor() |
| fees-update-2026-02-05-c | 2026-02-05 | Processed — E2E database integration verified |

---

## Change Log

### 2026-02-09
- Session startup: read all agent files, children reports, inbox
- Registry: upgraded to 60/60 unit tests (was 52/60)
- Copilot: API redesigned to single tool, PR #369 ready
- Fees: major progress — charge grouping, production bug found, E2E verified, 14/14 tests
- Morrison-Ops: new agent initialized (business process, not coding)
- Agent Farm: manage-worker.sh CLI, activation scripts added
- Updated decisions table with urgency ratings
- Processed 7 inbox messages

### 2026-02-05
- Restructured report to strategic workstream format
- Created workstream tracking documents
- Key staff: Mike + Radek on Trading & Registry

### 2026-02-03
- Registry: 33/34 integration tests passing
- Copilot: 8 trading tools implemented
- Agent farm: Service port allocation added
