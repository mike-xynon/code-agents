# Email Draft: LSEG License Query

**To:** Wes
**Subject:** LSEG License - Corporate Actions Data Access Query

---

Hi Wes,

I'm working on the design for the Corporate Actions Elections system (digitising DRP elections, rights issues, buybacks, etc.) and need to clarify what our LSEG license covers.

## Background

We currently use LSEG for pricing and symbology via the `LSEG.Data.Content` SDK, which connects to `api.refinitiv.com`. This works well for what we use it for.

However, for corporate actions data (dividends, rights issues, takeovers, meetings), I've discovered that LSEG has a **separate product called DataScope Select (DSS)** which uses a different endpoint (`selectapi.datascope.lseg.com`).

## What We Need

To build the Corporate Actions Elections feature, we need access to **prospective corporate action data**, including:

- Dividend announcements with DRP election options and deadlines
- Rights issues with subscription prices, ratios, and exercise deadlines
- Takeover/buyback offers with acceptance deadlines
- AGM/EGM meeting notices with resolution details and proxy deadlines

This data needs to arrive **before the election deadline** so investors can make decisions.

## Questions

1. **Does our current LSEG contract include DataScope Select?**
   - If yes, do we have credentials for `selectapi.datascope.lseg.com`?
   - If no, would we need to upgrade or add a subscription?

2. **What corporate actions coverage do we currently have (if any)?**
   - The SDK we use doesn't appear to have corporate actions endpoints
   - But there may be other access we're not aware of

3. **Who is our LSEG account contact?**
   - If we need to discuss adding DataScope Select, I can prepare the technical requirements

## Alternative

If LSEG DSS isn't available or is cost-prohibitive, we have other options:
- **ASX Real-Time Corporate Actions** (free for ReferencePoint customers - do we have this?)
- **EDI** (we may already have a subscription that includes corporate actions)
- **Manual entry** (workable for MVP but not scalable)

Let me know if you need any more detail on what we're trying to achieve.

Thanks,
[Your name]

---

## Attachment: Technical Context

### What LSEG DataScope Select Provides

| Data Type | Coverage |
|-----------|----------|
| Dividends | Cash, DRP options, scrip dividends |
| Capital Changes | Rights issues, splits, bonus issues |
| M&A | Takeovers, mergers, schemes |
| Meetings | AGM/EGM with resolutions |
| Buybacks | Off-market buybacks |

- 95,000+ companies
- 145+ countries
- 200+ exchanges (including ASX)
- Updated daily with prospective events

### API Access

```
Endpoint: https://selectapi.datascope.lseg.com/RestApi/v1/
Authentication: OAuth token
Format: REST/JSON

Key operations:
- CorporateActionsStandardExtractionRequest
- CorporateActionsISO15022ExtractionRequest
```

### What We'd Build

A scheduled job that:
1. Fetches upcoming corporate actions for instruments we hold
2. Stores raw response for audit/healing
3. Parses into our data model
4. Creates election opportunities for affected accounts
5. Notifies investors/advisers of deadlines
