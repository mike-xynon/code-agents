# Corporate Actions - Class Design

> **Status:** Design Approved
> **Updated:** 2026-02-02

---

## Design Principles

1. **Database is flexible** - Store event type as string, type-specific data as JSON string
2. **Code uses interfaces** - 5 main category interfaces, consumers don't need 50 switch statements
3. **Options belong to event data** - Not all CAs have options, so `IElectionOptions` is a mixin
4. **No over-engineering** - Options are value objects (not entities), no subtype interfaces needed

---

## Database Entity

```csharp
public class CorporateAction : EntityBase
{
    public Guid Id { get; set; }

    // Type as string - matches ISO CAEV codes
    public string EventTypeCode { get; set; }      // "DVCA", "DRIP", "RHTS", "TEND", etc.
    public string Category { get; set; }           // "Mandatory", "Voluntary", "Meeting"

    // Instrument
    public Guid InstrumentId { get; set; }
    public string InstrumentCode { get; set; }
    public string IssuerName { get; set; }

    // Truly common dates only
    public DateOnly AnnouncementDate { get; set; }
    public DateOnly? RecordDate { get; set; }

    // Source
    public string SourceProvider { get; set; }
    public string? SourceReference { get; set; }
    public CorporateActionStatus Status { get; set; }

    // Type-specific data as raw JSON string - deserializes to IEventTypeData
    public string? EventData { get; set; }
}

public enum CorporateActionStatus
{
    Announced,      // Just received
    Open,           // Accepting elections
    Closed,         // Deadline passed
    Processed       // Completed
}
```

### Database Table

| Column | Type | Notes |
|--------|------|-------|
| Id | uuid | PK |
| EventTypeCode | text | "DRIP", "RHTS", "TEND", etc. |
| Category | text | "Mandatory", "Voluntary", "Meeting" |
| InstrumentId | uuid | FK to Instrument |
| InstrumentCode | text | "BHP.AX" |
| IssuerName | text | |
| AnnouncementDate | date | |
| RecordDate | date | nullable |
| SourceProvider | text | "LSEG", "EDI", "Manual" |
| SourceReference | text | nullable |
| Status | text | |
| EventData | text | JSON string |

---

## Interface Hierarchy

```
IEventTypeData (base)
├── IDividendData ──────────────────────────── Some concrete types also implement IElectionOptions
├── IRightsData : IElectionOptions ─────────── Always has options
├── ITakeoverData : IElectionOptions ───────── Always has options
├── IMeetingData : IElectionOptions ────────── Always has options (resolutions)
└── IBuybackData : IElectionOptions ────────── Always has options

IElectionOptions (mixin)
├── Options: List<ElectionOption>
├── DefaultOptionCode: string?
└── ElectionDeadline: DateOnly
```

---

## Interface Definitions

```csharp
// ═══════════════════════════════════════════════════════════════════════════
// BASE INTERFACE
// ═══════════════════════════════════════════════════════════════════════════

public interface IEventTypeData
{
    string EventTypeCode { get; }
}


// ═══════════════════════════════════════════════════════════════════════════
// ELECTION OPTIONS - Mixin for voluntary actions
// ═══════════════════════════════════════════════════════════════════════════

public interface IElectionOptions
{
    List<ElectionOption> Options { get; }
    string? DefaultOptionCode { get; }
    DateOnly ElectionDeadline { get; }
}

public class ElectionOption
{
    public string Code { get; set; }              // "FULL_DRP", "EXERCISE", "ACCEPT"
    public string Description { get; set; }
    public bool IsDefault { get; set; }
    public bool RequiresQuantity { get; set; }
    public decimal? Price { get; set; }           // For rights exercise
}


// ═══════════════════════════════════════════════════════════════════════════
// 5 MAIN CATEGORY INTERFACES
// ═══════════════════════════════════════════════════════════════════════════

// Dividends - some voluntary (DRIP), some mandatory (DVCA)
public interface IDividendData : IEventTypeData
{
    decimal GrossAmount { get; }
    string Currency { get; }
    DateOnly PaymentDate { get; }
}

// Rights - always voluntary
public interface IRightsData : IEventTypeData, IElectionOptions
{
    decimal SubscriptionPrice { get; }
    string Ratio { get; }
    bool IsRenounceable { get; }
}

// Takeovers - always voluntary
public interface ITakeoverData : IEventTypeData, IElectionOptions
{
    string BidderName { get; }
    decimal? CashPerShare { get; }
    string? ScripRatio { get; }
}

// Meetings - always have resolutions to vote on
public interface IMeetingData : IEventTypeData, IElectionOptions
{
    DateTimeOffset MeetingDateTime { get; }
    List<Resolution> Resolutions { get; }
}

public class Resolution
{
    public int Number { get; set; }
    public string Description { get; set; }
    public string? Recommendation { get; set; }   // "For", "Against", "Open"
}

// Buybacks - always voluntary
public interface IBuybackData : IEventTypeData, IElectionOptions
{
    decimal? PriceMin { get; }
    decimal? PriceMax { get; }
}
```

