# Corporate Actions Progress

## Current Status
**CLASS DESIGN COMPLETE** - Data model designed and approved. Single `CorporateAction` database entity with JSON `EventData` field. Interface hierarchy: `IEventTypeData` base, 5 category interfaces (`IDividendData`, `IRightsData`, `ITakeoverData`, `IMeetingData`, `IBuybackData`), plus `IElectionOptions` mixin for voluntary actions. Ready for implementation.

**Design Document:** `corporate-actions-class-design.md`

## Blockers
| Blocker | Status | Notes |
|---------|--------|-------|
| Corporate Action Data Source | **OPTIONS IDENTIFIED** | ASX Real-Time CA (recommended) or EDI. Need to check subscriptions/pricing. Manual entry designed as fallback. |
| ASX ReferencePoint Subscription | **CHECK REQUIRED** | Free CA access if we have ReferencePoint. Contact: Information.Services@asx.com.au |
| EDI Subscription Scope | **CHECK REQUIRED** | May already include corporate actions. Need to confirm with business. |
| Morrison Election API | **OPEN** | Unknown if Morrison has API for election submission. Need to clarify their capabilities |
| Registry Confirmation Method | **OPEN** | How do we confirm elections were processed? Polling, webhook, or reconciliation file? |

## Next Actions Queue

### Implementation (Ready to Start)
1. ✅ ~~Get LSEG Data Content Guide~~ - **DONE**
2. ✅ ~~Design unified data model~~ - **DONE** - See `corporate-actions-class-design.md`
3. **Create EF Core entities** - `CorporateAction`, `CorporateActionElection`
4. **Create database migration** - Single table with JSON column
5. **Create repository interface** - `ICorporateActionRepository`
6. **Create service layer** - `ICorporateActionService` with factory for deserialization
7. **Create ingestion service** - For LSEG/EDI/Manual data sources

### Data Access (Parallel Track)
8. **Test LSEG DSS endpoint** - Try `selectapi.datascope.lseg.com` with current credentials
9. **Request EDI sample data** - Email drafted below (still relevant for comparison)

### Business Questions (Parallel)
10. **Check ASX ReferencePoint subscription** - Free CA data if we have it
11. **Check EDI subscription scope** - May already include corporate actions
12. **Schedule Morrison call** - Focus on election SUBMISSION API

### Implementation (After Design)
9. **Database migrations** - corporate_actions, elections, resolutions tables
10. **Build admin portal screens** - Manual entry MVP while integrations developed
11. **Implement CA ingestion service** - Connect to chosen data provider

## Progress Log

### 2026-02-02 (Session 7) - CLASS DESIGN
- **DATA MODEL DESIGN APPROVED** with user through iterative refinement

- **ADDED RAW DATA STORAGE** for provider audit trail:
  - New entity `CorporateActionSource` stores original provider response
  - Enables healing/reprocessing if parsing logic changes
  - Stores: RawData, Provider, FetchedAt, ProcessingErrors
  - One CorporateAction can have multiple source records (updates, re-fetches)

- **REVIEWED LSEG DATA ACCESS**:
  - Confirmed DSS (DataScope Select) is separate product from SDK
  - Different endpoint: `selectapi.datascope.lseg.com`
  - 8 event categories: CAP, DIV, EAR, MNA, NOM, PEO, SHO, VOT
  - Need to confirm license includes DSS access

- **DRAFTED EMAIL TO WES** - `email-draft-wes-lseg.md`:
  - Asking about LSEG license coverage
  - What corporate actions access we have
  - Whether DSS is included or needs upgrade
  - Alternative options (ASX ReferencePoint, EDI)

- **DATA MODEL DESIGN APPROVED** with user through iterative refinement:

- **Rejected patterns:**
  - Separate `CorporateActionOption` table → Options are value objects, not entities
  - Separate extension tables per type → Overkill, JSONB is sufficient
  - Subtype interfaces → Unnecessary complexity

- **Approved design:**
  - Single `CorporateAction` entity with `EventData` as JSON string
  - `EventTypeCode` as string (ISO CAEV codes: "DRIP", "RHTS", "TEND", etc.)
  - Only truly common fields on entity: `AnnouncementDate`, `RecordDate`
  - Type-specific data (including `PaymentDate` for dividends) in JSON
  - `IElectionOptions` mixin interface for voluntary actions (has `Options`, `DefaultOptionCode`, `ElectionDeadline`)

- **Interface hierarchy:**
  ```
  IEventTypeData (base)
  ├── IDividendData ──────── Some implement IElectionOptions (DRIP), some don't (DVCA)
  ├── IRightsData : IElectionOptions
  ├── ITakeoverData : IElectionOptions
  ├── IMeetingData : IElectionOptions
  └── IBuybackData : IElectionOptions
  ```

- **Created:** `corporate-actions-class-design.md` with full class definitions

---

### 2026-02-01 (Session 6)
- **LSEG DATA CONTENT GUIDE ANALYZED** - Extracted from `reference-data/515597.xlsx` (13MB Excel, 14 sheets)
  - Used Python openpyxl to extract field definitions in read-only mode
  - Output files: `report_types_extract.json`, `field_definitions_extract.json`, `code_descriptions_extract.json`

- **LSEG DataScope Select Report Types:**
  | Report Type | Category | Coverage |
  |-------------|----------|----------|
  | Corporate Actions - Standard Events | Equity, Mutual Funds | Dividends, capital changes, M&A |
  | Corporate Actions - IPO Events | Equity | IPOs |
  | Corporate Actions - ISO 15022 Events | Equity, Fixed Income, Convertibles | Full ISO 15022 format |
  | Debt Corporate Actions - ISO 15022 | Gov't/Agency | Bond-specific CA |

- **FIELD COUNTS:**
  - **Corporate Actions**: 351 fields
  - **Debt Corporate Actions (ISO 15022)**: 350 fields
  - **Election/Option related**: 61+ fields identified

- **KEY ELECTION FIELDS CONFIRMED (Corporate Actions):**
  | Field | Type | Description |
  |-------|------|-------------|
  | Mandatory/Voluntary Indicator | TEXT | Code indicating if event requires election |
  | Capital Change Optional Flag | TEXT | Y/N if optional for shareholders |
  | Dividend Reinvestment Deadline | DATE | DRP election deadline |
  | Subscription Period Start/End Date | DATE | Rights issue subscription window |
  | Tender Offer Start/Expiration Date | DATE | Takeover offer window |
  | Voting Rights Date | DATE | Meeting voting cutoff |
  | Rights Period Start/End Date | DATE | Rights trading window |
  | Rights ISIN | TEXT | ISIN for tradable rights |
  | Offer Price | NUMERIC | Subscription/exercise price |
  | Capital Change Renounceable Flag | TEXT | Y/N if rights transferable |

- **KEY ISO 15022 FIELDS (Debt Corporate Actions):**
  | Field | Type | Description |
  |-------|------|-------------|
  | Event Type Code | TEXT | ISO 15022 CAEV code |
  | Mandatory Voluntary Indicator Code | TEXT | MAND/VOLU/CHOS |
  | Option Number | NUMERIC | Identifies available options |
  | Option Type Code | TEXT | Type of option |
  | Option Status Code | TEXT | Status of option |
  | Market Deadline Date | DATE | Issuer deadline for election |
  | Certification Deadline Date | DATE | Certification cutoff |
  | Period of Action Start/End Date | DATE | Option validity period |
  | Default Processing Flag | TEXT | Y/N if option is default |
  | Features Indicator Code | TEXT | Option features |

- **CONCLUSION:** LSEG DataScope Select has COMPLETE corporate action coverage:
  - All election fields we need (deadlines, options, mandatory/voluntary)
  - ISO 15022 event type codes
  - Meeting/voting data
  - Rights issue details
  - **The gap is access, not data availability**

