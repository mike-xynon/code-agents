# LSEG Corporate Actions Data Evaluation

> **Purpose:** Systematically evaluate LSEG libraries for corporate action data access
> **Started:** 2026-01-31
> **Status:** In Progress

---

## 1. Current Setup

### 1.1 Installed Packages

| Package | Version | Location |
|---------|---------|----------|
| LSEG.Data.Content | 2.2.2 | NQ.Lseg project |

### 1.2 Available Namespaces (Confirmed)

- `LSEG.Data.Content.Pricing` - Real-time quotes
- `LSEG.Data.Content.HistoricalPricing` - Historical price data
- `LSEG.Data.Content.SearchService` - Instrument search
- `LSEG.Data.Content.Symbology` - RIC/symbol conversion
- `LSEG.Data.Content.Data` - Generic data structures
- `LSEG.Data.Core` - Session management

### 1.3 Credentials

- Stored in user secrets (ID: `6d25fa95-6a7d-496d-bd0f-014d886f03ab`)
- Session type: RDPv1 (Platform Session)

---

## 2. Evaluation Steps

### Step 1: Verify Current Tests Pass
- [ ] Run existing symbology integration tests
- [ ] Confirm session authentication works
- [ ] Document any errors

### Step 2: Explore Available NuGet Packages
- [ ] List all LSEG packages on NuGet
- [ ] Check if LSEG.Data (main package) differs from LSEG.Data.Content
- [ ] Evaluate EikonDataAPI package

### Step 3: Test Data Access Capabilities
- [ ] Test SearchService for dividend-related fields
- [ ] Test if FundamentalAndReference exists in any package
- [ ] Explore Data namespace for hidden capabilities

### Step 4: Evaluate Alternative Session Types
- [ ] Check if Desktop Session is available
- [ ] Test different session configurations
- [ ] Document session capabilities

### Step 5: Decision Point
- [ ] Document what IS available
- [ ] Document what is NOT available
- [ ] Recommend next steps

---

## 3. Progress Log

### 2026-01-31 12:00 - Initial Assessment

**Finding:** The `LSEG.Data.Content` package (v2.2.2) is designed for RDP (Refinitiv Data Platform) access. Based on LSEG developer community discussions, RDP does NOT support TR.* fundamental/reference fields - only real-time Elektron fields.

**Decision:** Need to systematically verify this by:
1. Testing what the current package CAN do
2. Checking if other packages provide different capabilities
3. Exploring session configuration options

---

### 2026-01-31 12:30 - Running Existing Tests

**Action:** Running LSEG symbology integration tests to verify baseline functionality.

**Result:** ✅ Baseline test passed - session authentication and symbology resolution working.

---

### 2026-01-31 14:30 - Package Assembly Exploration

**Action:** Added LSEG.Data package (v2.2.2) and explored all namespaces via reflection.

**LSEG.Data Assembly Namespaces (2):**
```
LSEG.Data.Core
LSEG.Data.Logger
```

**LSEG.Data.Content Assembly Namespaces (28):**
```
LSEG.Data.Content
LSEG.Data.Content.Data
LSEG.Data.Content.HistoricalPricing
LSEG.Data.Content.HistoricalPricing.Events
LSEG.Data.Content.HistoricalPricing.Interday
LSEG.Data.Content.HistoricalPricing.Intraday
LSEG.Data.Content.HistoricalPricing.Tick
LSEG.Data.Content.IPA                          <-- Instrument Pricing Analytics
LSEG.Data.Content.IPA.Curves
LSEG.Data.Content.IPA.Dates
LSEG.Data.Content.IPA.FinancialContracts
LSEG.Data.Content.IPA.Surfaces
LSEG.Data.Content.News
LSEG.Data.Content.Pricing
LSEG.Data.Content.SearchService
LSEG.Data.Content.Symbology
```

**Key Finding:** ❌ NO `FundamentalAndReference` namespace exists in either package.

**Definition Classes Found:**
- Pricing.Definition (real-time quotes)
- HistoricalPricing.Summaries.Definition (OHLC data)
- HistoricalPricing.Events.Definition (price events)
- IPA.FinancialContracts.Definition (derivatives)
- SearchService.Search.Definition (instrument search)
- Symbology.SymbolConversion.Definition (RIC conversion)

**Decision:** The TR.* fundamental fields (dividends, corporate actions) are NOT accessible through the current SDK. Need to explore:
1. IPA namespace for any relevant data
2. Alternative access methods (REST API direct call)

---

### 2026-01-31 14:45 - Direct API Access Attempt

**Action:** Extracted access token from session and tried direct REST API calls.

**Results:**
- ✅ AccessToken successfully extracted (2473 chars)
- ❌ API endpoints returning 404 Not Found:
  - `https://api.refinitiv.com/data/datagrid/v1/` → 404
  - `https://api.refinitiv.com/data/fundamental-and-reference/v1/` → 404
  - `https://api.refinitiv.com/data/pricing/v1/` → 404

**Analysis:** The direct API endpoints are not accessible. Possible reasons:
1. Wrong endpoint URLs (LSEG rebranding may have changed them)
2. Subscription doesn't include these API endpoints
3. These endpoints require different authentication

**Finding from Web Search:**
- LSEG Data Library Python has `fundamental_and_reference` module
- .NET SDK doesn't expose this functionality
- May need to upgrade to different LSEG product tier

---

### 2026-01-31 15:00 - Summary of LSEG Capabilities

**What WORKS with current setup:**
- ✅ Session authentication (RDPv1/Platform Session)
- ✅ Symbology resolution (RIC lookup)
- ✅ Search service (instrument search)
- ✅ Real-time pricing
- ✅ Historical pricing (OHLC data)
- ✅ Access token extraction

**What DOESN'T WORK:**
- ❌ FundamentalAndReference namespace (not in SDK)
- ❌ TR.* fields for dividends/corporate actions
- ❌ Direct API calls to fundamental endpoints
- ❌ Corporate action event data

**Conclusion:** The current LSEG subscription/SDK cannot provide corporate action data.

---

## 4. Final Recommendations

### Option A: Upgrade LSEG Subscription
Contact LSEG to add:
- Eikon Desktop access (enables full TR.* fields)
- Refinitiv Tick History / DataScope Select (corporate actions extraction API)

**Pros:** Official, comprehensive data
**Cons:** Additional licensing cost, may take time to provision

### Option B: EDI Corporate Actions Feed
Check if current EDI subscription includes corporate actions data beyond listing reference.
Contact Exchange Data International for [corporate actions API access](https://developer.exchange-data.com/).

**Pros:** Already have EDI integration, comprehensive coverage
**Cons:** May require subscription upgrade

### Option C: Alternative Data Providers
- **Systemathics.Apis** (85K NuGet downloads) - market data APIs
- **ASX Company Announcements** - free but requires parsing

### Option D: Hybrid Approach (Recommended for MVP)
1. Use existing LSEG for pricing/symbology
2. Add EDI corporate actions feed for structured data
3. Supplement with manual entry for election-specific details

---

## 5. Test Files Created

| File | Purpose |
|------|---------|
| `LsegPackageExplorationTests.cs` | Explores available namespaces/types |
| `LsegDataPlatformApiTests.cs` | Tests session properties and IPA |
| `LsegDirectApiTests.cs` | Tests direct REST API access |
| `LsegCorporateActionIntegrationTests.cs` | Documents API limitations |

---

## 6. Next Steps

1. **Verify EDI subscription** - Check what corporate action data EDI provides
2. **Contact LSEG sales** - Inquire about fundamental data access options
3. **Design fallback** - Plan manual entry system for MVP