---

## Concrete Implementations

```csharp
// ═══════════════════════════════════════════════════════════════════════════
// DIVIDEND TYPES
// ═══════════════════════════════════════════════════════════════════════════

// DVCA - Mandatory cash dividend, no election
public class DividendCashData : IDividendData
{
    public string EventTypeCode => "DVCA";

    public decimal GrossAmount { get; set; }
    public string Currency { get; set; }
    public DateOnly PaymentDate { get; set; }

    // Additional fields
    public decimal? NetAmount { get; set; }
    public decimal? FrankingPercent { get; set; }
    public decimal? WithholdingTax { get; set; }
}

// DRIP - Voluntary dividend reinvestment
public class DividendReinvestmentData : IDividendData, IElectionOptions
{
    public string EventTypeCode => "DRIP";

    // IDividendData
    public decimal GrossAmount { get; set; }
    public string Currency { get; set; }
    public DateOnly PaymentDate { get; set; }

    // Additional fields
    public decimal? FrankingPercent { get; set; }
    public decimal? DRPPrice { get; set; }
    public decimal? DRPDiscount { get; set; }

    // IElectionOptions
    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}

// DVOP - Dividend with scrip option
public class DividendOptionData : IDividendData, IElectionOptions
{
    public string EventTypeCode => "DVOP";

    public decimal GrossAmount { get; set; }
    public string Currency { get; set; }
    public DateOnly PaymentDate { get; set; }
    public decimal? ScripPrice { get; set; }

    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}


// ═══════════════════════════════════════════════════════════════════════════
// RIGHTS TYPES
// ═══════════════════════════════════════════════════════════════════════════

// RHTS - Rights issue
public class RightsIssueData : IRightsData
{
    public string EventTypeCode => "RHTS";

    // IRightsData
    public decimal SubscriptionPrice { get; set; }
    public string Ratio { get; set; }
    public bool IsRenounceable { get; set; }

    // Additional fields
    public string? RightsIsin { get; set; }
    public DateOnly? TradingStart { get; set; }
    public DateOnly? TradingEnd { get; set; }
    public bool HasShortfallFacility { get; set; }
    public decimal? Discount { get; set; }

    // IElectionOptions
    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}

// PRII - Share Purchase Plan
public class SharePurchasePlanData : IRightsData
{
    public string EventTypeCode => "PRII";

    public decimal SubscriptionPrice { get; set; }
    public string Ratio { get; set; }
    public bool IsRenounceable => false;  // SPPs not renounceable

    public decimal MinApplication { get; set; }
    public decimal MaxApplication { get; set; }

    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}


// ═══════════════════════════════════════════════════════════════════════════
// TAKEOVER TYPES
// ═══════════════════════════════════════════════════════════════════════════

// TEND - Tender/Takeover offer
public class TenderOfferData : ITakeoverData
{
    public string EventTypeCode => "TEND";

    public string BidderName { get; set; }
    public decimal? CashPerShare { get; set; }
    public string? ScripRatio { get; set; }

    public decimal? MinAcceptance { get; set; }
    public string? Conditions { get; set; }
    public bool IsHostile { get; set; }

    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}

// MRGR - Merger (often requires meeting vote)
public class MergerData : ITakeoverData
{
    public string EventTypeCode => "MRGR";

    public string BidderName { get; set; }
    public decimal? CashPerShare { get; set; }
    public string? ScripRatio { get; set; }

    public bool RequiresVote { get; set; }
    public Guid? LinkedMeetingId { get; set; }

    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}


// ═══════════════════════════════════════════════════════════════════════════
// MEETING TYPES
// ═══════════════════════════════════════════════════════════════════════════

// MEET/GMET/CMET - Meetings
public class MeetingData : IMeetingData
{
    public string EventTypeCode { get; set; }  // "MEET", "GMET", "CMET"

    public DateTimeOffset MeetingDateTime { get; set; }
    public List<Resolution> Resolutions { get; set; }

    public string? Location { get; set; }
    public string? VirtualLink { get; set; }

    public List<ElectionOption> Options { get; set; }  // Typically: Attend, Proxy, Abstain
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }     // Proxy deadline
}


// ═══════════════════════════════════════════════════════════════════════════
// BUYBACK TYPES
// ═══════════════════════════════════════════════════════════════════════════

// BIDS - Off-market buyback
public class BuybackData : IBuybackData
{
    public string EventTypeCode => "BIDS";

    public decimal? PriceMin { get; set; }
    public decimal? PriceMax { get; set; }

    public long? SharesSought { get; set; }
    public bool IsScaleBackPossible { get; set; }

    public List<ElectionOption> Options { get; set; }
    public string? DefaultOptionCode { get; set; }
    public DateOnly ElectionDeadline { get; set; }
}


// ═══════════════════════════════════════════════════════════════════════════
// MANDATORY TYPES (no elections)
// ═══════════════════════════════════════════════════════════════════════════

// BONU - Bonus issue
public class BonusIssueData : IEventTypeData
{
    public string EventTypeCode => "BONU";

    public string Ratio { get; set; }
    public DateOnly EffectiveDate { get; set; }
}

// SPLF - Stock split
public class StockSplitData : IEventTypeData
{
    public string EventTypeCode => "SPLF";

    public string Ratio { get; set; }
    public DateOnly EffectiveDate { get; set; }
}
```