### 2026-01-31 (Session 5)
- **EXTRACTED KEY INFO FROM DOWNLOADED PDFs** using pdftotext
  - Location: `reference-data/`
  - Converted to text: `dss_user_guide.txt`, `dss_soap_guide.txt`, `isitc_market_practice.txt`

- **MAJOR FINDING: Three Distinct Data Structure Categories**
  1. **MANDATORY** - No election (DVCA, BONU, SPLF) - simple structure
  2. **VOLUNTARY** - Election required (DRIP, RHTS, TEND, BIDS) - needs options array, deadline
  3. **MEETING** - Proxy/voting (MEET, GMET, CMET) - needs resolutions, proxy deadline

- **Created comprehensive "Corporate Action Data Structures - Research Summary" section:**
  - Sources reviewed table with what each contributed
  - Detailed breakdown of three categories with field requirements
  - Proposed data model structure
  - LSEG 8 event categories with date fields
  - ISO 15022 message types (MT564-MT568)
  - What's still unknown

- **LSEG DSS Findings:**
  - 8 event categories: CAP, DIV, EAR, MNA, NOM, PEO, SHO, VOT
  - `GetCoraxEvents()` API returns full event list
  - Each category has specific date field constraints

- **ISITC Market Practice Findings:**
  - Rights issues = TWO linked events (RHDI distribution + EXRI exercise)
  - Response deadline is at OPTION level, not event level
  - MT568 for narrative overflow (text, not PDF attachments)
  - Proxy Tabulator is a defined actor role

- **Document Distribution:**
  - Data feeds provide URLs, NOT actual PDF documents
  - MT568 = text overflow, not attachments
  - Actual documents from registries (Computershare, Link)

### 2026-01-31 (Session 4)
- **COMPREHENSIVE CORPORATE ACTION TYPES RESEARCH**

- **Created full CAEV (Corporate Action Event) code table:**
  - 50+ event types defined in ISO 15022/20022
  - Identified which require elections vs mandatory
  - Identified which involve document distribution
  - Both LSEG and EDI use ISO 15022 format

- **Key Event Types for Elections:**
  | Code | Event | Election |
  |------|-------|----------|
  | DRIP | Dividend Reinvestment | Yes |
  | DVOP | Dividend Option | Yes |
  | RHTS | Rights Issue | Yes |
  | BIDS | Buyback/Issuer Bid | Yes |
  | TEND | Tender/Takeover | Yes |
  | MEET | AGM | Yes (proxy) |
  | GMET | General Meeting | Yes (proxy) |
  | MRGR | Merger | Yes (vote) |

- **Document Distribution:**
  - MT568 = Corporate Action Narrative (document attachments)
  - Registries are primary source for actual PDFs
  - Data feeds provide announcement details + document URLs

- **Added Documentation Download Section:**
  - Listed specific PDFs user can download for my review
  - LSEG User Guide, SOAP Guide, Data Content Guide
  - EDI requires developer portal registration
  - ISITC Market Practice v8.0 PDF

### 2026-01-31 (Session 3)
- **DEEP DIVE INTO API SPECS** - Researched actual API documentation for LSEG DSS and EDI

- **LSEG DataScope Select (DSS) - NEW FINDING:**
  - This is a DIFFERENT product from the SDK we tested
  - Endpoint: `selectapi.datascope.lseg.com` (not `api.refinitiv.com`)
  - HAS corporate actions API with comprehensive coverage
  - Request type: `CorporateActionsStandardExtractionRequest`
  - 8 event categories: DIV, CAP, MNA, SHO, PEO, EAR, NOM, VOT
  - Capital Change codes include: 13 (rights issue), 21 (split), 33 (return of capital), etc.
  - 300+ fields available
  - **No NuGet SDK** - must use REST directly
  - **Unknown if current LSEG contract includes DSS access**

- **EDI Coverage Confirmed:**
  - 45-60 event types including rights issues (explicitly documented)
  - ISO 15022 format
  - 150+ exchanges including ASX
  - API requires developer portal login for full spec
  - **DRP election coverage unclear** - need to confirm

- **NuGet Libraries:**
  - No official NuGet for LSEG DSS or EDI
  - ISO20022.Net and Iso20022 packages exist for parsing ASX format

- **Added Reference Documents section** with all source URLs

- **Created Coverage Comparison Table** - rights issues confirmed in both LSEG and EDI, but DRP election details need verification in both

### 2026-01-31 (Session 2)
- **IMPORTANT CORRECTION:** Morrison transaction data is HISTORIC only, not prospective
  - Transaction feed shows what happened to holdings (DRP shares received, etc.)
  - Does NOT include upcoming corporate actions, deadlines, or election opportunities
  - Does NOT include dividends
  - Updated Morrison section to clarify this limitation

- **DATA SOURCE RESEARCH COMPLETED:**

  | Source | Viability | Notes |
  |--------|-----------|-------|
  | ASX Real-Time Corporate Actions | ⭐ RECOMMENDED | ISO 20022 format, direct from issuers, free for ReferencePoint customers |
  | EDI (Exchange Data International) | VIABLE | REST API, may already have subscription, 150+ exchanges |
  | LSEG/Refinitiv RDP API | UNCERTAIN | SDK proven dead-end, but RDP REST API may work differently |
  | ASX Announcements (unstructured) | NOT RECOMMENDED | Would require NLP/parsing, high effort |
  | Manual Entry | VIABLE MVP | Designed detailed workflow, admin screens, notifications |

- **KEY FINDING: ASX Real-Time Corporate Actions**
  - Official ASX service with structured data (ISO 20022)
  - Delivered real-time via ASX Net, VPN, or SWIFTNet
  - Covers dividends, rights issues, mergers, buybacks, etc.
  - **Free for ASX ReferencePoint customers** - check if NQ has subscription
  - Contact: Information.Services@asx.com.au

- **MANUAL ENTRY MVP DESIGNED:**
  - Detailed admin portal screens (list, create/edit, affected HINs)
  - Minimum viable data model documented
  - Deadline notification workflow specified
  - Operations team enters data from registry emails, ASX announcements
  - Designed to easily transition to automated feed later

- Updated design document Section 14 with data source recommendations

### 2026-01-31
- Resumed from previous session
- **Recovered context from:**
  - `corporate-action-election-design.md` - Comprehensive design document (939 lines)
  - `lseg-corporate-actions-evaluation.md` - LSEG evaluation showing SDK is dead end
  - `CLAUDE.md` - Updated to include Corporate Actions as active workstream

- **Key findings from previous session:**
  - LSEG SDK (LSEG.Data.Content v2.2.2) does NOT support TR.* fundamental fields
  - No FundamentalAndReference namespace in the .NET SDK
  - Direct API calls to fundamental endpoints return 404
  - Session auth, symbology, and pricing work fine - just no corporate action data

- **Design document status:**
  - Authority model defined (MDA vs Investor Direct)
  - Data models designed (CorporateAction, CorporateActionElection entities)
  - Workflow diagrams complete (DRP and Rights Issue flows)
  - API endpoints specified for Xynon Portal
  - Morrison API requirements documented as TBD
  - MVP scope recommended: DRP elections first (4-6 weeks)

- **Alternative data sources to evaluate:**
  1. EDI feed - may include corporate actions beyond listing reference
  2. ASX announcements API - free but needs parsing
  3. Morrison notifications - clarify if they push CA data
  4. Manual entry - fallback for MVP

- **MAJOR DISCOVERY - Codebase exploration:**
  - Found comprehensive corporate action transaction mapping in `TransactionExtensions.cs`
  - Morrison equity transactions include ~100+ corporate action transaction codes
  - System already detects corporate actions AFTER they occur (DRP, rights, buybacks, takeovers)
  - This proves Morrison has corporate action data - need to ask about PROSPECTIVE access
  - Updated this file with technical details (see Technical Notes section)

