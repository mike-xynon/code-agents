# Corporate Action Election System - Design Document

> **Status:** Draft for Review - Awaiting data source decision
> **Created:** 2026-01-30
> **Updated:** 2026-01-31
> **Author:** Claude (Design Phase)

---

## 1. Executive Summary

This document outlines the design for digitising corporate action elections, providing authenticated instruction capture from investors/advisers, transmission through Morrison (sponsoring broker) to share registries, with full audit trail.

**Goal:** Replace paper-based election processes with digital workflow that provides:
- Superior provenance (verified identity, authenticated sessions, timestamps)
- Dual authority paths (MDA-authorised adviser OR investor direct)
- Full audit trail meeting RG179 requirements
- Faster turnaround than manual processes

---

## 2. Current Understanding

### 2.1 The Legal Framework

```
[Investor/HIN Holder] ←── Legal Relationship ──→ [Share Registry]
        ↑                                              ↑
        │ We provide better                            │
        │ instruction mechanism                        │
        ↓                                              │
    [Xynon Portal]                                     │
        │                                              │
        │ Authenticated election                       │
        ↓                                              │
    [Morrison Securities] ────── Submission ───────────┘
      (Sponsoring Broker)
```

**Key Insight:** We don't replace the legal relationship. We provide a superior instruction path with better verification than paper, sitting alongside the investor↔registry relationship.

### 2.2 Morrison's Current Process (Assumed - Needs Verification)

Based on codebase exploration, Morrison currently handles:
- **Order execution** via REST API (`IMorrisonProxy`)
- **Account creation** with HIN assignment
- **Holdings reconciliation** via financial position endpoint
- **Contract notes** retrieval

**Open Question #1:** What is Morrison's current API for corporate action election submission? Is there an existing endpoint, or does this require new development on Morrison's side?

### 2.3 Existing Patterns in Portal

The Portal codebase provides excellent patterns for this system:

| Pattern | Location | Relevance |
|---------|----------|-----------|
| Activity Workflow | `DbUserActivity`, `OperationWorkflowService` | Election lifecycle management |
| Multi-party Approval | `ApprovalRequest`, `IVerbOperation` | Adviser/investor consent capture |
| Role-based Access | `AccountRoleType`, `DbAccountRole` | Authority verification |
| Invitation/Consent | `InvitationService`, `DbInvitation` | Fresh consent capture |
| Audit Trail | `DbUserActivity` timestamps, `Data`/`ExecutionData` JSONB | Full election provenance |
| State Machine | `OnboardingStateMachine` | Complex election flow routing |

### 2.4 Existing Models in NuGet Libraries

| Model | Location | Relevance |
|-------|----------|-----------|
| `CorporateActionType` | `NQ.Trading.Models` | Basic enum (Dividend, Split) - needs extension |
| `DtoInstrumentIncome` | `NQ.Trading.Models` | Dividend/income data from LSEG |
| `EntityBase` | `NQ.CoreData` | Audit trail base class |
| `TransactionFlagDto` | `NQ.Trading.Models` | Status/document attachment pattern |
| `CashAllocationInstructionDto` | `NQ.Trading.Models` | Instruction pattern (placeholder) |

---

## 3. Authority Model

### 3.1 Two Authority Paths

**Path A: Adviser with MDA Authority**
```
Adviser → [Xynon validates MDA scope] → Election submitted with authority recorded
```
- Adviser has discretionary authority under MDA agreement
- System records: "Submitted under MDA authority per agreement dated X"
- No fresh consent required (authority already exists)
- **Risk:** Corporate actions may be outside discretionary scope (RG179 grey area)

**Path B: Investor Personal Decision**
```
Investor → [Xynon captures explicit consent] → Election submitted with consent recorded
```
- Investor makes personal decision
- Fresh consent captured with timestamp
- Explicit acknowledgement recorded
- Adviser may be notified but does not authorise

### 3.2 RG179 Grey Area Handling

Corporate actions potentially outside MDA discretionary scope:
- **Material elections** affecting portfolio strategy (rights issues, takeovers)
- **Tax-impacting decisions** requiring personal advice
- **Concentration-affecting** elections (rights issues can increase exposure)

**Proposed Approach:**

