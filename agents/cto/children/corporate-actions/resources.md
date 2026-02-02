# Corporate Actions - Resource Tracking

> **Purpose:** Track all reference materials examined during research and design
> **Last Updated:** 2026-02-02

---

## Agent Files

Location: `agents/cto/children/corporate-actions/`

| File | Purpose | Status |
|------|---------|--------|
| `init.md` | Mission and onboarding | Complete |
| `governing.md` | Rules from CTO | Complete |
| `report.md` | Status report | Active |
| `resources.md` | This file - resource tracking | Active |
| `design.md` | Data model, interfaces, entities | Complete |
| `system-design.md` | Full system design (authority, workflows, APIs) | Complete |
| `progress.md` | Detailed progress log and session history | Active |
| `lseg-evaluation.md` | LSEG SDK evaluation | Complete |
| `email-draft-wes.md` | Email to Wes re: LSEG license | Ready to send |

---

## Reference Data Files

Location: `agents/cto/children/corporate-actions/reference-data/`

### Source Documents (PDFs)

| File | Source | Usefulness | Key Findings |
|------|--------|------------|--------------|
| `dss_14_5_user_guide.pdf` | LSEG Developer Portal | ⭐⭐⭐ HIGH | DSS coverage (95K companies, 145 countries), 8 event categories, extraction process |
| `dss_soap_api_programmer_guide_wsdl.pdf` | LSEG Developer Portal | ⭐⭐⭐ HIGH | GetCoraxEvents operation, event type codes, date constraints per category |
| `Corporate_Actions_Market_Practice_v8.0_Dec2022.pdf` | ISITC | ⭐⭐⭐ HIGH | ISO 15022 message types (MT564-568), rights as TWO linked events |
| `515597.xlsx` | LSEG MyAccount (Data Content Guide v19.1) | ⭐⭐⭐⭐ CRITICAL | 351 CA fields, 350 ISO 15022 fields, complete field definitions |

### Extracted Text Files

| File | Source | Purpose |
|------|--------|---------|
| `dss_user_guide.txt` | dss_14_5_user_guide.pdf | Searchable text for grep |
| `dss_soap_guide.txt` | dss_soap_api_programmer_guide_wsdl.pdf | Searchable text for grep |
| `isitc_market_practice.txt` | Corporate_Actions_Market_Practice_v8.0_Dec2022.pdf | Searchable text for grep |

### Extracted Data Files

| File | Source | Contents |
|------|--------|----------|
| `report_types_extract.json` | 515597.xlsx | 25 DSS report types including Corporate Actions variants |
| `field_definitions_extract.json` | 515597.xlsx | First 200 rows of field definitions |
| `code_descriptions_extract.json` | 515597.xlsx | First 300 rows of code descriptions |

---

## Web Resources Consulted

### LSEG / Refinitiv

| URL | Usefulness | Key Findings |
|-----|------------|--------------|
| https://developers.lseg.com/en/api-catalog/datascope-select/datascope-select-rest-api | ⭐⭐⭐ HIGH | REST API structure, authentication endpoint, extraction request format |
| https://developers.lseg.com/.../tutorials | ⭐⭐ MEDIUM | Tutorial 5 covers corporate actions extraction |
| https://www.lseg.com/en/data-analytics/financial-data/corporate-actions-data | ⭐ LOW | Marketing overview only |

### EDI (Exchange Data International)

| URL | Usefulness | Key Findings |
|-----|------------|--------------|
| https://www.exchange-data.com/corporate-actions/ | ⭐⭐ MEDIUM | 45-60 event types, ISO 15022 format, 150+ exchanges |
| https://developer.exchange-data.com/ | ⭐ LOW | Requires login - not accessed |
| https://www.exchange-data.com/corporate-actions-guide-everything-you-need-to-know/ | ⭐⭐ MEDIUM | Event type explanations |

### ASX

| URL | Usefulness | Key Findings |
|-----|------------|--------------|
| https://www.asx.com.au/.../real-time-corporate-actions | ⭐⭐⭐ HIGH | ISO 20022 format, free for ReferencePoint customers |

### ISO Standards

| URL | Usefulness | Notes |
|-----|------------|-------|
| iso20022.org | ⚠️ AVOIDED | Causes hangs - did not fetch |
| iotafinance.com | ⭐⭐ MEDIUM | CAEV code definitions |

---

## Codebase Files Examined

Repository: `nq-nugetlibraries`

| File | Path | Relevance |
|------|------|-----------|
| `LsegDirectApiTests.cs` | NQ.Lseg.Tests | Tested direct API - 404 errors |
| `LsegDataPlatformApiTests.cs` | NQ.Lseg.Tests | Explored IPA namespace |
| `LsegPackageExplorationTests.cs` | NQ.Lseg.Tests | NO FundamentalAndReference namespace |
| `TransactionExtensions.cs` | NQ.Morrison.API | **KEY:** 100+ CA transaction codes mapped |
| `EquityTransactionTypes.cs` | NQ.Morrison.API | Full transaction code definitions |

**Key Finding:** Morrison has HISTORIC CA data (what happened), not PROSPECTIVE (upcoming elections).

---

## Resources NOT Helpful

| Resource | Why Not Helpful |
|----------|-----------------|
| LSEG.Data.Content SDK | No corporate actions namespace |
| api.refinitiv.com endpoints | 404 errors on fundamental endpoints |
| iso20022.org | Causes browser/fetch hangs |
| Generic LSEG marketing pages | No technical detail |

---

## Resources Still Needed

| Resource | How to Get | Why Needed |
|----------|------------|------------|
| LSEG DSS credentials | Check with Wes | Test API access |
| EDI API documentation | Register at developer portal | Alternative data source |
| ASX ReferencePoint Manual | Download from ASX | ISO 20022 message spec |
| Morrison CA API spec | Schedule call | Election submission |

---

## Session Log Summary

| Session | Date | Focus | Outcome |
|---------|------|-------|---------|
| 5 | 2026-01-31 | PDF extraction | Extracted text from 3 PDFs, identified 3 CA categories |
| 6 | 2026-02-01 | LSEG Excel analysis | Extracted 701 fields from Data Content Guide |
| 7 | 2026-02-02 | Class design | Finalized data model, raw storage, LSEG API review, agent setup |

---

## Tools Used for Extraction

| Tool | Purpose |
|------|---------|
| pdftotext | Convert PDF to searchable text |
| Python openpyxl | Extract Excel data in read_only mode |
| Grep | Search extracted text files |