---

## Corporate Action Data Structures - Research Summary

### Objective
Understand the different data structures needed to handle corporate actions. Is there one unified structure, or do different corporate action types require different data models?

### Sources Reviewed

| Source | Location | Key Contribution |
|--------|----------|------------------|
| **LSEG Data Content Guide v19.1** | `reference-data/515597.xlsx` | **DEFINITIVE** - 351 Corporate Actions fields, 350 ISO 15022 fields, all codes |
| **ISITC Corporate Actions Market Practice v8.0** | `reference-data/Corporate_Actions_Market_Practice_v8.0_Dec2022.pdf` | ISO 15022 event codes, message structures, US market practice for DRIP, rights, deadlines |
| **LSEG DSS User Guide v14.5** | `reference-data/dss_14_5_user_guide.pdf` | Event categories, coverage (95,000 companies, 145 countries) |
| **LSEG DSS SOAP API Guide** | `reference-data/dss_soap_api_programmer_guide_wsdl.pdf` | 8 event types, date field constraints, API operations |
| **LSEG Developer Portal** | https://developers.lseg.com/en/api-catalog/datascope-select/datascope-select-rest-api | REST API structure, extraction request format |
| **EDI Corporate Actions** | https://www.exchange-data.com/corporate-actions/ | 45-60 event types, ISO 15022 format, 150+ exchanges |
| **EDI Developer Portal** | https://developer.exchange-data.com/ | API endpoint (requires login for full spec) |
| **ISO 20022 CAEV Codes** | Various web sources (iotafinance.com, swift.com) | 50+ standard event type codes |

---

### Finding: There Are THREE Distinct Data Structure Categories

Corporate actions are NOT one uniform data type. Based on the research, there are **three main structural categories** that require different data models:

#### Category 1: MANDATORY (No Election Required)
**Structure:** Simple announcement → automatic processing

| Field Type | Examples |
|------------|----------|
| Event identification | Event ID, CAEV code, issuer, instrument |
| Key dates | Announcement, Ex-date, Record date, Payment date |
| Entitlement | Ratio, rate, amount per share |
| Currency | Payment currency |

**Event Types:**
- DVCA (Cash Dividend) - mandatory
- BONU (Bonus Issue)
- SPLF/SPLR (Stock Split/Reverse)
- INTR (Interest Payment)
- REDM (Redemption)
- CAPD (Capital Distribution)

**Example:** "BHP pays $1.50 dividend on 15 March to holders on record 1 March"
- No election needed
- System just needs to track dates and calculate entitlements

---

#### Category 2: VOLUNTARY (Election Required)
**Structure:** Announcement → Options → Election deadline → Instruction → Confirmation

| Field Type | Examples |
|------------|----------|
| All mandatory fields | (as above) |
| **Options array** | Each option has: code, description, default flag |
| **Election deadline** | Response deadline date/time |
| **Quantity fields** | Min/max quantities, partial election allowed |
| **Price fields** | Subscription price (for rights), discount |
| **Instruction tracking** | Election status, submission reference |

**Event Types:**
- DRIP (Dividend Reinvestment) - `CAMV//CHOS` = with choice
- DVOP (Dividend Option) - cash vs scrip
- RHTS (Rights Issue) - exercise/lapse/sell
- EXRI (Exercise Rights)
- TEND (Tender Offer) - accept/reject takeover
- BIDS (Buyback/Issuer Bid) - participate or not
- CONV (Conversion) - convert between classes
- EXOF (Exchange Offer)

**Example:** "WBC Rights Issue - subscribe at $25, deadline 28 Feb"
- Multiple options: Full exercise, Partial, Lapse, Sell rights
- Each option may have different price/quantity rules
- Deadline is critical
- Need to capture and submit instruction

**Key Finding from ISITC (line 591):**
> "Details that are specific to an option or can vary by option are to be reported at the Option Level (i.e. option code, response deadline)."

**Key Finding from ISITC (line 615):**
> "Rights Offers: The US Market processes Rights Offers as two separate events. The two events must be linked to each other."
- Event 1: RHDI (Rights Distribution) - mandatory, receive the rights
- Event 2: EXRI (Exercise Rights) - voluntary, decide what to do

---

#### Category 3: MEETING/VOTING (Proxy Required)
**Structure:** Notice → Agenda items → Proxy/Vote → Tabulation

| Field Type | Examples |
|------------|----------|
| All mandatory fields | (as above) |
| **Meeting details** | Meeting date, time, location, virtual link |
| **Agenda items array** | Resolution number, description, recommendation |
| **Voting options** | For, Against, Abstain, Discretionary |
| **Proxy fields** | Proxy deadline, proxy holder details |
| **Document references** | Notice of meeting URL, annual report URL |

**Event Types:**
- MEET (Annual General Meeting)
- GMET (General Meeting / EGM)
- OMET (Ordinary General Meeting)
- BMET (Bond Holder Meeting)
- CMET (Court Meeting) - for schemes of arrangement

**Example:** "BHP AGM on 15 Nov, proxy deadline 13 Nov"
- Multiple resolutions to vote on
- Each resolution has For/Against/Abstain options
- Proxy form needed if not attending
- Often combined with dividend announcement

**Key Finding from ISITC (line 266):**
> Actors include "Proxy Tabulator" as a distinct role in the corporate action flow.

---

### Data Model Implications

Based on these three categories, our data model needs:

```
CorporateAction (base)
├── Type: enum (DVCA, DRIP, RHTS, MEET, etc.)
├── Category: enum (Mandatory, Voluntary, Meeting)
├── Instrument: reference
├── Dates: structure
│   ├── AnnouncementDate
│   ├── ExDate
│   ├── RecordDate
│   ├── PaymentDate
│   └── EffectiveDate
├── Source: structure
│   ├── Provider (LSEG, EDI, ASX, Manual)
│   ├── ReferenceId
│   └── LastUpdated
│
├── [If Voluntary or Meeting]
│   ├── ElectionDeadline: datetime (CRITICAL)
│   ├── DefaultOption: string
│   └── Options[]: array
│       ├── OptionCode
│       ├── Description
│       ├── IsDefault
│       ├── RequiresQuantity
│       ├── MinQuantity
│       ├── MaxQuantity
│       └── Price (for rights)
│
├── [If Meeting]
│   ├── MeetingDate: datetime
│   ├── MeetingLocation: string
│   ├── ProxyDeadline: datetime
│   └── Resolutions[]: array
│       ├── ResolutionNumber
│       ├── Description
│       ├── Recommendation
│       └── VotingOptions[]
│
└── Documents[]: array
    ├── DocumentType (OfferDocument, ProxyForm, Notice, etc.)
    ├── Url
    └── Description
```

---

### LSEG DSS Event Categories (from SOAP Guide)

The LSEG API organizes into 8 categories, each with specific date constraints:

| Category | Code | Date Fields Available | Our Category |
|----------|------|----------------------|--------------|
| Capital Change | CAP | Announcement, Deal, Ex, Effective, Record | Mixed |
| Dividend | DIV | Announcement, Pay, Ex, Record | Mandatory or Voluntary |
| Earnings | EAR | Announcement, Period End | Mandatory (info) |
| Mergers & Acquisitions | MNA | Deal Announce/Cancel/Close/Effective/Revised, Tender Expiration | Voluntary |
| Nominal Value | NOM | Nominal Value Date | Mandatory |
| Public Equity Offerings | PEO | First Trade Date | Voluntary |
| Shares Outstanding | SHO | (uses ShareType sub-classification) | Voluntary |
| Voting Rights | VOT | Voting Rights Date | Meeting |

---

### ISO 15022 Message Structure (from ISITC)

The standard uses linked messages:

