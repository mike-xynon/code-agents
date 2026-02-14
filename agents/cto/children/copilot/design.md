# Trading Copilot - Design & Architecture

## Overview

The Trading Copilot provides AI-assisted analysis for bulk trading operations. It analyzes portfolios with pending trades, enriches them with market context (dividends, momentum, sector performance), and provides structured recommendations.

## System Architecture

```
SessionMode
├── Ursa (existing)       <- Single portfolio, Investor → mandate → model
└── Trading (new)         <- Multi-portfolio, Drift → grouping → execution
```

## Analysis Architecture

### Complete Analysis Flow

The trading analysis runs two separate LLM prompts in parallel, then validates tolerances:

```
                    ┌─────────────────────────────┐
                    │     Trading Overview        │
                    │  (portfolios + holdings +   │
                    │   tolerance% + variance%)   │
                    └─────────────┬───────────────┘
                                  │
              ┌───────────────────┴───────────────────┐
              ▼                                       ▼
┌─────────────────────────┐             ┌─────────────────────────┐
│   Portfolio Analysis    │             │  Momentum Analysis      │
│  (batch by portfolios)  │             │  (by exchange/sector)   │
│                         │             │                         │
│  - Dividend timing      │             │  - Exchange comparison  │
│  - Trade flags          │             │  - Sector vs exchange   │
│  - Proceed/defer/review │             │  - Instrument vs sector │
└───────────┬─────────────┘             └───────────┬─────────────┘
            │                                       │
            │         ┌───────────────────┐         │
            └────────►│    Synthesis      │◄────────┘
                      │  + Attach Context │
                      └─────────┬─────────┘
                                │
                    ┌───────────▼───────────┐
                    │ Tolerance Validation  │
                    │  (soft check - flags) │
                    │                       │
                    │ • Flag defer→breach   │
                    │ • Suggest partials    │
                    └───────────┬───────────┘
                                ▼
                    ┌─────────────────────────────┐
                    │   Final Recommendations     │
                    │  + Market Context + Flags   │
                    └─────────────────────────────┘
```

### Why Separate Prompts?

1. **Portfolio analysis** focuses on trade-level decisions (proceed, defer, review) based on flags
2. **Momentum analysis** provides market context without influencing trade decisions
3. **Separation prevents hallucination** - the portfolio prompt doesn't see momentum data, so it can't invent momentum reasons for deferrals
4. **Parallel execution** reduces total latency
5. **Synthesis merges both** - momentum context is passed TO synthesis, so the executive summary includes market trends

## TOON Format (Token-Optimized Output Notation)

Portfolio and momentum data is encoded in a compact format to minimize LLM token usage while preserving clarity.

### Portfolio Batch Format

```
=== BATCH 1 OF 3 ===

--- Portfolio: ABC123 (John Smith) ---
Model: Conservative Growth
Holdings{sym,curr%,tgt%,diff%,trade$,flags}:
CBA,8.5,6.0,1.5,-4147,div:8d/$2.40
BHP,5.2,4.0,1.0,-2500,sec:Materials
WBC,3.1,3.0,0.5,-800
```

Format details:
- `Holdings{columns}:` declares the column schema
- Each line is CSV with values in column order
- Flags at end are optional, comma-separated within the field
- Common flags: `div:Nd/$X.XX` (dividend), `dip:-N%` (price dip), `cgt:Nd` (CGT threshold)

### Momentum Analysis Format

Three-level hierarchy: Exchange → Sector → Instrument

```
=== EXCHANGE SUMMARY ===
Exchanges{code,12mo%,6mo%,1mo%}:
ASX,+9%,+5%,+1%
NYSE,+12%,+7%,+2%
LSE,+6%,+3%,0%

=== ASX SECTORS (exchange: 12mo +9%, 6mo +5%, 1mo +1%) ===
Sectors{name,12mo%,6mo%,1mo%,vsExch1mo%}:
Financials,+8%,+4%,+1%,0%
Materials,+12%,+8%,+3%,+2%
Healthcare,+5%,+2%,-1%,-2%

=== ASX FINANCIALS (sector: 12mo +8%, 1mo +1% | exch: 1mo +1%) ===
Instruments{sym,12mo%,6mo%,1mo%,vsSec1mo%,exdiv,sells#,buys#}:
CBA,-2%,+3%,-4%,-5%,8d,12,0
WBC,+4%,+2%,+1%,0%,,8,0
NAB,+6%,+3%,+2%,+1%,,5,2
```