```csharp
public enum ElectionAuthorityType
{
    MdaDiscretionary,      // Simple elections within clear MDA scope
    MdaWithNotification,   // MDA scope but investor notified
    InvestorDirect,        // Investor personal decision
    AdviserRecommended     // Adviser recommends, investor consents
}

public record ElectionAuthority
{
    public ElectionAuthorityType Type { get; init; }
    public Guid AuthorisingUserId { get; init; }
    public DateTimeOffset AuthorisedAt { get; init; }
    public string? MdaAgreementReference { get; init; }
    public string? ConsentStatement { get; init; }
    public string? AdviserRationale { get; init; }  // For MDA decisions
}
```

**Business Rule:** For MVP, classify elections:

| Election Type | Default Authority Path | Override Allowed |
|---------------|----------------------|------------------|
| DRP election | MdaDiscretionary | Yes (investor can override) |
| Rights issue participation | InvestorDirect | Can be MdaWithNotification if documented |
| Off-market buyback | InvestorDirect | Complex tax implications |
| Takeover acceptance | InvestorDirect | Material decision |

---

## 4. Proposed Data Models

### 4.1 Core Entities

```csharp
// Corporate action event from registry/market data
public class CorporateAction : EntityBase
{
    public Guid CorporateActionId { get; set; }
    public CorporateActionType Type { get; set; }

    // Source information
    public Guid InstrumentId { get; set; }
    public string InstrumentSymbol { get; set; }  // e.g., "BHP.AX"
    public string IssuerName { get; set; }

    // Timeline
    public DateOnly AnnouncementDate { get; set; }
    public DateOnly RecordDate { get; set; }
    public DateOnly ElectionDeadline { get; set; }
    public DateOnly? PaymentDate { get; set; }

    // Election options (JSONB)
    public List<ElectionOption> Options { get; set; }

    // Default if no election made
    public string DefaultOptionCode { get; set; }

    // Source reference
    public string RegistryReference { get; set; }
    public string? DocumentUrl { get; set; }
}

public enum CorporateActionType
{
    DividendReinvestmentPlan,
    DividendReinvestmentPlanChange,  // Changing existing DRP
    RightsIssue,
    RightsIssueRenounceable,
    OffMarketBuyback,
    TakeoverOffer,
    SchemeOfArrangement,
    SharePurchasePlan,
    Demerger
}

public class ElectionOption
{
    public string OptionCode { get; set; }        // e.g., "FULL_DRP", "PARTIAL_DRP", "CASH"
    public string Description { get; set; }
    public decimal? Price { get; set; }           // For rights issues
    public decimal? Discount { get; set; }        // Percentage discount
    public decimal? MinQuantity { get; set; }
    public decimal? MaxQuantity { get; set; }
    public bool RequiresQuantity { get; set; }    // User must specify quantity
    public bool RequiresCash { get; set; }        // User must have/provide cash
}
```

### 4.2 Election Record

```csharp
// Individual election decision
public class CorporateActionElection : EntityBase
{
    public Guid ElectionId { get; set; }
    public Guid CorporateActionId { get; set; }
    public Guid AccountId { get; set; }
    public string Hin { get; set; }               // HIN for registry submission

    // Election details
    public string SelectedOptionCode { get; set; }
    public decimal? ElectedQuantity { get; set; } // For partial elections
    public decimal? HoldingAtElection { get; set; } // Snapshot of holding

    // Authority tracking
    public ElectionAuthority Authority { get; set; }  // JSONB

    // Status
    public ElectionStatus Status { get; set; }

    // Submission tracking
    public DateTimeOffset? SubmittedToMorrison { get; set; }
    public string? MorrisonReference { get; set; }
    public DateTimeOffset? ConfirmedByRegistry { get; set; }
    public string? RegistryReference { get; set; }

    // Error handling
    public string? RejectionReason { get; set; }
    public int RetryCount { get; set; }
}

public enum ElectionStatus
{
    // Pre-submission
    Draft,                    // Started but not submitted
    PendingInvestorConsent,   // Awaiting investor action
    PendingAdviserAction,     // Awaiting adviser decision

    // Submission
    ReadyForSubmission,       // Authorised, queued for Morrison
    SubmittedToMorrison,      // Sent to Morrison

    // Confirmation
    ConfirmedByRegistry,      // Registry acknowledged
    Processed,                // Corporate action completed

    // Terminal states
    Cancelled,                // User cancelled
    Expired,                  // Deadline passed without election
    Rejected,                 // Morrison or registry rejected
    Failed                    // Technical failure
}
```