| Message | Purpose | When Used |
|---------|---------|-----------|
| MT564 | Corporate Action Notification | Always - announces the event |
| MT565 | Corporate Action Instruction | Voluntary - submits election |
| MT566 | Corporate Action Confirmation | After processing - confirms outcome |
| MT567 | Status and Processing Advice | Throughout - status updates |
| MT568 | Corporate Action Narrative | When MT564 exceeds 10KB - overflow text |

**Key structural finding (ISITC line 899-900):**
> "Creating multiple messages within a notification is necessary when all the information for a notification causes the MT564 and/or MT568 message to exceed the message limitation of 10,000 bytes."

This means complex events (many options, long narrative) may come as multiple linked messages.

---

### LSEG Field Mapping for Our Data Model

Based on the LSEG Data Content Guide v19.1 analysis, here's the mapping from our required fields to LSEG:

#### Core Event Fields
| Our Field | LSEG Field (Corporate Actions) | LSEG Field (ISO 15022) |
|-----------|-------------------------------|------------------------|
| Event ID | Corporate Actions ID | Event Identifier |
| Event Type | Corporate Actions Type | Event Type Code |
| Category | (derive from type) | Mandatory Voluntary Indicator Code |
| Issuer | Company Name | Issuer Name |
| Instrument | Asset ID, ISIN, CUSIP | ISIN, Common Code |

#### Date Fields
| Our Field | LSEG Field (Corporate Actions) | LSEG Field (ISO 15022) |
|-----------|-------------------------------|------------------------|
| Announcement Date | Capital Change Announcement Date, Dividend Announcement Date | Announcement Date |
| Ex Date | Capital Change Ex Date, Dividend Ex Date | Ex Date |
| Record Date | Dividend Record Date | Record Date |
| Payment Date | Dividend Pay Date | Payment Date |
| Effective Date | Effective Date, Deal Effective Date | Change Effective Date |
| **Election Deadline** | Dividend Reinvestment Deadline, Subscription Period End Date, Tender Offer Expiration Date | **Market Deadline Date** |

#### Election/Option Fields
| Our Field | LSEG Field (Corporate Actions) | LSEG Field (ISO 15022) |
|-----------|-------------------------------|------------------------|
| Is Mandatory | Capital Change Optional Flag (inverse) | Mandatory Voluntary Indicator Code |
| Default Option | (not found - derive) | Default Processing Flag |
| Options Count | (count options) | Option Number (array) |
| Option Code | Shares Offer Code, Structure Offer Number | Option Type Code |
| Option Description | Shares Offer Description | Option Type Code Description |
| Option Price | Offer Price | Option Currency Code + amount |
| Requires Quantity | (derive from type) | (derive from type) |

#### Rights Issue Specific
| Our Field | LSEG Field |
|-----------|------------|
| Rights ISIN | Rights ISIN |
| Rights Start Date | Rights Period Start Date |
| Rights End Date | Rights Period End Date |
| Renounceable | Capital Change Renounceable Flag |
| Entitlement | Entitlement |
| Shares Offered | Shares Offered |

#### Meeting/Voting Specific
| Our Field | LSEG Field |
|-----------|------------|
| Meeting Date | (via MEET events) |
| Voting Rights Date | Voting Rights Date |
| Voting Rights Per Share | Voting Rights Per Share |
| Voting Rights Description | Voting Rights Description |

#### Takeover/M&A Specific
| Our Field | LSEG Field |
|-----------|------------|
| Deal ID | Deal ID |
| Deal Type | Deal Type |
| Deal Status | Deal Status |
| Acquirer | Company Name (with Role) |
| Target | Company Name (with Role) |
| Price Per Share | Price Per Share Offered |
| Deal Value | Deal Value |

---

### What's Still Unknown

| Question | Source Needed |
|----------|---------------|
| Does EDI include election deadline as a specific field? | EDI sample data |
| ~~What document URL fields does LSEG provide?~~ | ~~LSEG Data Content Guide~~ → Not found in field list |
| How are linked events (e.g., rights distribution + exercise) represented in the API? | LSEG/EDI sample data |
| ~~What's the actual field name for "election deadline" in each provider?~~ | **LSEG: Market Deadline Date (ISO 15022) or type-specific (Standard)** |

---

### Next Steps

1. **Request EDI sample data** (email drafted in Documentation section below)
2. **Get LSEG Data Content Guide** (spreadsheet with all field definitions) - requires MyAccount login
3. **Design unified data model** that handles all three categories
4. **Map provider fields** to our model once we have sample data

---

## Complete Corporate Action Types (ISO 15022/20022 CAEV Codes)

The industry standard defines **50+ corporate action event types**. Both LSEG and EDI use ISO 15022 format.

### Full CAEV Code List

| Code | Event Type | Election? | Documents? | Notes |
|------|------------|-----------|------------|-------|
| **DIVIDENDS & INCOME** |
| DVCA | Cash Dividend | No | Dividend statement | Mandatory |
| DVOP | Dividend Option | **Yes** | Election form | Choose cash/scrip/DRP |
| DRIP | Dividend Reinvestment | **Yes** | DRP form | Enrol/change/cancel |
| DVSC | Scrip Dividend | **Yes** | Election form | Stock instead of cash |
| DVSE | Stock Dividend | No | - | Mandatory stock dividend |
| INTR | Interest Payment | No | - | Bond interest |
| CAPD | Capital Distribution | No | - | Return of capital |
| CAPG | Capital Gains Distribution | No | - | CGT implications |
| **RIGHTS & CAPITAL RAISING** |
| RHTS | Rights Issue | **Yes** | Offer document, entitlement form | Exercise/lapse/sell |
| RHDI | Rights Distribution | No | - | Initial entitlement notice |
| EXRI | Exercise Rights | **Yes** | Exercise form | Convert rights to shares |
| PRII | Priority Issue | **Yes** | Offer document | SPP, placements |
| EXOF | Exchange Offer | **Yes** | Offer document | Swap securities |
| **MEETINGS & VOTING** |
| MEET | Annual General Meeting | **Yes** | Notice of meeting, proxy form | Vote on resolutions |
| GMET | General Meeting | **Yes** | Notice of meeting, proxy form | EGM |
| OMET | Ordinary General Meeting | **Yes** | Notice of meeting, proxy form | Similar to AGM |
| BMET | Bond Holder Meeting | **Yes** | Notice, proxy | Bond specific |
| CMET | Court Meeting | **Yes** | Scheme booklet | Scheme votes |
| **M&A & RESTRUCTURING** |
| TEND | Tender Offer | **Yes** | Bidder's statement, target's statement | Accept/reject takeover |
| BIDS | Issuer Bid/Buyback | **Yes** | Buyback offer | Off-market buyback |
| MRGR | Merger | **Yes** | Scheme booklet | Vote on merger |
| EXOF | Exchange Offer | **Yes** | Offer document | Security swap |
| SOFF | Spin-Off | No | Demerger booklet | Receive new shares |
| LIQU | Liquidation | No | Liquidation statement | Final distribution |
| **CAPITAL CHANGES** |
| BONU | Bonus Issue | No | - | Free shares |
| SPLF | Stock Split (Forward) | No | - | More shares, lower price |
| SPLR | Reverse Split | No | - | Fewer shares, higher price |
| CONS | Consolidation | No | - | Share consolidation |
| CONV | Conversion | **Yes** | Conversion notice | Convert between classes |
| CHAN | Change | No | - | Name/ticker change |
| REDM | Redemption | No | - | Issuer redeems |
| MCAL | Full Call/Early Redemption | No | - | Called early |
| PCAL | Partial Redemption | No | - | Partial call |
| **OTHER** |
| DSCL | Disclosure | No | Disclosure form | Substantial holder |
| WTRC | Withholding Tax Certification | **Yes** | W-8BEN etc | Tax form required |
| CERT | TEFRA D Certification | **Yes** | Certification | US tax |
| INFO | Information Only | No | Announcement | No action required |
| DFLT | Bond Default | No | Default notice | Issuer in default |
| BRUP | Bankruptcy | No | - | Insolvency |
| OTHR | Other | Varies | Varies | Catch-all |

