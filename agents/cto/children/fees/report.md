# Fees Agent - Progress Report

## Current Status

**Phase:** 1 - Analysis & Documentation (In Progress)
**Last Updated:** 2026-02-03

## Session Log

### Session 1 - 2026-02-03

**Objective:** Understand the fee system architecture

**Completed:**
- Located fee-related code in `~/repos/nuget` (not registry as initially assumed)
- Identified the two-context architecture:
  - `ChargeModelDataContext` (NQ.Charges) - offer/template storage
  - `PortfolioModelDataContext` (NQ.DataModel) - applied fees storage
- Mapped core data models: ChargeV1, OfferPackageDto, PortfolioFeeSetDto
- Documented key services: FeeOrchestrator, ChargeTransactionProvider, WorkspacePackageService
- Traced fee calculation flow from holdings to PortfolioChargeRecord
- Identified the `IsPremium` flag mechanism for premium feature opt-in
- Documented `PortfolioInstruction` types and their effects on fee boundaries
- Identified potential gap in PremiumReport instruction → fee activation flow

**Key Findings:**
1. Fees use a snapshot model - offer packages are captured as JSON when client agrees
2. Premium features (IsPremium=true) require explicit selection via PortfolioFeeSetDto
3. Fee date boundaries are controlled by PortfolioInstruction records
4. Daily fees are calculated as annual_amount / 365

**Questions Raised:**
- Is there an existing handler for PremiumReport instructions that creates PortfolioCharge records?
- How is FeatureType mapped to ChargeV1.ServiceType?
- What triggers the connection between AddFeature() and fee activation?

**Documentation Created:**
- Updated `design.md` with comprehensive (but tentative) architecture analysis
- Added confidence levels to distinguish confirmed vs inferred details

## Next Steps

1. Write unit tests to validate fee calculation assumptions
2. Search for PremiumReport instruction handler (may exist in code not yet reviewed)
3. Validate tax pattern calculations with concrete test cases
4. Begin Phase 2: Client setup queries (after core understanding validated)

## Blockers

- Need unit test validation before high confidence on calculation details
- Premium feature flow needs end-to-end tracing to confirm or identify gap

## Files Reviewed

| File | Purpose |
|------|---------|
| `NQ.DataModel/Models/Fees/Fee.cs` | Base fee model |
| `NQ.DataModel/Models/Fees/VariableFee.cs` | Variable fee model (adviser fees) |
| `NQ.DataModel/Models/Fees/FeeCalculator.cs` | Legacy fee calculation |
| `NQ.DataModel/Services/FeeOrchestrator.cs` | Fee coordination |
| `NQ.DataModel/Services/ChargeProvider.cs` | ChargeTransactionProvider & PortfolioChargeProvider |
| `NQ.DataModel/Services/WorkspacePackages.cs` | WorkspacePackageService |
| `NQ.DataModel/Services/PortfolioRepository.cs` | AddFeature() for PremiumReport |
| `NQ.DataModel/Entities/PortfolioFee.cs` | PortfolioCharge, PortfolioChargeRecord, PortfolioInstruction |
| `NQ.Charges/Entities/ChargeModelDataContext.cs` | Offer-side data context |
| `NQ.Charges/Services/ChargeRepository.cs` | ChargeService implementation |
| `NQ.Trading/NQ.Trading.Models/Fees/ChargeV1.cs` | Charge definition |
| `NQ.Trading/NQ.Trading.Models/Fees/OfferPackageDto.cs` | Package DTOs |
| `NQ.Trading/NQ.Trading.Models/Portfolio/PortfolioFeatureDto.cs` | Feature selection DTO |
| `NQ.DataModel/Docs/FeeCalculation.md` | Existing documentation |
| `NQ.Trading.Tests/FeeCalculationSequenceTests.cs` | Test examples |