### 4.3 Audit Trail (Using Existing Pattern)

```csharp
// Extends DbUserActivity for election workflow
// OperationName = "CorporateActionElection"

public class ElectionActivityData  // Stored in DbUserActivity.Data
{
    public Guid CorporateActionId { get; set; }
    public Guid ElectionId { get; set; }
    public string ActionType { get; set; }        // "DRP", "RightsIssue", etc.
    public string IssuerName { get; set; }
    public string InstrumentSymbol { get; set; }
    public DateOnly Deadline { get; set; }
    public List<ElectionOption> Options { get; set; }
    public decimal HoldingQuantity { get; set; }
}

public class ElectionExecutionData  // Stored in DbUserActivity.ExecutionData
{
    public string SelectedOptionCode { get; set; }
    public decimal? ElectedQuantity { get; set; }
    public ElectionAuthority Authority { get; set; }
    public string MorrisonReference { get; set; }
    public string RegistryReference { get; set; }
    public DateTimeOffset ProcessedAt { get; set; }
}
```

---

## 5. Workflow Diagrams

### 5.1 DRP Election Flow (Simple Case)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DRP Election Workflow                           │
└─────────────────────────────────────────────────────────────────────────┘

[Corporate Action Announced]
         │
         ▼
┌─────────────────────┐
│ Xynon receives CA   │  ← From market data feed or Morrison notification
│ Creates CA record   │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│ Identify affected   │  ← Match instrument to holdings
│ accounts/HINs       │
└─────────────────────┘
         │
         ▼
┌─────────────────────┐
│ Create activities   │  ← DbUserActivity for each affected account
│ for notification    │
└─────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
[Adviser    [Investor
 View]       View]
    │         │
    │    ┌────┴────────────────────────┐
    │    │                             │
    ▼    ▼                             ▼
┌─────────────┐                 ┌─────────────┐
│ Path A:     │                 │ Path B:     │
│ MDA Scope   │                 │ Personal    │
└─────────────┘                 └─────────────┘
    │                                 │
    ▼                                 ▼
┌─────────────────────┐       ┌─────────────────────┐
│ Adviser selects     │       │ Investor reviews    │
│ option, records     │       │ options, selects,   │
│ MDA rationale       │       │ provides consent    │
└─────────────────────┘       └─────────────────────┘
    │                                 │
    └────────────┬────────────────────┘
                 ▼
┌─────────────────────────────────────┐
│ Election record created             │
│ - Authority captured                │
│ - Status: ReadyForSubmission        │
│ - Audit: timestamp, user, IP, etc.  │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ Submit to Morrison                  │
│ - API call with election details    │
│ - Status: SubmittedToMorrison       │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ Morrison routes to registry         │
│ (via CHESS or direct)               │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│ Confirmation received               │
│ - Status: ConfirmedByRegistry       │
│ - Notify investor/adviser           │
└─────────────────────────────────────┘
```

### 5.2 Rights Issue Flow (Complex Case)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Rights Issue Workflow                              │
└─────────────────────────────────────────────────────────────────────────┘

[Rights Issue Announced]
         │
         ▼
┌─────────────────────────────────────┐
│ Xynon receives CA with details:     │
│ - Issue price, discount             │
│ - Record date, deadline             │
│ - Pro-rata entitlement ratio        │
│ - Renounceable or not               │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Calculate entitlements per HIN      │
│ - Holding × ratio = entitlement     │
│ - Cash required = ent × price       │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Create high-priority activities     │  ← Rights issues are time-sensitive
│ - Deadline prominently displayed    │
│ - Push notification if enabled      │
└─────────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
[Adviser    [Investor
 View]       View]
    │         │
    │         │
    ▼         ▼
┌─────────────────────────────────────┐
│ CRITICAL: Rights issues typically   │
│ require investor decision due to:   │
│ - Cash outlay required              │
│ - Concentration impact              │
│ - Dilution if not exercised         │
│                                     │
│ → Default to InvestorDirect path    │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Adviser can:                        │
│ a) Notify investor with rec         │
│ b) Request investor decision        │
│ c) Submit under MDA (with flag)     │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Investor decision required:         │
│ - View entitlement details          │
│ - Check available cash              │
│ - Select: Full/Partial/Lapse        │
│ - Acknowledge implications          │
│ - Explicit consent captured         │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ If partial exercise:                │
│ - Cash check for amount             │
│ - Remaining rights: lapse or sell?  │
│   (if renounceable)                 │
└─────────────────────────────────────┘
         │
         ▼
[Continue to submission as above]
```