---

## Factory for Deserialization

```csharp
public static class EventTypeDataFactory
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public static IEventTypeData? Deserialize(string eventTypeCode, string? json)
    {
        if (string.IsNullOrEmpty(json)) return null;

        return eventTypeCode switch
        {
            // Dividends
            "DVCA" => JsonSerializer.Deserialize<DividendCashData>(json, JsonOptions),
            "DRIP" => JsonSerializer.Deserialize<DividendReinvestmentData>(json, JsonOptions),
            "DVOP" => JsonSerializer.Deserialize<DividendOptionData>(json, JsonOptions),

            // Rights
            "RHTS" => JsonSerializer.Deserialize<RightsIssueData>(json, JsonOptions),
            "PRII" => JsonSerializer.Deserialize<SharePurchasePlanData>(json, JsonOptions),

            // Takeovers
            "TEND" => JsonSerializer.Deserialize<TenderOfferData>(json, JsonOptions),
            "MRGR" => JsonSerializer.Deserialize<MergerData>(json, JsonOptions),
            "BIDS" => JsonSerializer.Deserialize<BuybackData>(json, JsonOptions),

            // Meetings
            "MEET" or "GMET" or "CMET" => JsonSerializer.Deserialize<MeetingData>(json, JsonOptions),

            // Mandatory
            "BONU" => JsonSerializer.Deserialize<BonusIssueData>(json, JsonOptions),
            "SPLF" or "SPLR" => JsonSerializer.Deserialize<StockSplitData>(json, JsonOptions),

            // Unknown - return generic
            _ => JsonSerializer.Deserialize<GenericEventData>(json, JsonOptions)
        };
    }
}

// Fallback for unknown types
public class GenericEventData : IEventTypeData
{
    public string EventTypeCode { get; set; }
    public Dictionary<string, object>? AdditionalData { get; set; }
}
```

---

## Usage Examples

```csharp
// Load from database
var ca = await dbContext.CorporateActions.FindAsync(id);
var eventData = EventTypeDataFactory.Deserialize(ca.EventTypeCode, ca.EventData);

// Check if it has election options
if (eventData is IElectionOptions elections)
{
    Console.WriteLine($"Deadline: {elections.ElectionDeadline}");
    Console.WriteLine($"Options: {elections.Options.Count}");
    Console.WriteLine($"Default: {elections.DefaultOptionCode}");
}

// Work with specific category
switch (eventData)
{
    case IDividendData dividend:
        Console.WriteLine($"Payment: {dividend.PaymentDate}, Amount: {dividend.GrossAmount}");
        break;

    case IRightsData rights:
        Console.WriteLine($"Subscribe at {rights.SubscriptionPrice}, Ratio: {rights.Ratio}");
        if (rights.IsRenounceable)
            Console.WriteLine("Rights are tradeable");
        break;

    case IMeetingData meeting:
        Console.WriteLine($"Meeting: {meeting.MeetingDateTime}");
        foreach (var res in meeting.Resolutions)
            Console.WriteLine($"  {res.Number}: {res.Description}");
        break;
}
```

---

## Election Entity

```csharp
public class CorporateActionElection : EntityBase
{
    public Guid Id { get; set; }
    public Guid CorporateActionId { get; set; }
    public Guid AccountId { get; set; }
    public string Hin { get; set; }

    // Election choice
    public string SelectedOptionCode { get; set; }
    public decimal? ElectedQuantity { get; set; }
    public decimal HoldingAtElection { get; set; }

    // For meetings - votes per resolution (JSON)
    public string? ResolutionVotes { get; set; }

    // Authority
    public string AuthorityType { get; set; }         // "MDA", "InvestorDirect"
    public Guid AuthorisingUserId { get; set; }
    public DateTimeOffset AuthorisedAt { get; set; }
    public string? AuthorityReference { get; set; }

    // Status
    public string Status { get; set; }                // Draft, Submitted, Confirmed, etc.

    // Submission tracking
    public DateTimeOffset? SubmittedAt { get; set; }
    public string? BrokerReference { get; set; }
    public DateTimeOffset? ConfirmedAt { get; set; }
    public string? RegistryReference { get; set; }
    public string? RejectionReason { get; set; }
}
```

