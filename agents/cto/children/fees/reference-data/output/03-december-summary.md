# December Fee Summary

Source: Google Sheets (shared spreadsheet) - Output reference data
Retrieved: 2026-02-03

## Summary

| Member Number | Total Fees | Initial Fee |
|---------------|------------|-------------|
| 1102155 | $17.40 | |
| 1102917 | $19.65 | $300 |
| 1102344 | $0 | |

## Analysis

### Member 1102155 (JR TAYLOR SMSF PTY LTD)
- **Days in December:** 31 days
- **Total Fees:** $17.40
- **Average Daily Fee:** $17.40 / 31 = $0.561/day
- **No Initial Fee:** Already paid in November

**Validation:** From raw data, daily fees were ~$0.56, so 31 days × $0.56 ≈ $17.36 ✓ (close match)

### Member 1102917 (NEW CLIENT)
- **Total Fees:** $19.65
- **Initial Fee:** $300 (new client in December)
- **Implied start:** Must have started in December

**Back-calculation:**
- If $19.65 over ~31 days: ~$0.63/day
- Implies balance around: $0.63 × 365 / 0.0011 ≈ $209,000

### Member 1102344 (AMY BRIERLEY)
- **Total Fees:** $0 (still $0 balance)
- **No Initial Fee:** Already charged in November

## Running Totals

| Member | Nov Fees | Dec Fees | Nov+Dec Total | Initial Fee |
|--------|----------|----------|---------------|-------------|
| 1102155 | $6.36 | $17.40 | $23.76 | $300 |
| 1102917 | - | $19.65 | $19.65 | $300 |
| 1102344 | $0 | $0 | $0 | $300 |

## Key Insights

1. **Initial fee only charged once** - 1102155 paid $300 in Nov, not again in Dec
2. **New client 1102917** appeared in December with $300 initial fee
3. **Pro-rata confirmed** - Daily fees scale with balance as expected
