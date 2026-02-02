# Corporate Actions Agent - Status Report

**Agent:** corporate-actions
**Parent:** cto
**Status:** Design Complete, Ready for Implementation
**Last Updated:** 2026-02-02

## Mission
Implement Corporate Actions Elections system - digitising DRP elections, rights issues, buybacks, takeovers, and meeting votes.

## Current State

### Completed
- [x] LSEG Data Content Guide analyzed (351 CA fields, 350 ISO 15022 fields)
- [x] Data model designed and approved
- [x] Interface hierarchy defined (IEventTypeData → 5 category interfaces → IElectionOptions mixin)
- [x] Raw data storage pattern designed (CorporateActionSource)
- [x] Election entity designed (CorporateActionElection)
- [x] LSEG DSS API structure documented
- [x] Email drafted to Wes re: LSEG license

### Blocked
- [ ] LSEG license confirmation - waiting on Wes
- [ ] Morrison election submission API - unknown capability
- [ ] ASX ReferencePoint subscription check - needs business confirmation

### Ready to Implement
- [ ] EF Core entities
- [ ] Database migration
- [ ] Repository interface
- [ ] Service layer with EventTypeDataFactory
- [ ] Ingestion service scaffold
- [ ] Manual entry admin screens (MVP)

## Agent Files

| File | Status |
|------|--------|
| `design.md` | Complete - class design approved |
| `system-design.md` | Complete - full system design |
| `progress.md` | Active - detailed session logs |
| `resources.md` | Active - all reference materials tracked |
| `lseg-evaluation.md` | Complete - SDK is dead end, need DSS |
| `email-draft-wes.md` | Ready to send |

## Reference Data
Location: `reference-data/` (relative to this agent folder)
- LSEG Data Content Guide (515597.xlsx) - 701 fields extracted
- DSS User Guide & SOAP Guide (text extracted)
- ISITC Market Practice v8.0 (text extracted)

See `resources.md` for complete tracking.

## Key Design Decisions

1. **Single table with JSON** - CorporateAction entity stores type-specific data in `EventData` JSON column
2. **Interface hierarchy** - 5 category interfaces, IElectionOptions mixin for voluntary actions
3. **Options as value objects** - List<ElectionOption> in JSON, not separate table
4. **Raw data preservation** - CorporateActionSource stores original provider response for healing

## Next Session
1. Check if LSEG license question resolved
2. If unblocked, begin EF Core entity implementation
3. If still blocked, implement manual entry MVP screens

## Progress Log

### 2026-02-02
- Completed class design with user approval
- Added raw data storage pattern (CorporateActionSource)
- Reviewed LSEG DSS API access requirements
- Drafted email to Wes about LSEG license
- Created agent folder structure under CTO children