### Our Priority Corporate Actions

| Priority | CA Type | CAEV Code | Election Required | Document Sent |
|----------|---------|-----------|-------------------|---------------|
| **P1** | DRP Election | DRIP, DVOP | Yes - enrol/change/cancel | DRP form |
| **P1** | Rights Issue | RHTS, EXRI | Yes - exercise/lapse | Offer document, entitlement |
| **P2** | Off-market Buyback | BIDS | Yes - accept/reject | Buyback offer booklet |
| **P2** | Takeover | TEND | Yes - accept/reject | Bidder's/Target's statement |
| **P2** | Scheme of Arrangement | MRGR, CMET | Yes - vote | Scheme booklet |
| **P3** | SPP | PRII | Yes - participate | Offer letter |
| **P3** | AGM/EGM Voting | MEET, GMET | Yes - proxy/vote | Notice of meeting, proxy form |

### Document Distribution Question

**Can we get the documents (offer booklets, proxy forms) via these providers?**

| Provider | Document Access | Notes |
|----------|-----------------|-------|
| LSEG DSS | ⚠️ Unclear | May have document URLs in fields, but not confirmed |
| EDI | ⚠️ Unclear | ISO 15022 MT568 is "narrative" message for documents |
| ASX RT CA | ✅ Likely | ISO 20022 includes document references |
| **Registries** | ✅ Primary source | Computershare, Link send documents directly |

**ISO 15022 Document Messages:**
- MT564 = Corporate Action Notification (event details)
- MT565 = Corporate Action Instruction (election)
- MT566 = Corporate Action Confirmation
- MT567 = Status/Processing Advice
- **MT568 = Corporate Action Narrative** (for documents/attachments)

---

## Corporate Action Type Coverage Comparison

**Our Requirements vs Data Source Coverage:**

| CA Type | Our Need | LSEG DSS | EDI | ASX RT CA |
|---------|----------|----------|-----|-----------|
| **DRP Elections** | Enrol/change DRP participation | ⚠️ DIV category, DRIP code exists | ⚠️ Dividends covered, DRP options unconfirmed | ✅ Direct from issuer |
| **Rights Issues** | Exercise/lapse/sell rights | ✅ CAP code 13 + RHTS | ✅ Explicitly documented | ✅ Direct from issuer |
| **Buybacks** | Participate in off-market buyback | ✅ SHO category + BIDS | ✅ Mentioned in coverage | ✅ Direct from issuer |
| **Takeovers** | Accept/reject offer | ✅ MNA category + TEND | ✅ Explicitly documented | ✅ Direct from issuer |
| **Bonus Issues** | Receive bonus shares | ✅ CAP codes + BONU | ✅ Part of capital changes | ✅ Direct from issuer |
| **SPP** | Participate in share purchase plan | ✅ PEO category + PRII | ⚠️ Not explicitly mentioned | ✅ Direct from issuer |
| **AGM/EGM Voting** | Vote on resolutions | ✅ VOT category + MEET/GMET | ✅ "Voluntary actions" | ✅ Direct from issuer |
| **Schemes** | Vote on merger/demerger | ✅ MNA + MRGR/CMET | ✅ M&A covered | ✅ Direct from issuer |

**Key Dates Required:**

| Date Field | LSEG DSS | EDI | ASX RT CA |
|------------|----------|-----|-----------|
| Announcement Date | ✅ | ⚠️ Implied | ✅ |
| Record Date | ✅ | ✅ | ✅ |
| Ex Date | ✅ | ✅ | ✅ |
| Election Deadline | ⚠️ Unclear | ⚠️ "Effective Date" | ✅ |
| Payment Date | ✅ | ✅ | ✅ |
| Meeting Date | ✅ (MEET events) | ⚠️ Unclear | ✅ |

**Legend:** ✅ Confirmed | ⚠️ Likely but unconfirmed | ❌ Not available

**Assessment:**
- **ASX Real-Time CA** is most authoritative (direct from issuers) but requires subscription check
- **LSEG DSS** has comprehensive coverage including meetings (VOT category)
- **EDI** has good coverage but meeting/voting details need confirmation

---

## Data Source Evaluation

### 1. ASX Real-Time Corporate Actions ⭐ RECOMMENDED
**Status:** VIABLE - Needs subscription evaluation

**What it is:**
Official ASX service providing structured corporate action data direct from issuers.

**Key features:**
- **Format:** ISO 20022 compliant, machine-readable
- **Delivery:** Real-time via ASX Net, ALC cross connect, ASX VPN, or SWIFTNet
- **Coverage:** All corporate actions covered by ASX (dividends, rights issues, mergers, buybacks, etc.)
- **Source:** Direct from issuers = authoritative, minimal errors
- **Processing:** Straight-through processing, structured data (not PDF parsing)

**Pricing:**
- Access fees **waived for ASX ReferencePoint customers**
- Unknown if NQ/Xynon has ReferencePoint subscription

**Pros:**
- Most authoritative source (direct from ASX)
- Prospective data (as soon as announced)
- Structured format eliminates parsing
- ISO 20022 standard = well-defined schema

**Cons:**
- May require infrastructure for ASX Net connectivity
- Subscription cost if not ReferencePoint customer
- Australia-only (not an issue for current scope)

**Next steps:**
1. Check if NQ has existing ASX ReferencePoint subscription
2. Contact ASX Information Services: Information.Services@asx.com.au
3. Request sample data and integration documentation

