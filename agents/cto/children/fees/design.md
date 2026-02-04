# Fees Agent - Design Document

## Status

**Document Type:** Tentative Reverse-Engineering Analysis
**Last Updated:** 2026-02-03
**Confidence Level:** Medium - derived from code review, not yet validated with unit tests

> **Important:** This document represents our current understanding based on static code analysis. Many details are inferred from code structure and naming conventions. Specific behaviors should be confirmed through unit tests before relying on them for implementation decisions.

## Overview

The fee system manages charges for portfolios across two distinct data contexts:
- **Offer/Template side** (`ChargeModelDataContext`) - flexible, versioned charge definitions
- **Actual/Applied side** (`PortfolioModelDataContext`) - precise snapshots applied to portfolios

This separation allows fee packages to be defined with flexibility and overrides, while ensuring that once a client agrees to fees, the exact terms are captured immutably.

## Two-Context Architecture

### ChargeModelDataContext (NQ.Charges)

Stores the **offer templates** - the menu of available charges.

| Entity | Purpose | Confidence |
|--------|---------|------------|
| `ChargeServiceProvider` | Organizations providing services (DDH, OMG, Morrison, Arktos) | High |
| `ChargeServiceType` | Service categories (Admin, Promoter, Trustee, etc.) | High |
| `PlatformOffer` | Products (NQ Super, NQ Pension, Xynon MDA) | High |
| `ServiceCharge` | Charge definition linking Provider + ServiceType | High |
| `ChargeVersion` | Versioned JSON (ChargeV1) with ValidFrom date | High |
| `OfferPackage` | Named package of charges for a date (e.g., "NQ Super @ Jan 24") | High |
| `PackagedCharge` | Links ChargeVersion → OfferPackage with optional JsonOverride | High |

### PortfolioModelDataContext (NQ.DataModel)

Stores the **applied fees** - what the client actually agreed to.

| Entity | Purpose | Confidence |
|--------|---------|------------|
| `OfferedPackage` | JSON snapshot of OfferPackageDto at agreement time | High |
| `PortfolioCharge` | Links portfolio → OfferedPackage + AdviceFeeJson | High |
| `PortfolioChargeRecord` | Individual calculated charge entries for execution | High |
| `PortfolioInstruction` | User instructions affecting fees (cancellation, premium features) | High |

### Relationship Diagram

```
OFFER SIDE (ChargeModelDataContext)          ACTUAL SIDE (PortfolioModelDataContext)
─────────────────────────────────────        ────────────────────────────────────────
ServiceProvider ─┐
ServiceType ─────┼→ ServiceCharge
                 │        │
                 │        ↓
                 │   ChargeVersion (JSON)
                 │        │
PlatformOffer ───┼→ OfferPackage
                 │        │
                 │        ↓
                 └→ PackagedCharge ──────→  OfferedPackage (JSON snapshot)
                    (with overrides)              │
                                                  ↓
                                           PortfolioCharge ←── Portfolio
                                           (OfferedPackageKey +
                                            AdviceFeeJson)
                                                  │
                                                  ↓
                                           PortfolioChargeRecord[]
```

## Core Data Models

### ChargeV1 (Charge Definition)

Located: `NQ.Trading/NQ.Trading.Models/Fees/ChargeV1.cs`

| Field | Type | Purpose |
|-------|------|---------|
| `Title` | string | Display name for end users |
| `Name` | string | Internal identifier |
| `Offer` | string | Product (NQ Super, NQ Pension, Xynon MDA) |
| `ServiceType` | string | Admin, Promoter, Trustee, Adviser, etc. |
| `Provider` | string | DDH, OMG, Morrison, Arktos |
| `Rule` | ChargeRule | Bps, BpsWithMin, Fixed, AdHoc, Adjustment |
| `Frequency` | ChargeFrequency | Monthly, Annually, Joining, Order |
| `TaxPattern` | string | AuGstRitc, AuGstRitcAndRebate, Adjustment |
| `AccountCodes` | ChargeAccountCodes | CoA codes for revenue/tax/credit/rebate |
| `Tiers` | List\<ChargeTier\> | Amount tiers with min/max boundaries |
| `IsPremium` | bool? | **Key flag** - requires explicit selection if true |
| `Cap` | decimal? | Maximum charge amount |
| `CapPeriod` | CapPeriod? | Period for cap (CalendarYear, etc.) |

### OfferPackageDto

Located: `NQ.Trading/NQ.Trading.Models/Fees/OfferPackageDto.cs`

Contains `PlatformCharges` - a list of `PackagedChargeDto`, each with:
- `PlatformCharge` - base ChargeV1 definition
- `ChargeOverride` - optional segment/time-specific override

### PortfolioFeeSetDto

Located: `NQ.Trading/NQ.Trading.Models/Fees/OfferPackageDto.cs`

Stored in `PortfolioCharge.AdviceFeeJson`. Contains portfolio-specific fee selections:
- `Charges` - List of `PortfolioFeeDto`
  - `PlatformCharge` - reference to offer package charge
  - `Charge` - the actual ChargeV1 the client agreed to
  - `SelectedFrequency` - chosen billing frequency (if options available)