This format gives the LLM full market context:
- Compare exchanges globally
- Compare sectors within each exchange
- Compare instruments within each sector
- See pending trade volume (sells#, buys#)

## LLM Prompt Design

### Portfolio Analysis Prompt

Key principles:
- **Default to PROCEED** - most trades should execute
- **Only defer when explicit flags present** - prevents hallucination
- **Output JSON** for reliable parsing

```
## CRITICAL: Only Use Flags Present in the Data
Each holding line shows flags at the end. Examples:
- `CBA,8.5,6.0,1.5,-4147,div:8d/$2.40` - HAS dividend flag
- `BHP,5.2,4.0,1.0,-2500,sec:Materials` - NO dividend flag

**DO NOT assume flags exist if they are not shown.**
```

### Momentum Analysis Prompt

Key principles:
- **Avoid naive interpretations** - underperformance isn't inherently bad
- **Describe trajectory** - improving/deteriorating, not just current state
- **No judgments** - "lagging sector" is neutral, adviser decides if opportunity or risk

```
## IMPORTANT: Avoid Naive Interpretations
- Underperformance is NOT inherently bad. A stock down on news may have that news priced in.
- Recent weakness after strong 12mo could be healthy consolidation.
- Consider the TRAJECTORY: improving (bad→better) vs deteriorating (good→worse).

AVOID: "worst performer" (judgmental)
PREFER: "lagging sector by X% this month", "momentum improving from -8% to -2%"
```

## Progress Streaming (SSE)

The analysis endpoint streams progress updates via Server-Sent Events:

```
GET /api/trading-copilot/analyze-sells/stream
Accept: text/event-stream
```

Events:
```json
data: {"type":"progress","stage":"analyzing","message":"Analyzing batch 1 of 3...","currentStep":1,"totalSteps":5,"batchNumber":1,"totalBatches":3}

data: {"type":"progress","stage":"synthesizing","message":"Synthesizing recommendations...","currentStep":4,"totalSteps":5}

data: {"type":"result","data":{...final result...}}
```

Frontend uses `useAISellsAnalysis` hook which:
1. Opens SSE connection
2. Updates progress state on each event
3. Returns final result when complete

## Data Model

### Response Structure

```typescript
interface AISellsAnalysisResponse {
  success: boolean;
  analysis?: string;              // Executive summary
  recommendations?: SellAnalysisResult;
  exchangeComments?: MarketComment[];      // Exchange-level context
  sectorComments?: SectorMarketComment[];  // Sector-level context
}

interface BulkSellRecommendation {
  instrumentCode: string;
  action: 'Proceed' | 'Defer' | 'Review';
  reason: string;
  totalValue: number;
  portfolioCount: number;
  flags?: string[];
  momentumNote?: string;  // LLM-generated context comment
}

interface MarketComment {
  exchange: string;
  comment: string;
  crossExchangeInsight?: string;
}

interface SectorMarketComment {
  exchange: string;
  sector: string;
  comment: string;
  exchangeContext?: string;
  crossExchangeInsight?: string;
}
```

## Trade DTOs Reference

Two DTO files define trade-related types. When adding new trade DTOs, check these first.

### Trade Planning DTOs (`TradePlanningDtos.cs`)

Older trade planning system with session-based workflow.

| Class | Key Fields | Purpose |
|-------|------------|---------|
| `ProposedTradeDto` | InstrumentId, Symbol, Action, Quantity, EstimatedValue | Individual proposed trade |
| `TradeCalculationResultDto` | List\<ProposedTradeDto\>, Analysis | Trade calculation result |
| `TradePlanningSessionDto` | SessionId, Portfolios, ModelAdjustments | Session with filtered portfolios |
| `PortfolioLevelAnalysisDto` | TotalBuyValue, TotalSellValue, NetCashMovement | Portfolio aggregation |
| `TradeExecutionStatusDto` | FilledQuantity, AveragePrice, Status | Execution result |
| `UpdateSessionModelAdjustmentsRequestDto` | Constraints, Substitutions, ExitStrategies | Session-specific overrides |
| `SessionInstrumentConstraintDto` | InstrumentId, Symbol, DoNotBuy, DoNotSell, Hold | Per-instrument trading rules |
| `GradualExitStrategyDto` | InstrumentId, CurrentQuantity, TargetQuantity, MaxSellPercent | Illiquid position exit plan |

### Trading Copilot DTOs (`TradingCopilotDtos.cs`)

Trading Copilot uses flatter structures optimized for UI binding.

| Class | Key Fields | Purpose |
|-------|------------|---------|
| `HoldingActual` | InstrumentCode, Action, Amount, MinAmount, MaxAmount | Single holding with trade |
| `PortfolioActuals` | PortfolioId, Holdings, PendingWithdrawal | Portfolio with all holdings |
| `ExecutionPlan` | Portfolios, Totals, InstrumentSummaries | Complete execution plan |
| `ExecutionTotals` | SellValue, BuyValue, NetCashFlow, TradeCount | Aggregate totals |
| `InstrumentSummary` | InstrumentCode, TotalSellValue, TotalBuyValue | Cross-portfolio aggregation |
| `BuyReductionSummary` | TotalOriginalBuys, TotalReducedBuys, CashPreserved | Buy reduction tracking |

### Key Differences

| Aspect | TradePlanningDtos | TradingCopilotDtos |
|--------|-------------------|---------------------|
| Instrument ID | `InstrumentId` (Guid) | `InstrumentCode` (string) |
| Trade amount | `Quantity` + `EstimatedValue` | `Amount` (single value) |
| Range constraints | Not present | `MinAmount`, `MaxAmount` |
| Deferral tracking | Via `Status` field | `IsDeferred`, `DeferReason` |
| Event context | Not present | `Categories[]` for events |

## Key Files

### Backend (C#)

| File | Purpose |
|------|---------|
| `nuget:NQ.Copilot/Services/Trading/TradingAnalysisOrchestrator.cs` | Main orchestration - parallel analysis, synthesis |
| `nuget:NQ.Copilot/Services/Trading/TradingFormatter.cs` | TOON format output for batches and momentum |
| `nuget:NQ.Copilot/Services/Trading/TradingPrompts.cs` | LLM prompts for batch and momentum analysis |
| `nuget:NQ.Copilot/Services/Trading/TradingResponseParser.cs` | JSON extraction and parsing |
| `nuget:NQ.Copilot/Services/Trading/TradingBatcher.cs` | Split portfolios into batches |
| `nuget:NQ.Copilot/Services/Trading/TradingAggregator.cs` | Aggregate by instrument/portfolio/model |
| `nuget:NQ.Copilot/Services/Trading/MomentumAnalysis.cs` | Types for momentum hierarchy |
| `nuget:NQ.Copilot/Tools/Trading/ToleranceValidationTools.cs` | Tolerance validation (soft checks) |
| `nuget:NQ.Copilot/Tools/Trading/TradingAnalysisTools.cs` | Main analysis tool with progress streaming |
| `portal:Tmw.Api/Services/Portfolio/AISellsAnalysisService.cs` | API service, conversion to UI types |
| `portal:Tmw.Api/Services/Portfolio/TradingCopilotDataProvider.cs` | Data enrichment (dividends, momentum) |
| `portal:Tmw.Api/Controllers/TradingCopilotController.cs` | SSE streaming endpoint |

### Frontend (TypeScript)

| File | Purpose |
|------|---------|
| `pwa:hooks/useAISellsAnalysis.ts` | SSE streaming hook with progress |
| `pwa:AISellsAnalysisTab.view.tsx` | Analysis UI with progress indicator |
| `pwa:AISellsAnalysis.types.ts` | TypeScript interfaces |

## Design Decisions

### 1. Separate Momentum Analysis
- **Decision:** Run momentum analysis in separate LLM call, not mixed with portfolio analysis
- **Rationale:** Prevents LLM from inventing momentum-based deferrals; keeps portfolio decisions flag-driven
- **Trade-off:** Extra LLM call, but runs in parallel so no latency cost

### 2. TOON Format Over JSON
- **Decision:** Use compact text format instead of JSON for LLM input
- **Rationale:** ~60% fewer tokens, clearer structure for LLM understanding
- **Trade-off:** Custom parsing needed, but output is still JSON for reliability

### 3. Flag-Driven Deferrals
- **Decision:** Only defer when explicit flags (div:, dip:, cgt:) are present
- **Rationale:** Prevents LLM hallucination of reasons; makes behavior predictable
- **Trade-off:** May miss edge cases, but adviser can override

### 4. Three Exchange Coverage
- **Decision:** Include all 3 exchanges (ASX, NYSE, LSE) in momentum analysis
- **Rationale:** Full international context for advisers managing global portfolios
- **Trade-off:** More tokens, but valuable cross-market insights

## Tolerance Validation Pattern

### Why Tolerance Matters

Model tolerances define acceptable drift bands (e.g., ±2% from target). When the AI recommends deferring a sell, it may leave a holding outside its tolerance band. This isn't an error - it's a **concern to surface**.

### Soft Check vs Hard Failure

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Validation Hierarchy                            │
├─────────────────────────────────────────────────────────────────────┤
│  HARD FAILURE (block)     │ Compliance violation - cannot proceed   │
│  SOFT WARNING (surface)   │ Tolerance breach - note and proceed     │
│  ADVISORY (inform)        │ Momentum concern - context only         │
└─────────────────────────────────────────────────────────────────────┘
```

Tolerance breaches are **soft warnings**, not hard failures:
- The AI notes the variance and factors it into recommendations
- Concerns are surfaced to the trader as flags
- The trade can still proceed - trader makes final call

### Orchestration: Post-Recommendation Validation

After the AI generates recommendations, we validate against tolerances:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Full Analysis Flow                               │
└─────────────────────────────────────────────────────────────────────┘

1. Get Trading Overview (portfolios, holdings, drift data)
   └── Each holding has: actual%, target%, tolerance%, variance%

2. Parallel Analysis
   ├── Portfolio Analysis → recommendations (proceed/defer/partial)
   └── Momentum Analysis → market context

3. Synthesis → merged recommendations + executive summary

4. Tolerance Validation ← NEW STEP
   │
   └── For each recommendation:
       ├── If "defer": Would deferring leave holding outside tolerance?
       ├── If "partial": Would partial trade meet tolerance?
       └── Flag breaches but DON'T block

5. Return recommendations with tolerance flags
```

### AI Decision Framework

The AI should consider tolerance when making recommendations:

```
Example: CBA at 8.5%, target 6.0%, tolerance ±2%
         Current variance: +2.5% (OUTSIDE tolerance)
         Dividend in 8 days: $2.40/share

┌─────────────────────────────────────────────────────────────────────┐
│  AI Analysis                                                        │
├─────────────────────────────────────────────────────────────────────┤
│  Factor 1: Dividend approaching → prefer defer                      │
│  Factor 2: Outside tolerance → should trade                         │
│  Factor 3: Momentum lagging sector (-4%) → no urgency               │
├─────────────────────────────────────────────────────────────────────┤
│  Decision Options:                                                  │
│  a) DEFER - capture dividend, note tolerance concern                │
│  b) PARTIAL - sell 50% now to meet tolerance, defer rest for div    │
│  c) PROCEED - full sell, accept dividend loss                       │
├─────────────────────────────────────────────────────────────────────┤
│  Recommendation: PARTIAL 60%                                        │
│  Reason: Sell enough to bring within tolerance (need to reduce by   │
│          0.5% to hit edge of tolerance band), defer 40% for dividend│
└─────────────────────────────────────────────────────────────────────┘
```

### Partial Trades for Tolerance

When a full defer would breach tolerance, the AI can recommend a partial trade:

```typescript
interface InstrumentRecommendation {
  symbol: string;
  action: 'proceed' | 'defer' | 'partial' | 'review';
  proceedPercent?: number;  // For partial: what % to execute now
  reason: string;
  flags: string[];          // Includes "tolerance_concern" if relevant
}
```

Example output:
```json
{
  "symbol": "CBA",
  "action": "partial",
  "proceedPercent": 60,
  "reason": "Partial sell to meet tolerance; defer 40% for dividend capture in 8 days",
  "flags": ["dividend_approaching", "tolerance_concern"]
}
```

### Tolerance Validation Tools

Two tools support this pattern:

**`get_tolerance_status`** - Call BEFORE analysis to understand baseline:
```
→ Shows which holdings are already outside tolerance
→ Helps AI understand constraints before making recommendations
```

**`validate_recommendations`** - Call AFTER generating recommendations:
```
→ Checks if recommendations would breach tolerances
→ Returns violations as warnings, not errors
→ AI can revise (e.g., change defer→partial) or accept with warning
```

### Display in UI

Tolerance concerns appear as flags on recommendations:

```
┌─────────────────────────────────────────────────────────────────────┐
│ CBA  DEFER → PARTIAL 60%                                            │
│ Total: $24,500 across 12 portfolios                                 │
│                                                                     │
│ ⚠️ Tolerance: Deferring full amount leaves 3 portfolios outside    │
│    tolerance. Recommended partial sell brings within band.          │
│                                                                     │
│ 📈 Dividend: $2.40/share ex-div in 8 days (~$840 captured)          │
│ 📉 Momentum: Lagging sector -4% (trajectory improving)              │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Never block on tolerance** - it's advisory, not compliance
2. **Surface concerns clearly** - trader should know the trade-off
3. **Consider partial trades** - often the right balance between timing and tolerance
4. **Factor in momentum** - if momentum is poor, tolerance concern is less urgent
5. **Highlight substitution** - if deferring CBA, can we sell more NAB instead?

## Workflow Modes

Three workflow modes determine how trades are planned:

| Mode | AI Analysis | Sell Handling | Buy Handling |
|------|-------------|---------------|--------------|
| `QuickRebalance` | None | Execute all | Execute all |
| `Manual` | None | User controls | User controls |
| `AiPlan` | Full LLM | AI recommends deferrals | AI optimizes reductions |

### AiPlan Mode

When AiPlan is selected via `PUT /workflow-mode`:
1. Auto-selects all portfolios with pending trades
2. Runs `AnalyzeAsync()` to generate LLM recommendations
3. Stores synthesis for use in execution plan generation
4. Applies recommendations to sells immediately

## Buy Workflow

### Multi-Phase Planning (Sells → Buys)

The AiPlan workflow chains sell decisions into buy planning:

```
Sells Phase                           Buys Phase
┌─────────────┐                      ┌─────────────┐
│ AiPlan      │──── /advance-phase ───>│ AiPlan      │
│ Mode        │                      │ Mode        │
├─────────────┤                      ├─────────────┤
│ Sells/Holds │                      │ Reduced     │
│ Deferrals   │  ➝ Preserve All ➝    │ Buys based  │
│             │                      │ on cash     │
└─────────────┘                      └─────────────┘
```

### Buy Phase Flow (AI Mode)

The buy phase follows a clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 1: CALCULATE DRIFT & TRADE AMOUNTS (Algorithm)                │
│                                                                     │
│   • Calculate portfolio drift vs model targets                      │
│   • Determine buy amounts needed per holding                        │
│   • Preserve all sell decisions from previous phase                 │
│   • Output: Original buy amounts (before any reduction)             │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 2: CALCULATE DEFERRAL BUDGET (Algorithm)                      │
│                                                                     │
│   • Available Cash = Sell Proceeds − Pending Withdrawals            │
│   • Total Buy Demand = Sum of all buy amounts                       │
│   • Deferral Needed = Buy Demand − Available Cash                   │
│   • Format data for LLM (TOON format with dividends, momentum)      │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 3: DECIDE WHICH BUYS TO REDUCE (LLM)                          │
│                                                                     │
│   LLM receives:                                                     │
│   • Portfolio context (value, model, cash available)                │
│   • Deferral budget (how much total must be deferred)               │
│   • Per-instrument data (amount, weights, ex-div, momentum)         │
│                                                                     │
│   LLM decides:                                                      │
│   • WHICH positions to defer (based on dividends, momentum, gaps)   │
│   • HOW MUCH to defer per position (proceed/partial/defer)          │
│   • WHY each decision was made (reason text)                        │
│                                                                     │
│   LLM does NOT do math - just picks positions and percentages       │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 4: APPLY LLM DECISIONS (Algorithm)                            │
│                                                                     │
│   • Apply proceed/partial/defer to each holding                     │
│   • Calculate final amounts from LLM percentages                    │
│   • Validate total deferred meets budget                            │
│   • Scale if needed to hit exact cash constraint                    │
│   • Set DeferReason on each affected holding                        │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 5: GENERATE UNIFIED SUMMARY (LLM)                             │
│                                                                     │
│   Synthesizes complete trading picture:                             │
│   • Sells phase results (approved, deferred, reasons)               │
│   • Buys phase results (proceeding, reduced, deferred)              │
│   • Market context (momentum, sector trends)                        │
│   • Net cash flow and overall impact                                │
│   • Key events (dividends captured, CGT optimization)               │
│                                                                     │
│   Output: Executive summary for display in AI Assistant panel       │
└─────────────────────────────────────────────────────────────────────┘
```

### API Endpoint: Advance Phase

`POST /api/trading-copilot/sessions/{sessionId}/advance-phase`

Transitions between workflow phases (Sells → Buys → Review):
1. **Calculate drift and trades**: Determines buy amounts from model targets (no reduction yet)
2. **Preserve sell decisions**: All sells and deferrals from previous phase are retained
3. **Calculate deferral budget**: How much total buy value must be reduced
4. **LLM decides reductions**: Which specific buys to defer based on market context
5. **Apply decisions**: Algorithm applies LLM recommendations to holdings
6. **Generate summary**: Creates unified executive summary combining both phases

**Response:**
```typescript
interface AdvancePhaseResponse {
  currentPhase: WorkflowPhase;
  actuals: ExecutionPlan;
  buyReductionSummary?: BuyReductionSummary;  // Present when transitioning to Buys
  executiveSummary?: string;  // Unified summary combining sells + buys + market context
}
```

### Phase Transition: Preserving Sell Decisions

**Critical**: When advancing from Sells → Buys phase, all sell-related decisions must be preserved.

The `GenerateBuyExecutionPlan` function handles this:

```csharp
// Preserves: actual sells, deferred sells (now holds), and any holds with defer reasons
var existingSellsAndDeferred = currentActuals?.Portfolios
    .SelectMany(p => p.Holdings
        .Where(h => h.Action == TradeAction.Sell
                 || h.IsDeferred
                 || !string.IsNullOrEmpty(h.DeferReason))
        .Select(h => (PortfolioId: p.PortfolioId, Holding: h)))
    .GroupBy(x => x.PortfolioId)
    .ToDictionary(g => g.Key, g => g.Select(x => x.Holding).ToList());
```

This preserves:
1. **Actual sells** (`Action == TradeAction.Sell`) - Proceeds with sale
2. **Deferred sells** (`IsDeferred == true`) - Originally sell, now held
3. **Holds with reasons** (`DeferReason != null`) - AI decided not to sell, with explanation

When building the buy plan:
```csharp
// Start with existing sells and deferred holdings (preserve from previous phase)
var holdings = existingSellsAndDeferred.GetValueOrDefault(p.PortfolioId, []).ToList();
var preservedInstruments = holdings.Select(h => h.InstrumentCode).ToHashSet();

// Add buys and holds for instruments NOT already preserved from sells phase
foreach (var h in p.Holdings.Where(h => !preservedInstruments.Contains(h.InstrumentCode)))
{
    // ... add buy or hold as appropriate
}
```

This ensures:
- Sell decisions survive the phase transition
- Defer reasons are visible in the Buy phase UI
- No duplication of holdings in the execution plan

### Available Cash Formula

```
AvailableCashForBuys = CurrentCash + ApprovedSellValue - PendingWithdrawal
```

Where:
- `CurrentCash`: Portfolio's existing cash balance (estimated as 2% of portfolio value)
- `ApprovedSellValue`: Sum of non-deferred sells from finalized sell plan
- `PendingWithdrawal`: Cash draw requirement that must be funded first

### Tiered Buy Reduction Algorithm (Non-AI / Fallback)

Used in Manual/QuickRebalance modes, or as fallback if LLM analysis fails.

When buy amounts exceed available cash, reduces buys using tiered proportional reduction.
**Rationale**: Prioritizes completing positions closest to model targets while scaling back positions that are further behind.

| Tier | Model Progress | Max Reduction | Priority |
|------|----------------|---------------|----------|
| 1    | 80-100% of target | 30% | Last to reduce |
| 2    | 50-80% of target | 50% | Moderate |
| 3    | <50% of target | 80% | First to reduce |

**Example:**
```
Portfolio with $50,000 available cash, $80,000 in pending buys:

Holding A: 90% to target → Tier 1, reduce max 30%
Holding B: 70% to target → Tier 2, reduce max 50%
Holding C: 40% to target → Tier 3, reduce max 80%

Algorithm reduces Tier 3 first, then Tier 2, then Tier 1
until total buys = available cash
```

### LLM Buy Analysis (AiPlan Mode)

In AiPlan mode, LLM decides buy deferrals (tiered algorithm is fallback only):

```
Advance Phase (Sells → Buys)
    │
    ├── 1. Calculate drift and original buy amounts (NO reduction yet)
    │   └── GenerateBuyExecutionPlan(skipAlgorithmicReduction: true)
    │
    ├── 2. Build LLM inputs with ORIGINAL amounts:
    │   ├── Available cash = Sell proceeds - Pending withdrawal
    │   ├── Total buy demand (original, unreduced)
    │   ├── Deferral needed = demand - cash (if positive)
    │   └── Per-instrument: symbol, ORIGINAL amount, weight gap, ex-div, momentum
    │
    ├── 3. LLM decides which buys to reduce:
    │   └── TradingAnalysisOrchestrator.AnalyzeBuysAsync()
    │       • Sees actual deferral budget
    │       • Picks WHICH positions based on dividends, momentum
    │       • Does NOT do math - just picks and explains
    │
    ├── 4. Algorithm applies LLM decisions:
    │   └── ApplyBuyRecommendations()
    │       ├── "proceed" → keep full amount
    │       ├── "partial" → apply proceedPercent% to original
    │       └── "defer" → set amount to 0, mark IsDeferred
    │
    ├── 5. Generate unified summary (combines sells + buys + market)
    │
    └── FALLBACK: If LLM returns null, use tiered algorithmic reduction
```

**Key principle**: Algorithm handles MATH (calculating amounts, applying percentages).
LLM handles JUDGMENT (which positions to defer, why).

**LLM Buy Deferral Priorities:**
1. **Dividends nearby** - Prefer deferring buys just before ex-div to capture yield
2. **Buying dips** - Favor proceeding on instruments with good long-term momentum but recent weakness
3. **Spread deferrals** - Avoid deferring exactly one instrument (concentration risk)

**Input Format (TOON):**
```
=== BUY ANALYSIS ===
Portfolio: ABC123 (John Smith)
Model: Conservative Growth | Value: $500,000
Cash available: $25,000 | Buy demand: $40,000 | Deferral needed: $15,000

Buys{sym,amount,currW%,tgtW%,gap%,exdiv,ret1mo,ret6mo}:
CBA,8500,2.1,4.0,1.9,8d,-3%,+8%
BHP,12000,1.5,4.0,2.5,,-5%,+12%
WBC,6000,3.2,4.0,0.8,15d,-1%,+6%
```

**Output Format:**
```json
{
  "portfolios": [{
    "accountNumber": "ABC123",
    "availableCash": 25000,
    "totalBuyDemand": 40000,
    "deferralNeeded": 15000,
    "summary": "Defer BHP fully, proceed with CBA and WBC to capture upcoming dividends",
    "recommendations": [
      {"symbol": "CBA", "action": "proceed", "amount": 8500, "reason": "Dividend capture in 8 days"},
      {"symbol": "BHP", "action": "defer", "amount": 0, "originalAmount": 12000, "reason": "No imminent catalyst, defer to preserve cash"},
      {"symbol": "WBC", "action": "proceed", "amount": 6000, "reason": "Dividend in 15 days, reasonable momentum"}
    ],
    "validation": {
      "totalProceeding": 14500,
      "totalDeferred": 12000,
      "withinBudget": true
    }
  }]
}
```

### Unified Executive Summary (Step 5)

After applying buy decisions, generates a combined summary for display in the AI Assistant panel.

**Purpose**: Provide a single cohesive narrative that covers the entire trading session - sells, buys, market context, and impact.

**Content includes:**
- **Trading Plan Overview**: Portfolio count, workflow mode
- **Sells Phase Summary**: Count, total value, deferrals with reasons
- **Buys Phase Summary**: Original demand, proceeding, deferred, reduction strategy
- **Net Cash Flow**: Total sells minus total buys
- **Market Context**: Momentum insights, sector trends (from synthesis)
- **Key Events**: Dividends captured, CGT optimization applied

**Example Output:**
```markdown
**Trading Plan: 60 Portfolios**

**Sells Phase (Complete):** 403 sells totaling $18,664,713
• 16 positions deferred (dividend timing, CGT optimization)

**Buys Phase (Current):** 148 buys totaling $5,226,061
• Original buy demand: $6,500,000
• Proceeding: $5,226,061
• Deferred: $1,273,939 (19.6%)
• Strategy: AI-optimized - prioritizes dividends, buys dips

**Net Cash Flow:** $13,438,651 (net seller)

**Market Context:** Mixed global momentum with NYSE leading (+5% 1mo)
vs ASX/NASDAQ (+1%). Materials sector showing strength.
```

**Implementation**: `GenerateUnifiedSummary()` in TradingCopilotController assembles this from session state and synthesis data.

**Future Enhancement**: Could use LLM to generate more natural prose summary instead of structured format.

### Session State

```typescript
interface TradingSession {
  // ... existing fields
  currentPhase: WorkflowPhase;       // Sells | Buys | Review
  buyReductionSummary?: BuyReductionSummary;  // Set after advancing to Buys
}

// Lean DTO - no SellPlanResult needed, compute from existing actuals
interface BuyReductionSummary {
  totalOriginalBuys: number;
  totalReducedBuys: number;
  cashPreserved: number;
  overallReductionPercent: number;
  strategy: string;
}
```

## Open Questions

1. **Momentum Data Source** - Currently using CategoryData.Momentum which may be null; need reliable source
2. **Caching** - Should momentum analysis be cached within a session?
3. **Partial Results** - How to handle if momentum analysis fails but portfolio analysis succeeds?
4. **Tolerance Aggregation** - When same symbol appears in multiple portfolios with different tolerances, how to aggregate?
5. **Buy Reduction Display** - How should the UI display the reduction summary and per-holding reductions?

---

## Test Data Design

### Mock Portfolio Composition

The mock portfolios (`MockData/mock-portfolios.json`) are structured into three types to exercise different trading scenarios. This data will eventually become formal test fixtures.

| Type | Count | Cash Level | Withdrawal | Expected Trades |
|------|-------|------------|------------|-----------------|
| **Accumulation** | ~20 | High (target + 10-15%) | None | Predominantly buys |
| **Withdrawal** | ~20 | Low (1.5-3%) | $85K-$417K | Predominantly sells |
| **Rebalance** | ~20 | Near target | None | Internal rebalancing |

#### Accumulation Portfolios (ACC100001-ACC100020)

Simulate accounts receiving deposits or with excess cash build-up:
- Cash significantly exceeds model target (e.g., 32% for Balanced Income with 18% target)
- No pending withdrawal
- Holdings are underweight due to cash dilution → triggers buys
- Tests buy workflow and LLM buy deferral decisions

Example: `ACC100002` - Balanced Income model, 32% cash (18% target), no withdrawal → strong buy candidates

#### Withdrawal Portfolios (ACC100021-ACC100040)

Simulate accounts funding distributions or pension payments:
- Minimal cash (1.5-3%)
- Large pending withdrawal ($85K-$417K)
- Must sell holdings to fund withdrawal → triggers sells
- Tests sell workflow and AI deferral logic (dividend capture, momentum)

Example: `ACC100028` - Growth Leaders model, 1.5% cash, $417K withdrawal → significant sells required

#### Rebalance Portfolios (ACC100041-ACC100060)

Simulate normal drift without external cash flows:
- Cash approximately matches model target
- No pending withdrawal
- Holdings have varied from model weights → internal rebalancing
- Tests both buy and sell generation for model alignment

Example: `ACC100045` - Conservative Core model, 12% cash (12.5% target), no withdrawal → sells fund buys internally

### Model Target Cash Percentages

Each model includes a target cash allocation. This is critical for understanding trade generation.

| Model | Target Cash % |
|-------|---------------|
| Balanced Income | 18% |
| Growth Leaders | 20% |
| Conservative Core | 12.5% |
| Concentrated Value | 10% |
| Diversified Sectors | 22% |
| High Growth Tilt | 23% |

### Weight Calculation and Trade Generation

The actual weight of each holding is calculated relative to **investable value**:

```
investableValue = portfolioTotalValue - pendingWithdrawal
actualWeight = (holdingValue / investableValue) * 100
variance = actualWeight - targetWeight
```

**Key implications:**

1. **Withdrawal reduces investable base** - A $500K portfolio with $100K withdrawal has $400K investable. A $40K holding becomes 10% (not 8%), triggering different trades.

2. **High cash → underweight holdings** - When cash exceeds model target, non-cash holdings are proportionally underweight, triggering buys.

3. **Trade triggers based on variance vs tolerance:**
   - `variance > tolerance` (overweight) → **Sell**
   - `variance < -tolerance` (underweight) → **Buy**
   - `|variance| <= tolerance` → **Hold**

**Example:**
```
Portfolio: $500,000 total, $50,000 pending withdrawal
Model: Conservative Core (12.5% cash target, 2% tolerance)

Investable: $450,000
Current Cash: $45,000 (10% of investable)
Target Cash: $56,250 (12.5% of $450K)

Holding CBA: $36,000 → 8.0% actual
CBA Target: 6.0%
CBA Variance: +2.0% (at tolerance edge)

→ CBA may sell to fund cash shortfall and withdrawal
```

This design ensures the mock data produces realistic trade distributions for testing all workflow paths.

---

## Post-Demo: System Unification

### Current State: Two Parallel Systems

The codebase has two trading session systems that need unification:

| Aspect | TradePlanningController | TradingCopilotController |
|--------|------------------------|-------------------------|
| **Purpose** | 4-step wizard workflow | AI-assisted trading |
| **Session store** | Redis (`RedisTradePlanningStore`) | In-memory (`Sessions` dictionary) |
| **Trade type** | `ProposedTradeDto` (Guid IDs) | `HoldingActual` (string codes) |
| **OMS integration** | Full (`IMorrisonProxy.CreateOrdersBatchAsync`) | None (demo only) |
| **Execution tracking** | `TradeExecutionStatusDto` | Not implemented |

### OMS Execution Path (The Truth)

The actual order submission flows through Morrison OMS:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        EXECUTION PIPELINE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  TradePlanningService.ExecuteTradesAsync()                             │
│  ├── Filter approved trades from session                                │
│  ├── Group by PortfolioId                                               │
│  ├── Build BatchOrderCreationRequest                                    │
│  │   └── PortfolioOrderRequest[]                                        │
│  │       └── TradeDecisionRequest[]                                     │
│  │           ├── InstrumentKey (Guid)                                   │
│  │           ├── Decision = Trade                                       │
│  │           ├── ExpectedQuantity                                       │
│  │           └── TradeSide (Buy/Sell)                                   │
│  │                                                                      │
│  ├── IMorrisonProxy.CreateOrdersBatchAsync(request)                    │
│  │   POST /api/rebalancing/orders/batch                                │
│  │                                                                      │
│  ├── BatchOrderCreationResult                                          │
│  │   └── OrderCreationResult[] (one per portfolio)                     │
│  │       ├── OrderKey (Guid)                                           │
│  │       ├── Success, FailureReason                                    │
│  │       └── CreatedTradeItem[]                                        │
│  │           ├── TradeKey (Guid)                                       │
│  │           ├── InstrumentKey, Symbol, Exchange                       │
│  │           ├── Units, TradeValue, TradeSide                         │
│  │           └── WasHeld                                               │
│  │                                                                      │
│  └── Map to InternalTradeExecution[]                                   │
│      └── Redis session storage                                         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key OMS Types (NQ.Trading.Models)

```
NQ.Trading.Models/Portfolio/
├── BatchOrderCreationRequest.cs     // Input to OMS
│   └── PortfolioOrderRequest
│       └── TradeDecisionRequest (InstrumentKey, Decision, Quantity)
│
├── OrderCreationResult.cs           // Output from OMS
│   └── CreatedTradeItem (TradeKey, InstrumentKey, Units, WasHeld)
│
├── DriftCalculationResult.cs        // Pre-execution drift data
│   └── PfHoldingDto (Holdings with Drift details)
│       └── HoldingDriftDto (TradeValue, TradeUnits, Tolerance)
│
├── OrderBatchModels.cs              // Batch tracking
│   ├── OrderBatchBase (Status, ModelCount, TradeCount)
│   └── TradeBatchItem (TradeKey, Status, Units, UnitPrice)
│
└── OrderFulfilmentModels.cs         // Execution progress
    └── TradeFulfilmentItem (UnitsFilled, AverageFillPrice, FillPercentage)
```

### IMorrisonProxy Interface (OMS Gateway)

Location: `NQ.Trading.Models/Interfaces/ITradeServiceBase.cs`

```csharp
// EXECUTION
Task<BatchOrderCreationResult> CreateOrdersBatchAsync(BatchOrderCreationRequest request);

// MONITORING
Task<IReadOnlyList<OrderBatchSummary>> GetPendingBatchesAsync(...);
Task<IReadOnlyList<OrderBatchSummary>> GetExecutingBatchesAsync(...);
Task<OrderBatchBase?> GetBatchDetailsAsync(Guid orderKey, ...);
Task<OrderFulfilmentStatus?> GetBatchFulfilmentAsync(Guid orderKey, ...);
```

### Unification Strategy

#### Phase 1: Align Session Storage (Post-Demo)

Replace TradingCopilot's in-memory `Sessions` with Redis:

```csharp
// Current (demo)
private static readonly ConcurrentDictionary<string, TradingSession> Sessions = new();

// Target (production)
private readonly ITradingSessionStore _sessionStore;  // Redis-backed
```

Benefits:
- Session persistence across restarts
- Multi-instance deployment support
- Consistent expiration handling

#### Phase 2: Unify Trade DTOs

Create adapter layer to convert between DTOs:

```csharp
// Copilot → TradePlanning
HoldingActual → ProposedTradeDto
├── InstrumentCode → InstrumentId (lookup via IInstrumentService)
├── Amount → EstimatedValue
├── Action → Action ("Buy" | "Sell")
├── IsDeferred, DeferReason → Status = "Held"
└── Categories → ComplianceFlags

// TradePlanning → OMS
ProposedTradeDto → TradeDecisionRequest
├── InstrumentId → InstrumentKey
├── Quantity → ExpectedQuantity
└── Action → TradeSide (RebalanceAlertTypes.Buy/Sell)
```

#### Phase 3: Add OMS Execution to Copilot

Extend `TradingCopilotController` with execution endpoint:

```csharp
// New endpoint
[HttpPost("sessions/{sessionId}/execute")]
public async Task<ActionResult<TradeExecutionResultDto>> ExecuteTrades(string sessionId)
{
    // 1. Convert HoldingActual[] → ProposedTradeDto[]
    // 2. Call TradePlanningService.ExecuteTradesAsync()
    // 3. Return execution result
}
```

Reuse existing execution pipeline - don't duplicate OMS integration.

#### Phase 4: Merge Session Models

Long-term target: Single session model supporting both workflows.

```csharp
public class UnifiedTradingSession
{
    // Identity
    public required string SessionId { get; set; }
    public required string UserId { get; set; }

    // Workflow
    public WorkflowMode Mode { get; set; }        // AI vs Manual
    public WorkflowPhase Phase { get; set; }      // Sells → Buys → Review
    public SessionPhase UIPhase { get; set; }     // Selection → Refinement → Execution

    // Data
    public List<TradingPortfolio> Portfolios { get; set; } = new();
    public List<UnifiedTrade> Trades { get; set; } = new();      // Unified type
    public SessionModelAdjustmentsDto? Adjustments { get; set; } // Constraints

    // AI-specific
    public TradingAnalysisSynthesis? AISynthesis { get; set; }
    public BuyReductionSummary? BuyReduction { get; set; }

    // Execution
    public List<TradeExecution> Executions { get; set; } = new();
}

public class UnifiedTrade
{
    public Guid TradeId { get; set; }
    public Guid PortfolioId { get; set; }
    public Guid InstrumentId { get; set; }
    public string InstrumentCode { get; set; }       // Symbol

    // Trade details
    public TradeAction Action { get; set; }          // Buy/Sell/Hold
    public decimal Quantity { get; set; }
    public decimal EstimatedValue { get; set; }
    public decimal? MinAmount { get; set; }          // From AI (optional)
    public decimal? MaxAmount { get; set; }          // From AI (optional)

    // Status
    public TradeStatus Status { get; set; }          // Proposed/Approved/Held/Rejected
    public bool IsDeferred { get; set; }
    public string? DeferReason { get; set; }
    public List<string> Categories { get; set; }     // Events (AI)
    public List<string> ComplianceFlags { get; set; }// Compliance (Planning)

    // Weights
    public decimal CurrentWeight { get; set; }
    public decimal TargetWeight { get; set; }
}
```

### File Reference for OMS Integration

| File | Purpose |
|------|---------|
| `Tmw.Api/Services/TradePlanning/TradePlanningService.cs` | Orchestrates execution |
| `Tmw.Api/Services/Storage/RedisTradePlanningStore.cs` | Session persistence |
| `NQ.Trading.Models/Interfaces/ITradeServiceBase.cs` | OMS interface definition |
| `NQ.Trading.SharedServices/ApiProxy/MorrisonRestProxy.cs` | HTTP OMS client |
| `NQ.Trading.Models/Portfolio/BatchOrderCreationRequest.cs` | OMS input |
| `NQ.Trading.Models/Portfolio/OrderCreationResult.cs` | OMS output |

### Execution Monitoring Flow

```
POST /execute
    ↓
BatchOrderCreationResult (OrderKeys)
    ↓
Store OrderKeys in session
    ↓
Polling: GET /execution-status
    ↓
IMorrisonProxy.GetBatchFulfilmentAsync(orderKey)
    ↓
OrderFulfilmentStatus
├── TradesFilled, TradesPartiallyFilled, TradesPending
├── TotalBuyValueFilled, TotalSellValueFilled
└── TradeFulfilmentItem[] (per-trade fill details)
```

### Migration Checklist

- [ ] Add Redis session store to TradingCopilotController
- [ ] Create HoldingActual → ProposedTradeDto adapter
- [ ] Add InstrumentId lookup service (code → Guid)
- [ ] Add `/execute` endpoint to TradingCopilot
- [ ] Wire up to existing TradePlanningService execution
- [ ] Add execution status polling to frontend
- [ ] Design unified session model
- [ ] Migrate TradePlanningController to unified model
- [ ] Migrate TradingCopilotController to unified model
- [ ] Consolidate DTOs
