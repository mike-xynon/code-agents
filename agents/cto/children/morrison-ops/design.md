# Morrison Ops Design Document

## Purpose

Capture learnings, analysis, and proposals for Morrison business process improvements.

---

## Onboarding Workstream

### Current Understanding

*Awaiting input from SJ*

### Problem Analysis

TBD - need to understand:
- What forms are involved?
- Where do customers abandon?
- What does the AML/KYC provider report?
- User feedback/complaints?

### Provider Assessment

- Provider name: TBD
- Provider's view: Confident in capability
- Gap analysis: TBD

---

## CMM Visibility Workstream

### Current Understanding

**What is CMM?**
Client Money and Margin requirements under Australian regulation for margin brokers like Morrison Securities. Represents the capital buffer required based on client positions and exposures.

**The Problem:**
- Large clients (GBA, Evolution) can individually consume significant CMM capacity
- When approaching limits, Morrison may need to reject trades or force position exits
- Clients currently lack visibility into their impact on our limits
- Creates relationship friction and operational risk

### Data Questions

| Question | Answer | Source |
|----------|--------|--------|
| Where is CMM calculated? | TBD | |
| What system holds this data? | TBD | |
| Is it real-time or batch? | TBD | |
| Per-client breakdown available? | TBD | |
| What are the thresholds? | TBD | |

### Solution Options

#### Option 1: Front Office Dashboard
**Description:** Add CMM status widget to trading interface

**Pros:**
- Visible at point of decision
- Real-time feedback

**Cons:**
- Requires FO development
- May require FO vendor involvement
- Integration complexity

**Cost Estimate:** TBD

#### Option 2: Daily Email/Alert
**Description:** Automated daily summary when approaching thresholds

**Pros:**
- Simple to implement
- No FO changes needed

**Cons:**
- Not real-time
- Inbox noise

**Cost Estimate:** TBD

#### Option 3: API for Large Clients
**Description:** Expose CMM data via API for clients to integrate

**Pros:**
- Clients can build their own views
- Programmatic routing decisions

**Cons:**
- Only useful for sophisticated clients
- Maintenance burden
- Security considerations

**Cost Estimate:** TBD

#### Option 4: Relationship Manager Process
**Description:** Manual proactive communication from RM when approaching limits

**Pros:**
- Personal touch
- Flexible
- No tech required

**Cons:**
- Doesn't scale
- Depends on RM diligence
- Reactive rather than proactive

**Cost Estimate:** TBD

### Recommendation

TBD - pending discovery phase completion