---

## 6. API Design

### 6.1 Xynon Portal API Endpoints

```
Corporate Actions (Read)
------------------------
GET  /api/corporate-actions
     → List active corporate actions affecting user's accounts
     → Filters: accountId, type, status, deadline

GET  /api/corporate-actions/{corporateActionId}
     → Corporate action details with options

GET  /api/accounts/{accountId}/corporate-actions
     → Corporate actions for specific account

GET  /api/accounts/{accountId}/corporate-actions/{corporateActionId}/entitlement
     → Calculated entitlement for rights issues


Elections (Read/Write)
----------------------
GET  /api/accounts/{accountId}/elections
     → List elections for account
     → Filters: status, corporateActionId

GET  /api/elections/{electionId}
     → Election details with audit trail

POST /api/accounts/{accountId}/elections
     → Create new election
     Body: {
       corporateActionId: guid,
       selectedOptionCode: string,
       electedQuantity?: number,
       authority: {
         type: "MdaDiscretionary" | "InvestorDirect",
         consentStatement?: string,
         adviserRationale?: string
       }
     }

PUT  /api/elections/{electionId}
     → Update draft election (before submission)

DELETE /api/elections/{electionId}
     → Cancel draft election


Adviser Endpoints
-----------------
GET  /api/adviser/corporate-actions
     → All corporate actions across advised accounts
     → Grouped by action, showing counts

GET  /api/adviser/corporate-actions/{corporateActionId}/accounts
     → All advised accounts affected by this action

POST /api/adviser/elections/bulk
     → Submit elections for multiple accounts
     Body: {
       corporateActionId: guid,
       elections: [{
         accountId: guid,
         selectedOptionCode: string,
         electedQuantity?: number
       }],
       authority: {
         type: "MdaDiscretionary",
         adviserRationale: string
       }
     }
```

### 6.2 Morrison API Requirements (TBD)

**Open Question #2:** What API does Morrison need to provide?

```
Proposed Morrison API (Needs Discussion)
----------------------------------------

POST /api/corporate-actions/elections
     → Submit election to registry
     Body: {
       hin: string,
       corporateActionRef: string,  // Registry reference
       optionCode: string,
       quantity?: number,
       authorityType: string,
       xynon Reference: string      // Our tracking ID
     }

     Response: {
       morrisonReference: string,
       status: "Submitted" | "Queued" | "Rejected",
       rejectionReason?: string
     }

GET  /api/corporate-actions/elections/{morrisonReference}
     → Check election status

     Response: {
       status: "Pending" | "Confirmed" | "Rejected",
       registryReference?: string,
       confirmedAt?: datetime,
       rejectionReason?: string
     }

Webhook (Optional)
------------------
POST [Xynon callback URL]
     → Morrison notifies Xynon of status changes
     Body: {
       morrisonReference: string,
       xynonReference: string,
       status: string,
       registryReference?: string,
       timestamp: datetime
     }
```

---

## 7. Audit Trail Requirements

### 7.1 What Must Be Captured

Per RG179 and best practice, every election must record:

| Field | Purpose | Source |
|-------|---------|--------|
| Who made the election | Identity verification | Authenticated user ID |
| When they made it | Timeline proof | Server timestamp |
| Under what authority | Legal basis | Authority type + reference |
| What they elected | Decision record | Option code + quantity |
| What they saw | Informed decision proof | Snapshot of options shown |
| What holding they had | Context | Holding at time of election |
| IP address | Additional verification | Request metadata |
| User agent | Session context | Request metadata |
| Session start time | Engagement context | Auth session |

### 7.2 Implementation Using Existing Patterns