---

## Raw Data Storage (Provider Audit Trail)

To enable healing of data import issues, we store the original provider data alongside our parsed model.

```csharp
public class CorporateActionSource : EntityBase
{
    public Guid Id { get; set; }
    public Guid CorporateActionId { get; set; }

    // Provider identification
    public string Provider { get; set; }              // "LSEG", "EDI", "ASX", "Manual"
    public string ProviderEventId { get; set; }       // Provider's unique ID for this event

    // Raw data - exactly as received
    public string RawData { get; set; }               // Full JSON/XML response
    public string RawDataFormat { get; set; }         // "JSON", "XML", "CSV"

    // Fetch metadata
    public DateTimeOffset FetchedAt { get; set; }
    public string? RequestParameters { get; set; }    // What we asked for (instrument, date range)
    public string? ApiEndpoint { get; set; }          // Which endpoint was called
    public string? ApiVersion { get; set; }

    // Processing status
    public bool IsProcessed { get; set; }
    public DateTimeOffset? ProcessedAt { get; set; }
    public string? ProcessingErrors { get; set; }     // Any errors during parsing

    // Navigation
    public CorporateAction CorporateAction { get; set; }
}
```

### Database Table: corporate_action_sources

| Column | Type | Notes |
|--------|------|-------|
| Id | uuid | PK |
| CorporateActionId | uuid | FK to CorporateAction |
| Provider | text | "LSEG", "EDI", "ASX", "Manual" |
| ProviderEventId | text | Provider's event reference |
| RawData | text | Original response (JSON/XML) |
| RawDataFormat | text | Format of RawData |
| FetchedAt | timestamptz | When we retrieved it |
| RequestParameters | text | nullable, JSON of request params |
| ApiEndpoint | text | nullable |
| ApiVersion | text | nullable |
| IsProcessed | boolean | |
| ProcessedAt | timestamptz | nullable |
| ProcessingErrors | text | nullable |

### Relationship

```
CorporateAction (1) ←───── (many) CorporateActionSource
```

One corporate action may have multiple source records if:
- Updated by provider (new version)
- Re-fetched for healing
- Multiple providers for same event

### Usage for Healing

```csharp
public class CorporateActionHealingService
{
    // Re-parse from raw data after fixing parsing logic
    public async Task ReprocessFromRaw(Guid corporateActionId)
    {
        var sources = await _db.CorporateActionSources
            .Where(s => s.CorporateActionId == corporateActionId)
            .OrderByDescending(s => s.FetchedAt)
            .ToListAsync();

        var latest = sources.First();
        var parsed = _parser.Parse(latest.Provider, latest.RawData);

        await UpdateCorporateAction(corporateActionId, parsed);
    }

    // Bulk re-process after parser fix
    public async Task ReprocessAllFromProvider(string provider, DateTimeOffset since)
    {
        var sources = await _db.CorporateActionSources
            .Where(s => s.Provider == provider && s.FetchedAt >= since)
            .ToListAsync();

        foreach (var source in sources)
        {
            try
            {
                var parsed = _parser.Parse(source.Provider, source.RawData);
                await UpdateCorporateAction(source.CorporateActionId, parsed);
                source.ProcessingErrors = null;
            }
            catch (Exception ex)
            {
                source.ProcessingErrors = ex.Message;
            }
            source.ProcessedAt = DateTimeOffset.UtcNow;
        }

        await _db.SaveChangesAsync();
    }
}
```

### Ingestion Flow

```
┌─────────────────────┐
│  LSEG/EDI/ASX API   │
└──────────┬──────────┘
           │ Raw response
           ▼
┌─────────────────────┐
│ Store in            │
│ CorporateActionSource│
│ (RawData = original)│
└──────────┬──────────┘
           │ Parse
           ▼
┌─────────────────────┐
│ Create/Update       │
│ CorporateAction     │
│ (EventData = parsed)│
└─────────────────────┘
```

---

## Data Source Mapping

The LSEG Data Content Guide (v19.1) provides these fields that map to our model:

| Our Field | LSEG Corporate Actions | LSEG ISO 15022 |
|-----------|------------------------|----------------|
| EventTypeCode | Corporate Actions Type | Event Type Code |
| Category | (derive from type) | Mandatory Voluntary Indicator Code |
| AnnouncementDate | Various *Announcement Date | Announcement Date |
| RecordDate | Dividend Record Date | Record Date |
| ElectionDeadline | Dividend Reinvestment Deadline, Subscription Period End Date | Market Deadline Date |
| Options | (derive from type) | Option Number, Option Type Code |
| DefaultOptionCode | (not explicit) | Default Processing Flag |

See `corporate-actions-progress.md` for full field mapping.
