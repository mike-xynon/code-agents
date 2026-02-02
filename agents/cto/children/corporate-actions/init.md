# Corporate Actions Agent

## Mission
Implement the Corporate Actions Elections system - digitising DRP elections, rights issues, buybacks, takeovers, and meeting votes with authenticated instruction capture and broker integration.

## Repositories
Clone these into your private home directory (`~/repos/`):

| Name | Bitbucket Repo | Purpose |
|------|----------------|---------|
| portal | `xynon/portal` | UI (PWA) and API |
| nuget | `xynon/nq-nugetlibraries` | Shared NuGet packages |

```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/portal.git portal
git clone git@bitbucket.org:xynon/nq-nugetlibraries.git nuget
```

## Agent Files

Located in this folder (`agents/cto/children/corporate-actions/`):

| File | Purpose |
|------|---------|
| `init.md` | This file - mission and onboarding |
| `governing.md` | Rules from CTO |
| `report.md` | Status report (update regularly) |
| `resources.md` | All reference materials tracked |
| `design.md` | Class design (data model, interfaces, entities) |
| `system-design.md` | Full system design (authority model, workflows, APIs) |
| `progress.md` | Detailed progress log and session history |
| `lseg-evaluation.md` | LSEG SDK evaluation (concluded: need DSS) |
| `email-draft-wes.md` | Pending email to Wes about LSEG license |

## Reference Data

Location: `agents/cto/children/corporate-actions/reference-data/`

| File | Usefulness | Contents |
|------|------------|----------|
| `515597.xlsx` | ⭐⭐⭐⭐ CRITICAL | LSEG Data Content Guide - 701 fields |
| `dss_user_guide.txt` | ⭐⭐⭐ HIGH | DSS User Guide (extracted from PDF) |
| `dss_soap_guide.txt` | ⭐⭐⭐ HIGH | DSS SOAP API Guide (extracted) |
| `isitc_market_practice.txt` | ⭐⭐⭐ HIGH | ISO 15022 market practice (extracted) |
| `report_types_extract.json` | ⭐⭐ MEDIUM | Extracted DSS report types |
| `field_definitions_extract.json` | ⭐⭐ MEDIUM | Extracted field definitions |

See `resources.md` for complete tracking of all materials examined.

## Context

**What exists:**
- Design is complete and approved
- Class design: `CorporateAction` entity with JSON `EventData`, interface hierarchy
- Raw data storage: `CorporateActionSource` for provider audit trail
- Election entity: `CorporateActionElection` for user decisions

**Data Model:**
```
CorporateAction
├── EventTypeCode (string: "DRIP", "RHTS", "TEND", etc.)
├── Category (Mandatory, Voluntary, Meeting)
├── EventData (JSON string → deserializes to IEventTypeData)
└── CorporateActionSource[] (raw provider data)

Interface hierarchy:
IEventTypeData (base)
├── IDividendData
├── IRightsData : IElectionOptions
├── ITakeoverData : IElectionOptions
├── IMeetingData : IElectionOptions
└── IBuybackData : IElectionOptions
```

**Blockers:**
- LSEG license confirmation needed (email drafted to Wes)
- Morrison API for election submission (unknown)
- ASX ReferencePoint subscription check needed

## Ready to Implement

1. Create EF Core entities (`CorporateAction`, `CorporateActionElection`, `CorporateActionSource`)
2. Create database migration
3. Create repository interface `ICorporateActionRepository`
4. Create service layer with `EventTypeDataFactory`
5. Create ingestion service scaffold (provider-agnostic)
6. Create manual entry admin screens (MVP fallback)

## Workflow
1. Read the design docs by asking the user for their content
2. Check `corporate-actions-progress.md` for current state and blockers
3. Confirm with user which task to pick up before writing code
4. Implement incrementally, updating report.md with progress
5. Update `corporate-actions-progress.md` when completing tasks

## First Steps
1. Ask user to provide content of `corporate-actions-progress.md`
2. Ask user to provide content of `corporate-actions-class-design.md`
3. Review blockers - check if LSEG/Morrison questions resolved
4. Confirm next implementation task with user
5. Begin with EF Core entities if approved