```csharp
// DbUserActivity usage for elections
var activity = new DbUserActivity
{
    OperationName = OperationNames.CorporateActionElection,
    UserId = electionUserId,
    AccountId = accountId,
    Status = UserActivityStatus.Created,

    // Election details (JSONB)
    Data = JsonSerializer.Serialize(new ElectionActivityData
    {
        CorporateActionId = corporateAction.Id,
        ActionType = corporateAction.Type.ToString(),
        IssuerName = corporateAction.IssuerName,
        InstrumentSymbol = corporateAction.InstrumentSymbol,
        Deadline = corporateAction.ElectionDeadline,
        Options = corporateAction.Options,
        HoldingQuantity = currentHolding
    }),

    // Set on completion
    ExecutionData = null,  // Populated when submitted

    Description = $"{corporateAction.Type} election for {corporateAction.IssuerName}",
    Expiry = corporateAction.ElectionDeadline.ToDateTime(TimeOnly.MaxValue),

    // Adviser tracking if applicable
    AdvisedById = isAdviserSubmission ? adviserId : null
};
```

### 7.3 Comparison to Paper Process

| Aspect | Paper Process | Xynon Digital |
|--------|---------------|---------------|
| Identity verification | Wet signature (easily forged) | Authenticated session with MFA |
| Timestamp | Post office or fax timestamp | Cryptographic server timestamp |
| Authority proof | Cover letter (if any) | Recorded authority type + MDA reference |
| Chain of custody | Manual handling, easily lost | Full database audit trail |
| Searchability | Physical filing cabinets | Instant query |
| Provenance | Weak | Strong (who, when, what, how) |

---

## 8. Notification & Deadline Management

### 8.1 Notification Types

| Event | Channel | Recipient | Timing |
|-------|---------|-----------|--------|
| New corporate action | Email + In-app | Investor + Adviser | On receipt |
| Deadline approaching | Email + SMS (opt-in) | Investor + Adviser | 7 days, 3 days, 1 day |
| Election submitted | Email + In-app | Investor | Immediate |
| Election confirmed | Email + In-app | Investor + Adviser | On confirmation |
| Election rejected | Email + In-app + SMS | Investor + Adviser | Immediate |

### 8.2 Deadline Handling

```csharp
public class DeadlineService
{
    // Schedule deadline reminders
    public async Task ScheduleReminders(CorporateAction action)
    {
        var deadlines = new[]
        {
            (action.ElectionDeadline.AddDays(-7), "7 days until deadline"),
            (action.ElectionDeadline.AddDays(-3), "3 days until deadline"),
            (action.ElectionDeadline.AddDays(-1), "Final day to elect")
        };

        foreach (var (date, message) in deadlines)
        {
            if (date > DateOnly.FromDateTime(DateTime.UtcNow))
            {
                await _scheduler.Schedule<ElectionReminderJob>(
                    date.ToDateTime(TimeOnly.Parse("09:00")),
                    new { action.CorporateActionId, message }
                );
            }
        }
    }

    // Handle expired elections
    public async Task ProcessExpiredElections()
    {
        var expired = await _db.Elections
            .Where(e => e.Status == ElectionStatus.Draft
                     || e.Status == ElectionStatus.PendingInvestorConsent)
            .Where(e => e.CorporateAction.ElectionDeadline < DateOnly.FromDateTime(DateTime.UtcNow))
            .ToListAsync();

        foreach (var election in expired)
        {
            election.Status = ElectionStatus.Expired;
            // Log that default option will apply
            await _notificationService.SendElectionExpiredNotification(election);
        }
    }
}
```

---

## 9. Open Questions

### Critical (Blocking MVP)

1. **Morrison API:** What is Morrison's current/planned API for corporate action election submission? Do they have registry connectivity, or is this new development?

2. **Corporate Action Data Source:** ⚠️ **OPTIONS IDENTIFIED - DECISION REQUIRED**

   **Recommended: ASX Real-Time Corporate Actions**
   - Official ASX service, ISO 20022 format, direct from issuers
   - Free for ASX ReferencePoint customers (check if NQ has subscription)
   - Covers all CA types: dividends, rights, mergers, buybacks
   - Contact: Information.Services@asx.com.au

   **Alternative: EDI (Exchange Data International)**
   - REST API available, 150+ exchanges including ASX
   - May already have subscription (check current EDI contract scope)
   - Contact: info@exchange-data.com

   **Fallback: Manual Entry MVP**
   - Operations team enters CAs from registry emails/ASX announcements
   - Detailed workflow designed - see corporate-actions-progress.md
   - Can launch immediately, transitions easily to automated feed

   **NOT viable:**
   - LSEG SDK - confirmed dead end for CA data
   - Morrison transaction feed - historical only, not prospective
   - Unstructured ASX announcements - requires NLP/parsing