## Key Services

### IChargeService / ChargeService

Located: `NQ.Charges/Services/ChargeRepository.cs`

Manages offer-side data:
- `GetOfferPackage(name, date)` - retrieves applicable package
- `EnsureOfferPackage(dto)` - creates/updates package definitions

**Confidence:** High - clear from code structure

### IFeeOrchestrator / FeeOrchestrator

Located: `NQ.DataModel/Services/FeeOrchestrator.cs`

Coordinates fee operations:
- `GetOfferPackage()` - retrieves and ensures package exists
- `EnsurePortfolioFee()` - links portfolio to fee package
- `CalculateChargeRecords()` - generates charge records from holdings

**Confidence:** High - clear from code structure

### WorkspacePackageService

Located: `NQ.DataModel/Services/WorkspacePackages.cs`

Creates actual fee records:
- `EnsureOfferedPackage()` - stores JSON snapshot
- `EnsurePortfolioFee()` - creates PortfolioCharge linking portfolio to package
- `EnsureCancellation()` - creates cancellation instructions
- `UpsertWithdrawalInstruction()` - manages withdrawal instructions

**Confidence:** High - clear from code structure

### ChargeTransactionProvider

Located: `NQ.DataModel/Services/ChargeProvider.cs`

Core calculation engine:
- Takes `IPortfolioChargeProvider` (charge definitions) and `PortfolioInstruction[]` (boundaries)
- Determines fee date boundaries from instructions
- `CalculateCreateChargeRecords()` - generates PortfolioChargeRecord entries

**Confidence:** High for structure, Medium for exact calculation details

### PortfolioChargeProvider

Located: `NQ.DataModel/Services/ChargeProvider.cs`

Loads charge definitions for a portfolio:
- Deserializes OfferPackageJson and AdviceFeeJson
- `ChargesFor(date)` - returns applicable ChargeV1 list for a date

**Confidence:** High

## Fee Calculation Flow

### 1. Package Applied to Portfolio

```
FeeOrchestrator.EnsurePortfolioFee(packageName, portfolioKey, validFrom)
    ↓
WorkspacePackageService.EnsurePortfolioFee()
    ↓
1. EnsureOfferedPackage (JSON snapshot)
2. Determine entityType from ClientType (NQ Super, NQ Pension)
3. Get variable fees from FeeCalculator.VariableFeesAgreedAtOnboarding()
4. Build PortfolioFeeSetDto with adviser charges
5. Create PortfolioCharge (OfferedPackageKey + AdviceFeeJson)
```

**Confidence:** Medium - inferred from code, needs validation

### 2. Fee Calculation

```
FeeOrchestrator.CalculateChargeRecords(portfolioKey)
    ↓
1. Get portfolio reference via IGlobalClientMap
2. Create workspace-scoped services
3. Get IFinancialHoldingRepository
4. Create ChargeTransactionProvider for portfolio
5. Get holdings up to current date
6. Group holdings by date
7. For each date: chargeTransactionProvider.CalculateCreateChargeRecords()
8. Upsert PortfolioChargeRecords
```

**Confidence:** High - clear from FeeOrchestrator code

### 3. Daily Charge Record Generation

```
ChargeTransactionProvider.CalculateCreateChargeRecords(holdings)
    ↓
1. Check date within fee window (feeStartDate ≤ date ≤ portfolioFeeEndDate)
2. Get applicable charges: _portfolioChargeProvider.ChargesFor(date)
3. Calculate holdingValue (sum of holdings, excluding Shield Master after Sept 2024)
4. For each ChargeV1 (skip Adjustment & Joining):
   → CreateChargeRecord() generates PortfolioChargeRecord
```

**Confidence:** High - clear from code

### 4. Charge Calculation Rules

| Rule | Formula | Confidence |
|------|---------|------------|
| `Bps` | `basis × rate / 365` (tiered) | High |
| `BpsWithMin` | `max(basis × rate / 365, minimum)` | High |
| `Fixed` | `amount / 365` | High |

Tax calculation (appears to use):
```
feeExclTax = feePayable / (1 + taxRate)
tax = feePayable - feeExclTax
taxCredit = tax × taxCreditRate
taxRebate = feeExclTax × taxRebateRate
```

**Confidence:** Medium - derived from CreateChargeRecord, needs test validation

## Premium Feature Flow

### PortfolioInstruction Types

| Type | Effect | Confidence |
|------|--------|------------|
| `FullCancellation` | Stops all fees on CompletionDate | High |
| `CancelAdviceFees` | Stops adviser fees on InitiateDate | High |
| `Withdrawal` | Triggers withdrawal workflow | Medium |
| `PremiumReport` | Triggers premium service + fee tracking | Medium |

### Premium Charge Selection

The `IsPremium` flag on ChargeV1 controls whether a charge requires explicit opt-in:

