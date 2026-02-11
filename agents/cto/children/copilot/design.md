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

## Open Questions

1. **Momentum Data Source** - Currently using CategoryData.Momentum which may be null; need reliable source
2. **Caching** - Should momentum analysis be cached within a session?
3. **Partial Results** - How to handle if momentum analysis fails but portfolio analysis succeeds?
4. **Tolerance Aggregation** - When same symbol appears in multiple portfolios with different tolerances, how to aggregate?