3. **Registry Confirmation:** How do we confirm elections were processed?
   - Morrison polling?
   - Webhook callback?
   - Daily reconciliation file?

### Important (Needed for Design Finalisation)

4. **MDA Scope Verification:** How do we verify adviser MDA authority covers corporate actions? Is this in existing MDA agreements, or do we need new consent?

5. **Bulk Elections:** Should advisers be able to submit same election for multiple accounts in one action? (Proposed: Yes, for DRP)

6. **DRP State:** Do we track ongoing DRP participation status, or just individual elections?

7. **Rights Issue Cash:** How do we verify investor has cash available for rights exercise? Check cash balance via Morrison?

### Nice to Have (Post-MVP)

8. **Rights Trading:** For renounceable rights, do we facilitate selling rights?

9. **Takeover Documentation:** Do we need to present offer documents within the app, or link to external?

10. **Tax Implications:** Should we show indicative tax impact? (Requires Navexa integration)

---

## 10. MVP Scope Recommendation

### Phase 1: DRP Elections (4-6 weeks)

**In Scope:**
- DRP enrolment/change/cancellation
- Single election per account
- Both authority paths (MDA and investor direct)
- Email notifications
- Basic deadline management
- Full audit trail

**Out of Scope:**
- Rights issues
- Bulk adviser submission
- SMS notifications
- Tax impact display

**Why DRP First:**
- High volume, simple decision (participate or not)
- No cash outlay required
- Lower regulatory risk (clear MDA scope)
- Proves the pipeline (Xynon → Morrison → Registry)

### Phase 2: Rights Issues (4-6 weeks)

**Adds:**
- Rights issue participation
- Partial election (quantity selection)
- Cash balance check
- Adviser bulk submission
- Enhanced deadline management (shorter windows)

### Phase 3: Advanced Elections (6-8 weeks)

**Adds:**
- Off-market buybacks
- Takeover offers
- SPP participation
- Tax impact indication (Navexa)
- Rights trading (renounceable)

---

## 11. Technical Architecture

### 11.1 New Components

```
Portal API
├── Controllers/
│   └── CorporateActionsController.cs      // New
│   └── ElectionsController.cs             // New
├── Services/
│   └── CorporateActions/
│       ├── CorporateActionService.cs      // Business logic
│       ├── ElectionService.cs             // Election management
│       ├── ElectionAuthorityService.cs    // Authority validation
│       ├── DeadlineService.cs             // Deadline management
│       └── MorrisonElectionProxy.cs       // Morrison integration
├── Repositories/
│   └── CorporateActionRepository.cs       // New
│   └── ElectionRepository.cs              // New
├── Persistence/
│   └── DbCorporateAction.cs               // New entity
│   └── DbCorporateActionElection.cs       // New entity
└── DomainModels/
    └── CorporateActions/
        ├── ElectionAuthority.cs           // Authority model
        └── ElectionOptions.cs             // Option definitions

NQ.Trading.Models (NuGet)
├── CorporateActions/
│   ├── CorporateActionType.cs             // Extend existing enum
│   ├── ElectionStatus.cs                  // New enum
│   └── ElectionSubmissionDto.cs           // New DTO for Morrison
```

### 11.2 Database Changes

```sql
-- New tables
CREATE TABLE corporate_actions (
    corporate_action_id UUID PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    instrument_id UUID NOT NULL,
    instrument_symbol VARCHAR(20) NOT NULL,
    issuer_name VARCHAR(200) NOT NULL,
    announcement_date DATE NOT NULL,
    record_date DATE NOT NULL,
    election_deadline DATE NOT NULL,
    payment_date DATE,
    options JSONB NOT NULL,
    default_option_code VARCHAR(50),
    registry_reference VARCHAR(100),
    document_url TEXT,
    -- EntityBase fields
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    modified_by VARCHAR(100),
    modified_at TIMESTAMPTZ,
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TABLE corporate_action_elections (
    election_id UUID PRIMARY KEY,
    corporate_action_id UUID NOT NULL REFERENCES corporate_actions,
    account_id UUID NOT NULL,
    hin VARCHAR(20) NOT NULL,
    selected_option_code VARCHAR(50) NOT NULL,
    elected_quantity DECIMAL,
    holding_at_election DECIMAL,
    authority JSONB NOT NULL,
    status VARCHAR(50) NOT NULL,
    submitted_to_morrison TIMESTAMPTZ,
    morrison_reference VARCHAR(100),
    confirmed_by_registry TIMESTAMPTZ,
    registry_reference VARCHAR(100),
    rejection_reason TEXT,
    retry_count INT DEFAULT 0,
    -- EntityBase fields
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    modified_by VARCHAR(100),
    modified_at TIMESTAMPTZ,
    deleted_by VARCHAR(100),
    deleted_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- Indexes
CREATE INDEX ix_corporate_actions_deadline ON corporate_actions(election_deadline);
CREATE INDEX ix_corporate_actions_instrument ON corporate_actions(instrument_id);
CREATE INDEX ix_elections_account ON corporate_action_elections(account_id);
CREATE INDEX ix_elections_status ON corporate_action_elections(status);
CREATE INDEX ix_elections_corporate_action ON corporate_action_elections(corporate_action_id);
```

