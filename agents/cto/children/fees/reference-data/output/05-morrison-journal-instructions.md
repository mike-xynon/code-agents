# Morrison Journal Instructions

Source: Google Sheets (shared spreadsheet) - Output reference data
Retrieved: 2026-02-03

## Purpose

These are the actual journal entries sent to Morrison Securities to execute cash movements for fee collection.

## Entry Types

| Type | Meaning | Direction |
|------|---------|-----------|
| C | Client Account | Debit (money out of client) |
| G | GL Account | Credit (money into Xynon accounts) |

## GL Codes

| Code | Description |
|------|-------------|
| WEA0099W2 | TPWEAL XYNON PORTAL FEES - BROKER (Revenue ex-GST) |
| WEA0199W2 | TPWEAL XYNON PORTAL FEES - BROKER GST |

---

## Annual Fee Instructions (2026-01-20)

### Client 1102155 - JR TAYLOR SMSF PTY LTD

| Type | Account/GL Code | Amount | Description |
|------|-----------------|--------|-------------|
| C | 1102155 | 300 | XYNON PORTAL ANNUAL FEE - 1102155 |
| G | WEA0099W2 | -272.73 | TPWEAL XYNON PORTAL FEES - BROKER / 1102155 |
| G | WEA0199W2 | -27.27 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102155 |

**Validation:** $300 inc GST → $272.73 ex-GST + $27.27 GST (10%) ✓

### Client 1102917 - MARZOLI FAMILY PTY LTD

| Type | Account/GL Code | Amount | Description |
|------|-----------------|--------|-------------|
| C | 1102917 | 300 | XYNON PORTAL ANNUAL FEE - 1102917 |
| G | WEA0099W2 | -272.73 | TPWEAL XYNON PORTAL FEES - BROKER / 1102917 |
| G | WEA0199W2 | -27.27 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102917 |

---

## Monthly Fee Instructions

### November (Date: 45981 = Excel serial date)

| Type | Account/GL Code | Amount | Description | Client |
|------|-----------------|--------|-------------|--------|
| C | 1102155 | 6.36 | XYNON PORTAL MONTHLY FEE - 1102155 | JR TAYLOR SMSF PTY LTD |
| G | WEA0099W2 | -5.78 | TPWEAL XYNON PORTAL FEES - BROKER / 1102155 | |
| G | WEA0199W2 | -0.58 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102155 | |

**Validation:** $6.36 inc GST → $5.78 ex-GST + $0.58 GST (9.1%) ≈ 10% ✓

### December (2025-12-20)

| Type | Account/GL Code | Amount | Description | Client |
|------|-----------------|--------|-------------|--------|
| C | 1102155 | 17.40 | XYNON PORTAL MONTHLY FEE - 1102155 | JR TAYLOR SMSF PTY LTD |
| G | WEA0099W2 | -15.82 | TPWEAL XYNON PORTAL FEES - BROKER / 1102155 | |
| G | WEA0199W2 | -1.58 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102155 | |
| C | 1102917 | 19.65 | XYNON PORTAL MONTHLY FEE - 1102917 | MARZOLI FAMILY PTY LTD |
| G | WEA0099W2 | -17.86 | TPWEAL XYNON PORTAL FEES - BROKER / 1102917 | |
| G | WEA0199W2 | -1.79 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102917 | |

**Validation:**
- $17.40 → $15.82 + $1.58 ✓
- $19.65 → $17.86 + $1.79 ✓

### January (2026-01-31)

| Type | Account/GL Code | Amount | Description | Client |
|------|-----------------|--------|-------------|--------|
| C | 1102155 | 17.38 | XYNON PORTAL MONTHLY FEE - 1102155 | JR TAYLOR SMSF PTY LTD |
| G | WEA0099W2 | -15.80 | TPWEAL XYNON PORTAL FEES - BROKER / 1102155 | |
| G | WEA0199W2 | -1.58 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102155 | |
| C | 1102917 | 19.51 | XYNON PORTAL MONTHLY FEE - 1102917 | MARZOLI FAMILY PTY LTD |
| G | WEA0099W2 | -17.74 | TPWEAL XYNON PORTAL FEES - BROKER / 1102917 | |
| G | WEA0199W2 | -1.77 | TPWEAL XYNON PORTAL FEES - BROKER GST / 1102917 | |

---

## Key Insights

### 1. Double-Entry Accounting
Each fee creates balanced entries:
- **Debit** client account (C) for total inc GST
- **Credit** revenue GL (G) for amount ex-GST
- **Credit** GST GL (G) for GST component

### 2. GST Calculation (10%)
```
Amount Ex-GST = Total / 1.1
GST = Total - Amount Ex-GST
```

Example: $300 / 1.1 = $272.73, GST = $27.27 ✓

### 3. Two Fee Types
- **ANNUAL FEE** - $300 one-time (initial/joining fee)
- **MONTHLY FEE** - Variable based on daily BPS accrual

### 4. Execution Timing
- Annual fees: Charged on 2026-01-20 (delayed from start date)
- Monthly fees: Charged at month end (20th or 31st)

### 5. Maps to Code Concepts
| Journal | Code Entity |
|---------|-------------|
| C (Client debit) | PortfolioChargeRecord.AmountExclTax + Tax |
| G (Revenue) | AmountExclTaxCoACode |
| G (GST) | TaxCoACode |
| ANNUAL FEE | ChargeFrequency.Joining |
| MONTHLY FEE | ChargeFrequency.Monthly |
