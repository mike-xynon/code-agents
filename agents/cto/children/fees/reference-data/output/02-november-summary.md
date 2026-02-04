# November Fee Summary

Source: Google Sheets (shared spreadsheet) - Output reference data
Retrieved: 2026-02-03

## Summary

| Member Number | Total Fees | Initial Fee |
|---------------|------------|-------------|
| 1102155 | $6.36 | $300 |
| 1102344 | $0 | $300 |

## Analysis

### Member 1102155 (JR TAYLOR SMSF PTY LTD)
- **Start Date:** 2025-11-20
- **Days in November:** 11 days (Nov 20-30)
- **Total Fees:** $6.36
- **Average Daily Fee:** $6.36 / 11 = $0.578/day
- **Initial Fee:** $300 (one-time joining fee?)

**Validation:** From raw data, daily fees were ~$0.56-0.57, so 11 days × $0.58 ≈ $6.36 ✓

### Member 1102344 (AMY BRIERLEY)
- **Start Date:** 2025-11-13
- **Total Fees:** $0 (balance was $0.00)
- **Initial Fee:** $300 (one-time joining fee?)

## Key Insights

1. **Initial Fee of $300** - This appears to be a one-time joining/setup fee
   - Not the $500/year premium fee (that would be different)
   - Could be related to `ChargeFrequency.Joining` in the code

2. **BPS fees only accrue on non-zero balances** - AMY BRIERLEY had $0 balance, so $0 fees

3. **Pro-rata calculation confirmed** - 11 days in Nov at ~$0.58/day = $6.36

## Questions for Validation

- Is the $300 initial fee the same as the adviser fee setup cost?
- Does this $300 map to a `ChargeFrequency.Joining` charge in the system?
- Why is initial fee $300 when premium is $500/year? Different fee type?