---

## 12. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Morrison API not ready | Medium | High | Start with mock, parallel development track |
| Registry rejection | Low | Medium | Clear error handling, retry logic |
| Deadline missed | Low | High | Multiple reminders, deadline prominent in UI |
| Wrong election submitted | Low | High | Confirmation screen, audit trail, cancel capability |
| MDA authority challenged | Low | Medium | Clear authority recording, RG179-compliant audit |
| Data source delays | Medium | Medium | Manual entry fallback, multiple source integration |

---

## 13. Success Criteria

### MVP (Phase 1)

- [ ] DRP election submitted through system
- [ ] Election confirmed by registry
- [ ] Full audit trail queryable
- [ ] Both authority paths functional
- [ ] Deadline notifications sent
- [ ] Zero data loss in election submission

### Full Release

- [ ] 90% of DRP elections processed digitally
- [ ] Rights issues supported
- [ ] Average time from announcement to election < 48 hours (vs weeks for paper)
- [ ] Zero compliance findings related to election provenance
- [ ] Adviser satisfaction > 4/5
- [ ] Investor satisfaction > 4/5

---

## 14. Next Steps

### Immediate Business Decisions Required

1. **Check ASX ReferencePoint subscription**
   - If we have it: Corporate action data is FREE
   - Contact: Information.Services@asx.com.au

2. **Check EDI subscription scope**
   - Current contract may include corporate actions
   - Who is the EDI relationship owner at NQ?

3. **Schedule Morrison call**
   - Focus: Election SUBMISSION API (not data source)
   - Can Morrison submit elections to registries?
   - What's their current manual process?

### Once Data Source Confirmed

4. **Technical spike** - Connect to ASX/EDI feed, validate data format
5. **Database migrations** - corporate_actions, corporate_action_elections tables
6. **Implement CA ingestion** - Service to consume feed and create records

### If Manual Entry MVP Required

4. **Build admin screens** - CA list, create/edit form, affected HINs view
5. **Implement notifications** - 7/3/1 day deadline reminders
6. **Document ops procedures** - Monitoring sources, data entry process

### Deferred Until Morrison Answers Available

7. **Morrison integration** - Election submission API
8. **Confirmation mechanism** - How registry confirmations flow back
9. **UI wireframes** - Election capture UX for investors/advisers

---

## Appendix A: Reference Files

| File | Location | Relevance |
|------|----------|-----------|
| Activity workflow | `Tmw.Api/Services/Operations/OperationWorkflowService.cs` | Pattern for election workflow |
| Account roles | `Tmw.Api/Persistence/V2/AccountRoleType.cs` | Authority verification |
| Operation names | `Tmw.Api/DomainModels/Activities/OperationNames.cs` | Add "CorporateActionElection" |
| Morrison proxy | `NQ.Trading.SharedServices/ApiProxy/MorrisonRestProxy.cs` | Integration pattern |
| Entity base | `NQ.CoreData/Features/EntityBase.cs` | Audit trail base class |
| Dividend processing | `nq.trading/specs/Dividends.puml` | Related workflow pattern |

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| HIN | Holder Identification Number - unique identifier for CHESS holdings |
| DRP | Dividend Reinvestment Plan |
| MDA | Managed Discretionary Account |
| RG179 | ASIC Regulatory Guide 179 - managed discretionary accounts |
| CHESS | Clearing House Electronic Subregister System |
| SPP | Share Purchase Plan |