**Source:** [ASX Real Time Corporate Actions](https://www.asx.com.au/connectivity-and-data/information-services/reference-data/real-time-corporate-actions)

---

### 2. EDI (Exchange Data International)
**Status:** VIABLE - Alternative to ASX direct

**What it is:**
Global corporate actions data provider covering 150+ exchanges including ASX.

**API Specification:**

| Endpoint | URL |
|----------|-----|
| Corporate Actions | `GET https://developer.exchange-data.com/api/.../GetLatestCorporateActions` |
| (Full spec requires login to developer portal) |

**Coverage:**
- **45-60 event types** (expanded from original 45)
- **150+ exchanges** worldwide including ASX
- **25 million corporate actions/year**
- **Updates 7 times per day**

**Event Types Confirmed:**
| Category | Events |
|----------|--------|
| Dividends | Cash dividends, special dividends |
| Capital Changes | Rights issues, stock splits, bonus issues |
| M&A | Takeovers, mergers, acquisitions |
| Other | Liquidations, class actions, purchase offers, name changes |

**Rights Issue Coverage (confirmed):**
> "Rights Offering (Issue) occurs when a company issues an offering of additional or new shares to existing shareholders based on their current holdings. Shareholders are given the option to purchase the shares being offered, at a fixed, reduced price prior to the expiration date, or sell the rights in the open market if they are transferable."

**Date Fields Available:**
- Ex-Date
- Record Date
- Pay Date
- Effective Date
- "Alerts up to 30 days before required dates"

**Data Format:**
- ISO 15022 compliant (extended for capital changes including rights issues)
- REST/JSON API
- Also available: SFTP, Amazon S3, XML, Web Portal

**DRP/DRIP Coverage:**
- Not explicitly documented
- Dividends covered, but unclear if DRP election options included
- **Need to confirm with EDI**

**Pros:**
- Already may have existing subscription (NQ uses EDI for reference data)
- REST API = easy integration
- Global coverage if needed for international expansion
- Well-established provider (since 1994, 500 employees)
- ISO 15022 compliant

**Cons:**
- Secondary source (not direct from ASX)
- DRP election details unconfirmed
- Full API spec requires developer portal login
- Unknown if current subscription includes corporate actions

**Next steps:**
1. Check current EDI subscription scope with business
2. Contact EDI: info@exchange-data.com
3. Request API documentation and Australia corporate actions sample data
4. **Specifically ask about DRP election options**

**Sources:**
- [EDI Corporate Actions](https://www.exchange-data.com/corporate-actions/)
- [EDI Developer Portal](https://developer.exchange-data.com/)
- [EDI Corporate Actions Guide](https://www.exchange-data.com/corporate-actions-guide-everything-you-need-to-know/)
- [EDI ISO 15022 Adoption](https://www.exchange-data.com/edi-adopts-iso-for-corporate-actions/)

---

### 3. LSEG DataScope Select (DSS)
**Status:** VIABLE - Separate product from SDK, has full corporate actions API

**IMPORTANT:** This is a different LSEG product from the SDK we tested. The `LSEG.Data.Content` SDK doesn't have corporate actions, but **DataScope Select REST API does**.

**API Specification:**

| Endpoint | URL |
|----------|-----|
| Authentication | `POST https://selectapi.datascope.lseg.com/RestApi/v1/Authentication/RequestToken` |
| Extraction | `POST https://selectapi.datascope.lseg.com/RestApi/v1/Extractions/Extract` |
| Field List | `GET .../GetValidContentFieldTypes(ReportTemplateType=...CorporateActions)` |

**Request Format:**
```json
{
  "ExtractionRequest": {
    "@odata.type": "#DataScope.Select.Api.Extractions.ExtractionRequests.CorporateActionsStandardExtractionRequest",
    "ContentFieldNames": ["Corporate Actions Type", "Dividend Pay Date", ...],
    "IdentifierList": {
      "@odata.type": "#...InstrumentIdentifierList",
      "InstrumentIdentifiers": [{"Identifier": "BHP.AX", "IdentifierType": "Ric"}]
    },
    "Condition": {
      "ReportDateRangeType": "Range",
      "IncludeDividendEvents": true,
      "IncludeCapitalChangeEvents": true,
      "IncludeMergersAndAcquisitionsEvents": true
    }
  }
}
```

**Event Types (8 categories):**
| Code | Category | Includes |
|------|----------|----------|
| DIV | Dividends | Cash dividends, DRP elections |
| CAP | Capital Changes | Rights issues, splits, bonus issues, scrip |
| MNA | Mergers & Acquisitions | Takeovers, schemes of arrangement |
| SHO | Shares Outstanding | Buybacks |
| PEO | Public Equity Offerings | SPP, placements |
| EAR | Earnings | Earnings announcements |
| NOM | Nominal Value | Par value changes |
| VOT | Voting Rights | Voting changes |

**Capital Change Event Type Codes (subset):**
| Code | Description |
|------|-------------|
| 13 | Non-renounceable rights issue (same stock) |
| 21 | Stock split |
| 33 | Return of capital |
| 43 | Non-renounceable scrip issue (same stock) |
| 71 | Complex capital change |
| 80 | Stock dividend (same stock) |

Full list includes: Stock Split, Stock Consolidation, Stock Dividend, Rights Issues, Scrip Issues, Write-Up/Off of Capital, Return of Capital, Capital Reduction, Spin-Off/Demerger, Unbundling, Share Buy-Back, Share Redenomination, Share Conversion, Change to No Par Value.

**Date Fields Available:**
- Dividend Announcement Date, Ex Date, Record Date, Pay Date
- Effective Date
- (300+ total fields available)

**DRP/DRIP Coverage:**
- LSEG documentation mentions "Dividends with Options (Scrip Dividends, Dividend Reinvestment Plans (DRIPs), Currency Options)"
- DRP elections appear to be covered under DIV category with options

**Pros:**
- Comprehensive corporate actions coverage
- Prospective data ("as soon as announced")
- Well-documented API
- May be accessible under existing LSEG contract

**Cons:**
- Different endpoint from what we tested (`selectapi.datascope.lseg.com` vs `api.refinitiv.com`)
- No NuGet SDK - must use REST directly
- Unknown if current contract includes DSS access

**Next steps:**
1. Check if LSEG contract includes DataScope Select
2. Test DSS endpoint with existing credentials
3. If access exists, build REST client wrapper

**Source:** [LSEG DataScope Select REST API](https://developers.lseg.com/en/api-catalog/datascope-select/datascope-select-rest-api)

---

### 4. ASX Announcements (Unstructured)
**Status:** FALLBACK - High effort

**What it is:**
Raw company announcements from ASX, released 7:30am-7:30pm AEST.

**Access options:**
- ASX Online Information Services (subscription)
- WebLink Data API (Level 1 ASX data provider)
- Third-party scrapers (unreliable)

**Challenges:**
- Announcements are semi-structured text/PDF
- Would require NLP/parsing to extract structured data
- Risk of missing or misinterpreting data
- 20-minute delay on public access

**Verdict:** Not recommended when structured alternatives exist.

---

### 5. Morrison Securities
**Status:** CLARIFIED - NOT a prospective data source

### Morrison Securities
**Status:** CLARIFIED - NOT a prospective data source

**Clarification (2026-01-31):**
The Morrison transaction feed discovery was useful context but is **NOT a solution** for the data source problem:
- Morrison transaction feed = **HISTORIC** corporate actions that affected holdings
- It does **NOT** include dividends
- It does **NOT** include elections
- It does **NOT** include FUTURE/prospective corporate actions or deadlines

What we found in `TransactionExtensions.cs` shows how Morrison reports what **already happened** to holdings (DRP shares received, rights exercised, etc.) - this is reconciliation data, not election opportunity data.

**Morrison remains relevant for:**
1. **Election submission** - API for submitting elections to registries (still TBD)
2. **Confirmation** - Receiving confirmation that elections were processed
3. **Holdings reconciliation** - Verifying current holdings before elections

**No longer relevant for:**
- Prospective corporate action data (announcements, deadlines, options)

### 6. Manual Entry (MVP Fallback)
**Status:** DESIGNED - Viable short-term option

This may be the only viable short-term option while data source agreements are negotiated.

---

## Manual Entry MVP Design

### Who Enters the Data?

**Option A: Operations Team (Recommended for MVP)**
- Dedicated ops staff monitor for corporate actions
- Single point of responsibility
- Consistent data quality
- Can be combined with registry email alerts

**Option B: Adviser Entry**
- Advisers create CAs for their clients
- Distributed workload
- Risk of inconsistency
- Not recommended for MVP

**Option C: Auto-import from PDF**
- Future enhancement, not MVP
- Would require OCR/NLP pipeline
- High development cost

**Recommendation:** Operations team enters data manually for MVP.

### Data Sources for Manual Entry

Operations team monitors these sources:
1. **Registry emails** - Many registries (Computershare, Link) send email alerts
2. **ASX announcements page** - Daily check for holdings
3. **Broker notifications** - Morrison may forward CA notices
4. **Company websites** - IR sections for active holdings

### Minimum Viable Data Model

```
CorporateAction (manual entry fields):
├── Type: dropdown (DRP, RightsIssue, Buyback, Takeover, etc.)
├── Instrument: autocomplete from holdings
├── Issuer Name: auto-filled from instrument
├── Announcement Date: date picker
├── Record Date: date picker
├── Election Deadline: date picker (CRITICAL)
├── Payment Date: date picker (optional)
├── Default Option: what happens if no election (e.g., "Cash")
├── Document URL: link to full offer document
└── Options[]: array of election options
    ├── Option Code: e.g., "FULL_DRP", "CASH", "PARTICIPATE"
    ├── Description: human-readable
    ├── Price: for rights issues
    └── Requires Quantity: boolean
```

### Admin Portal Screens

**1. Corporate Actions List**
```
┌─────────────────────────────────────────────────────────────┐
│ Corporate Actions                           [+ New Action]  │
├─────────────────────────────────────────────────────────────┤
│ Filter: [All Types ▼] [Open ▼] [Search...]                 │
├─────────────────────────────────────────────────────────────┤
│ Type      │ Issuer   │ Deadline   │ Affected │ Status      │
├───────────┼──────────┼────────────┼──────────┼─────────────┤
│ DRP       │ BHP      │ 2026-02-15 │ 45 HINs  │ Open        │
│ Rights    │ WBC      │ 2026-02-08 │ 12 HINs  │ Closing Soon│
│ Buyback   │ CBA      │ 2026-01-28 │ 8 HINs   │ Closed      │
└───────────┴──────────┴────────────┴──────────┴─────────────┘
```

**2. Create/Edit Corporate Action**
```
┌─────────────────────────────────────────────────────────────┐
│ New Corporate Action                                        │
├─────────────────────────────────────────────────────────────┤
│ Type:        [DRP ▼]                                        │
│ Instrument:  [BHP.AX ▼] (search holdings)                   │
│ Issuer:      BHP Group Limited (auto-filled)                │
│                                                             │
│ ── Timeline ──                                              │
│ Announcement: [2026-01-15]                                  │
│ Record Date:  [2026-01-20]                                  │
│ Deadline:     [2026-02-15] ⚠️ Required                      │
│ Payment:      [2026-03-01]                                  │
│                                                             │
│ ── Options ──                                               │
│ Default if no election: [Cash ▼]                            │
│                                                             │
│ [+ Add Option]                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Code: FULL_DRP    Description: Full participation       │ │
│ │ Requires quantity: ☐                            [Delete]│ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Code: PARTIAL_DRP Description: Partial participation    │ │
│ │ Requires quantity: ☑                            [Delete]│ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ Document URL: [https://...]                                 │
│                                                             │
│ [Cancel]                              [Save & Identify HINs]│
└─────────────────────────────────────────────────────────────┘
```

**3. Affected HINs View**
After saving, system auto-identifies affected HINs from holdings:
```
┌─────────────────────────────────────────────────────────────┐
│ BHP DRP - Affected Holdings (45 HINs)                       │
├─────────────────────────────────────────────────────────────┤
│ HIN          │ Account      │ Holding │ Election Status     │
├──────────────┼──────────────┼─────────┼─────────────────────┤
│ X0012345678  │ Smith Family │ 1,000   │ Pending             │
│ X0012345679  │ Jones SMSF   │ 5,000   │ Pending             │
│ ...                                                         │
└─────────────────────────────────────────────────────────────┘
```

### Deadline and Notification Handling

**System-generated notifications:**
| Trigger | Recipients | Channel |
|---------|-----------|---------|
| New CA created | All affected investors + advisers | Email, In-app |
| 7 days to deadline | Accounts without election | Email |
| 3 days to deadline | Accounts without election | Email, SMS (opt-in) |
| 1 day to deadline | Accounts without election | Email, SMS, Push |
| Deadline passed | Ops team | Internal alert |

**Deadline monitoring job:**
```csharp
// Daily job at 6am
public async Task CheckDeadlines()
{
    // Find CAs with deadline today
    var closingToday = await GetCorporateActionsClosingOn(DateOnly.FromDateTime(DateTime.Today));
    foreach (var ca in closingToday)
    {
        // Mark as closed
        ca.Status = CorporateActionStatus.Closed;

        // Alert on accounts without elections
        var pendingAccounts = await GetAccountsWithoutElection(ca.Id);
        if (pendingAccounts.Any())
        {
            await AlertOpsTeam($"{ca.IssuerName} deadline reached, {pendingAccounts.Count} accounts defaulted");
        }
    }
}
```

### Manual Entry Workflow Summary

```
1. Ops receives notification (email, announcement check)
         │
         ▼
2. Ops creates CorporateAction in admin portal
         │
         ▼
3. System auto-identifies affected HINs from holdings
         │
         ▼
4. System sends notifications to investors/advisers
         │
         ▼
5. Investors/advisers make elections via portal
         │
         ▼
6. Elections submitted to Morrison (when API ready)
         │
         ▼
7. Deadline monitoring catches any defaulted accounts
```

### Pros of Manual Entry MVP

- **Launch immediately** - No vendor negotiations needed
- **Prove the workflow** - Validates election capture and submission
- **Full control** - Ops can add custom notes, handle edge cases
- **Learn requirements** - Discover what automated feed needs to provide

### Cons of Manual Entry MVP

- **Operational overhead** - Someone must monitor and enter data
- **Risk of missing CAs** - Human error, illness, holidays
- **Doesn't scale** - Workload grows with client base
- **Deadline risk** - Manual monitoring less reliable

### Transition to Automated Feed

Manual entry design supports easy transition:
1. Admin portal remains for **override/correction**
2. Automated feed creates CorporateAction records instead of ops
3. Same notification and election workflow
4. Ops focuses on exceptions/escalations

---

---

## Open Questions for Business

1. **Morrison relationship:** What corporate action services does Morrison currently provide? Are they open to API development for elections?

2. **Current process:** How are corporate action elections handled today? Entirely paper-based via registry?

3. **Volume:** How many corporate action elections per month/quarter? (Helps prioritise automation)

4. **Priority:** Is DRP the right starting point, or are rights issues more urgent?

5. **EDI contract:** What is included in the current EDI subscription? Who is the contact?

---

## Technical Notes

### Existing Integration Points (from design doc)
- Morrison REST API exists for orders, accounts, positions
- `IMorrisonProxy` interface in codebase
- `NQ.Trading.Models` has basic `CorporateActionType` enum (Dividend, Split)
- Activity workflow pattern available for election lifecycle

### Key Codebase Discovery (2026-01-31)

**IMPORTANT: Comprehensive corporate action transaction mapping already exists!**

Location: `C:\Users\Micha\Source\repos\NQ\NQ Morrison\NQ.Morrison.API\Util\TransactionExtensions.cs`

This file contains:
- `CorporateActionType` enum with: Dividend, RightsIssue, BonusIssue, SplitConsolidation, CapitalReturn, TakeoverScheme, Interest, Distribution, Buyback
- `DetectCorporateAction()` function that maps ~100+ transaction codes to corporate action types
- Complete transaction code sets for:
  - **Dividends**: DRP, DRP-DEC, DRP-INC, DDV, SCD-DEC/INC, etc.
  - **Rights Issues**: DRT, NRE-DEC/INC, RAC-DEC/INC, RHA-DEC/INC, RHE-DEC/INC, etc.
  - **Bonus Issues**: BON-DEC/INC, DBN, BSP-DEC/INC, etc.
  - **Buybacks**: BYB-DEC/INC, DBB
  - **Takeovers**: TKA-DEC/INC, TKO-DEC/INC, SOA-DEC/INC, CAQ-DEC/INC

This proves that **Morrison already sends corporate action transaction data via their equity transaction feed**. The system can detect when corporate actions have occurred (after the fact).

**Implication for data source strategy:**
1. Morrison transaction feed provides HISTORICAL corporate action data (after execution)
2. What we NEED is PROSPECTIVE data (before deadline) to enable elections
3. Morrison may have access to this data - need to ask if they can provide CA announcements

### Morrison REST Proxy Current Capabilities
Location: `C:\Users\Micha\Source\repos\NQ\NQ-NugetLibraries\NQ.Trading\NQ.Trading.SharedServices\ApiProxy\MorrisonRestProxy.cs`

Current endpoints:
- `CreateAccount` - Account creation with HIN
- `GetAccountStatus` - Account status lookup
- `SendOrders` / `SendOrder` - Order placement
- `GetContractNotes` - Contract note retrieval
- `GetOrder` / `GetOrders` - Order status
- `CalculateDriftAsync` - Portfolio drift calculation
- `CreateOrdersAsync` / `CreateOrdersBatchAsync` - Rebalancing orders

**NOT present:** Any corporate action related endpoints (confirms this is a gap to address with Morrison)

### Files to reference
| File | Purpose |
|------|---------|
| `Tmw.Api/Services/Operations/OperationWorkflowService.cs` | Election workflow pattern |
| `NQ.Trading.SharedServices/ApiProxy/MorrisonRestProxy.cs` | Morrison integration pattern |
| `NQ.Lseg/` | Existing LSEG integration (pricing/symbology only) |
| `NQ Morrison/NQ.Morrison.API/Util/TransactionExtensions.cs` | **Corporate action detection logic** |
| `NQ Morrison/NQ.Morrison.API/Util/EquityTransactionTypes.cs` | **Full transaction code definitions** |

---

## Documentation Downloaded and Analyzed

### LSEG DataScope Select
| Document | Location | Status |
|----------|----------|--------|
| **Data Content Guide v19.1** | `reference-data/515597.xlsx` | ✅ ANALYZED - 701 fields extracted |
| **User Guide v14.5** | `reference-data/dss_14_5_user_guide.pdf` | ✅ Converted to text, reviewed |
| **SOAP API Guide** | `reference-data/dss_soap_api_programmer_guide_wsdl.pdf` | ✅ Converted to text, reviewed |

### Extracted Data Files
| File | Contents |
|------|----------|
| `report_types_extract.json` | 25 report types including Corporate Actions |
| `field_definitions_extract.json` | First 200 rows of field definitions |
| `code_descriptions_extract.json` | First 300 rows of code descriptions |

### Key Findings from LSEG Data Content Guide
- **Corporate Actions template**: 351 fields covering dividends, capital changes, M&A, IPOs
- **Debt Corporate Actions (ISO 15022)**: 350 fields with full ISO 15022 structure
- **Election fields confirmed**: Market Deadline Date, Option Number, Option Type Code, Mandatory Voluntary Indicator
- **Rights issue fields**: Rights ISIN, Rights Period Start/End Date, Renounceable Flag, Entitlement
- **Meeting/voting fields**: Voting Rights Date, Voting Rights Per Share, Voting Rights Description

### Still To Download/Review
| Document | Download URL | What I Need From It |
|----------|--------------|---------------------|
| **DSS Plus Upgrade Guide** | https://developers.lseg.com/content/dam/devportal/articles/datascope-equities-and-datascope-fixed-income-upgrade-to-datascope-plus/documents/dsp_upgrade_guide_dse_feb2023.pdf | Capital change event codes (low priority now) |

### EDI - What You Need to Get

**Option 1: Developer Portal Registration**
1. Go to https://developer.exchange-data.com/
2. Register for an account
3. Access the API Playground
4. Download/export the API documentation for "World Corporate Actions" (GetLatestCorporateActions endpoint)

**Option 2: Request Sample Data (Recommended)**
Email: info@exchange-data.com

```
Subject: Corporate Actions API - Sample Data Request for ASX

We are evaluating EDI's World Corporate Actions service for Australian (ASX) securities.

Could you please provide:

1. API Documentation / Swagger spec for GetLatestCorporateActions endpoint
2. Sample data file (CSV or JSON) showing:
   - DRP/Dividend Reinvestment events (with election options)
   - Rights Issues (with entitlement details)
   - Off-market Buybacks
   - Takeover/Tender offers
   - AGM/General Meeting notifications

3. Complete field list with descriptions, specifically:
   - Date fields (announcement, record, ex, deadline, payment)
   - Election/option fields
   - Document URL fields (if any)

4. Confirmation of ASX coverage depth

We have an existing EDI subscription for reference data - please confirm
if corporate actions is included or separate.
```

**What I need to review:**
| Item | Why |
|------|-----|
| Field list (CSV/Excel) | To map to our data model |
| Sample JSON response | To understand actual data structure |
| Event type codes | To compare with ISO 15022 CAEV codes |
| Date field names | To confirm election deadline is available |
| ASX sample data | To verify Australian coverage |

### ISO 15022 Standards - PDFs to Download
| Document | Download URL | What I Need From It |
|----------|--------------|---------------------|
| **ISITC Corporate Actions Market Practice v8.0** | https://isitc.org/wp-content/uploads/Corporate_Actions_Market_Practice_v8.0_Dec2022.pdf | Complete CAEV code list with usage |
| **DTCC Getting Started with ISO 20022** | https://www.dtcc.com/-/media/Files/Downloads/issues/Corporate-Actions-Transformation/Getting_Started_CA_ISO_20022.pdf | ISO 20022 message structure |

### Suggested Download Location
Save to: `C:\Users\Micha\AppData\Local\Temp\claude\...\scratchpad\corporate-actions-docs\`

Or add to project: `C:\Users\Micha\source\repos\nq\ClaudePortal\docs\corporate-actions\`

---

## Reference Documents

### LSEG DataScope Select
| Document | URL | Content |
|----------|-----|---------|
| REST API Portal | https://developers.lseg.com/en/api-catalog/datascope-select/datascope-select-rest-api | Main API documentation |
| Tutorial 5: Corporate Actions | https://developers.lseg.com/en/api-catalog/datascope-select/datascope-select-rest-api/tutorials/rest-api-tutorials/rest-api-tutorial-5--on-demand-corporate-actions-extraction | Request format, field list endpoint |
| User Guide v14.5 (PDF) | https://developers.lseg.com/content/dam/devportal/api-families/datascope-select/datascope-select-rest-api/documentation/overview-and-concepts/dss_14_5_user_guide.pdf | Full documentation |
| SOAP API Guide (WSDL) | https://developers.lseg.com/content/dam/devportal/api-families/datascope-select/datascope-select-soap-api/documentation/development/dss_soap_api_programmer_guide_wsdl.pdf | Event type codes |
| Corporate Actions Overview | https://www.lseg.com/en/data-analytics/financial-data/corporate-actions-data | Product description |

### EDI (Exchange Data International)
| Document | URL | Content |
|----------|-----|---------|
| Developer Portal | https://developer.exchange-data.com/ | API playground (requires login) |
| Corporate Actions Product | https://www.exchange-data.com/corporate-actions/ | Service overview |
| Worldwide Corporate Actions | https://www.exchange-data.com/product/worldwide-corporate-actions-data/ | Coverage details |
| ISO 15022 Adoption | https://www.exchange-data.com/edi-adopts-iso-for-corporate-actions/ | Format details |
| Corporate Actions Guide | https://www.exchange-data.com/corporate-actions-guide-everything-you-need-to-know/ | Event type explanations |
| Types Explained | https://www.exchange-data.com/explaining-the-main-types-of-corporate-action-data-and-what-they-mean/ | Rights issues, etc. |

### ASX Real-Time Corporate Actions
| Document | URL | Content |
|----------|-----|---------|
| Product Page | https://www.asx.com.au/connectivity-and-data/information-services/reference-data/real-time-corporate-actions | Service overview |
| Fact Sheet (PDF) | https://www.asx.com.au/content/dam/asx/connectivity-and-data/real-time-corporate-actions-factsheet.pdf | Format, delivery |
| Manual v3.0 (PDF) | https://www.asx.com.au/content/dam/asx/participants/clearing-and-settlement/settlement/asx-referencepoint-iso-20022-real-time-corporate-actions-manual-v3.0.pdf | Full specification |

### ISO 20022 NuGet Packages
| Package | URL | Purpose |
|---------|-----|---------|
| ISO20022.Net | https://www.nuget.org/packages/ISO20022.Net | Parse/create ISO 20022 messages |
| Iso20022 | https://www.nuget.org/packages/Iso20022 | Data contracts for (de)serialization |

---

## Session Handoff Notes

When resuming this work:
1. Check if any blockers have been resolved (Morrison API, EDI subscription)
2. Review any new requirements or priority changes
3. If data source identified, update design doc with integration details
4. If proceeding with manual entry MVP, design admin portal screens
