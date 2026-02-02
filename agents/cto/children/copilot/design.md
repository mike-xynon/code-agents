# Copilot Agent - Design & Architecture

## System Architecture

```
SessionMode
├── Ursa (existing)       <- Single portfolio, Investor → mandate → model
└── Trading (new)         <- Multi-portfolio, Drift → grouping → execution
```

## Tool Architecture

### Trading Mode Tools (8 tools implemented)

| Tool | Purpose | Status |
|------|---------|--------|
| `GetPortfolioDrift` | Analyze drift from target weights | Implemented |
| `GetGroupedDrift` | Group drift by instrument across portfolios | Implemented |
| `GetTargetGroupAnalysis` | Find substitutable instruments | Implemented |
| `GetInstrumentSignals` | Retrieve IM-provided signals | Implemented |
| `UpdateInstrumentSignals` | Store buy/hold/sell signals | Implemented |
| `GetTradePreview` | Preview trades before execution | Implemented |
| `SubmitTrades` | Execute trades across portfolios | Implemented |
| `GetTradeStatus` | Check execution status | Implemented |

### Ursa Mode Tools (existing)

Separate tool set for single-portfolio mandate-based investing. Not modified by this work.

## Key Design Decisions

### 1. Session Mode Split
- **Decision:** Extend `SessionMode` enum with `Trading` value
- **Rationale:** Clean separation of concerns, different prompts and tools per mode
- **Code:** `nuget:NQ.Copilot/Models/SessionMode.cs`

### 2. Tool Provider Architecture
- **Decision:** Separate tool providers for each mode
- **Rationale:** Tools have different dependencies (IImgrPortfolioService vs IMandateService)
- **Pattern:** `ICopilotToolProvider` implemented per mode

### 3. Context Extensions
- **Decision:** Add `Mode` and `TradingPortfolioService` to `CopilotContext`
- **Rationale:** Trading tools need access to portfolio service for drift calculations
- **Code:** `nuget:NQ.Copilot/Services/CopilotService.cs:1934-1944`

### 4. Signal Storage
- **Decision:** Session-scoped signal storage (not persisted)
- **Rationale:** Signals are transient per conversation, IM provides fresh data each session
- **Storage:** In-memory dictionary keyed by instrument

## Data Flow

```
[IM provides signals] → UpdateInstrumentSignals
                             ↓
[Analyze portfolios] → GetPortfolioDrift → GetGroupedDrift
                             ↓
[Find alternatives]  → GetTargetGroupAnalysis
                             ↓
[Plan trades]        → GetTradePreview
                             ↓
[Execute]            → SubmitTrades → GetTradeStatus
```

## Dependencies

### Services Required

| Service | Purpose | Mode |
|---------|---------|------|
| `IImgrPortfolioService` | Portfolio drift, positions | Trading |
| `ITradingPortfolioService` | Trade execution | Trading |
| `IInstrumentProvider` | Instrument lookup | Both |
| `ICentralAssetModelsService` | Asset model data | Both |

### NuGet Package Dependencies

- `NQ.Copilot` - Core copilot framework
- `NQ.Imgr` - Portfolio management interfaces
- `NQ.Trading` - Trade execution interfaces

## Code References

### Key Files Modified

| File | Changes |
|------|---------|
| `nuget:NQ.Copilot/Services/CopilotService.cs` | Added TradingPortfolioService to context |
| `nuget:NQ.Copilot/Models/SessionMode.cs` | Added Trading mode |
| `nuget:NQ.Copilot/Tools/TradingTools/` | New tool implementations |
| `nuget:NQ.Copilot.Tests/Unit/WorkflowToolsTests.cs` | Test updates |

## Open Questions

1. **UI Integration** - How does Trading mode get initiated from portal?
2. **Permission Model** - What permissions are required for multi-portfolio trading?
3. **Audit Trail** - How are trading decisions logged for compliance?

## External Design Documents

Located in `C:\Users\Micha\source\repos\nq\ClaudePortal\`:

| Document | Purpose |
|----------|---------|
| `trading-copilot-design.md` | Full architecture (Phase 1 foundation, Phase 2 intelligence) |
| `trading-support-system-design.md` | 10 tool specifications |
| `copilot-trading-extension.md` | Active development log |