```csharp
// From OfferPackageDto.GetApplicableCharges()
if (charge.IsPremium != true)
{
    // Non-premium: always apply
    result.Add(charge);
}
else
{
    // Premium: only apply if selected in PortfolioFeeSetDto
    var selection = portfolioFees?.Charges?
        .FirstOrDefault(pf => pf.PlatformCharge?.ChargeVersionId == packagedCharge.ChargeVersionId);
    if (selection != null) { ... }
}
```

**Confidence:** High - clear from code

### PortfolioFeatureDto

Located: `NQ.Trading/NQ.Trading.Models/Portfolio/PortfolioFeatureDto.cs`

Stored in `PortfolioInstruction.InstructionData` for PremiumReport instructions:

| Field | Purpose |
|-------|---------|
| `FeatureType` | PremiumReportAnnual or PremiumReportMonthly |
| `RequestDate` | When feature was requested |
| `IsEnabled` | Whether feature is active |
| `ChargeFrequency` | Selected billing frequency |
| `FeeSpecification` | Custom fee details (if any) |

**Confidence:** High - clear from code

## Identified Gap: Premium Instruction → Fee Activation

### What Exists

1. `AddFeature()` in PortfolioRepository creates `PortfolioInstruction` with PremiumReport type
2. `GetApplicableCharges()` filters charges based on `IsPremium` and selections in `PortfolioFeeSetDto`
3. Test code shows how to build `PortfolioFeeSetDto` to select premium charges

### What Appears Missing

**A handler that connects the instruction to fee activation:**

```
User selects PremiumReportAnnual
        ↓
AddFeature() creates PortfolioInstruction
        ↓
    [HANDLER NOT YET IDENTIFIED]
        ↓
    Expected behavior:
    1. Get OfferPackage for portfolio's product
    2. Find ChargeV1 with IsPremium=true matching feature type
    3. Build PortfolioFeeDto with:
       - PackagedChargeDto reference
       - Charge (with FeeSpecification if custom)
       - SelectedFrequency from PortfolioFeatureDto.ChargeFrequency
    4. Create/update PortfolioCharge.AdviceFeeJson
        ↓
GetApplicableCharges() includes the premium charge
        ↓
Fee calculation generates PortfolioChargeRecords
```

**Missing link details:**
- Mapping `FeatureType` → matching `ChargeV1.ServiceType`
- Code to build `PortfolioFeeSetDto` from `PortfolioFeatureDto`
- Triggering `PortfolioCharge` creation/update when instruction is processed

**Confidence:** Low - this is inferred from the gap between existing components. May exist in code not yet reviewed, or may be intentionally not implemented yet.

## Fee Date Boundaries

ChargeTransactionProvider sets boundaries from PortfolioInstruction records:

| Boundary | Source | Effect |
|----------|--------|--------|
| `_feeStartDate` | PortfolioChargeProvider.FeeStartDate | No fees before client acceptance |
| `_adviceFeeEndDate` | FullCancellation or CancelAdviceFees InitiateDate | Adviser fees stop |
| `_portfolioFeeEndDate` | FullCancellation CompletionDate | All fees stop |

**Confidence:** High - clear from ChargeTransactionProvider constructor

## Tax Patterns

| Pattern | GST Rate | RITC Rate | Rebate Rate | Use Case |
|---------|----------|-----------|-------------|----------|
| `AuGstRitc` | 10% | 75% | 0% | Standard super fund fees |
| `AuGstRitcAndRebate` | 10% | 75% | 15% | Super fund fees with rebate |
| `Adjustment` | 0% | 0% | 0% | Non-taxable (withdrawals) |

**Confidence:** Medium - derived from documentation and code references

## File Locations Summary

| Component | Path |
|-----------|------|
| ChargeV1 | `NQ.Trading/NQ.Trading.Models/Fees/ChargeV1.cs` |
| OfferPackageDto | `NQ.Trading/NQ.Trading.Models/Fees/OfferPackageDto.cs` |
| FeeOrchestrator | `NQ.DataModel/Services/FeeOrchestrator.cs` |
| ChargeTransactionProvider | `NQ.DataModel/Services/ChargeProvider.cs` |
| WorkspacePackageService | `NQ.DataModel/Services/WorkspacePackages.cs` |
| ChargeRepository | `NQ.Charges/Services/ChargeRepository.cs` |
| ChargeModelDataContext | `NQ.Charges/Entities/ChargeModelDataContext.cs` |
| PortfolioModelDataContext | `NQ.DataModel/Entities/PortfolioModelDataContext.cs` |
| PortfolioFee entities | `NQ.DataModel/Entities/PortfolioFee.cs` |
| PortfolioRepository | `NQ.DataModel/Services/PortfolioRepository.cs` |
| FeeCalculation docs | `NQ.DataModel/Docs/FeeCalculation.md` |

## Next Steps for Validation

1. **Write unit tests** to confirm fee calculation formulas
2. **Trace PremiumReport flow** end-to-end to find or confirm missing handler
3. **Validate tax pattern application** with concrete examples
4. **Confirm date boundary behavior** with edge case tests
5. **Document actual database queries** for client setup (Phase 2)

## Client Setup Queries

*To be developed in Phase 2 after core understanding is validated*
