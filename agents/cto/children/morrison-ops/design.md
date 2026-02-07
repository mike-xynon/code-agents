# Morrison-Ops Design Document

## Purpose

This document captures analysis, proposals, and design decisions for Morrison Securities business process improvements.

---

## Workstream 1: Customer Onboarding

### Current Understanding

*(To be filled after stakeholder input from SJ)*

### Problem Analysis

| Hypothesis | Evidence | Status |
|------------|----------|--------|
| Forms are confusing | — | Needs investigation |
| Process flow is unclear | — | Needs investigation |
| UX/interface issues | — | Needs investigation |
| Communication gaps | — | Needs investigation |

### Stakeholder Input

*(Record input from SJ and others here)*

### Proposed Solutions

*(To be developed after understanding the problem)*

---

## Workstream 2: CMM Visibility

### Current Understanding

**What is CMM?**
- Client Money and Margin — regulatory margin requirement for Australian margin brokers
- Morrison Securities must maintain CMM compliance
- Large clients can individually consume significant CMM capacity

**The Problem:**
- Large clients (GBA, Evolution) don't know when they're approaching our limit
- Leads to rejected/delayed trades when capacity is reached
- No proactive visibility for clients to self-manage

### Open Questions

| Question | Answer | Source |
|----------|--------|--------|
| Where is CMM data today? | — | — |
| What systems hold it? | — | — |
| What thresholds trigger concern? | — | — |
| What lead time do clients need? | — | — |
| What's the current manual process? | — | — |

### Solution Options

| Option | Description | Pros | Cons | Effort |
|--------|-------------|------|------|--------|
| Front office integration | Real-time CMM in trading UI | Immediate visibility | Integration complexity | — |
| Daily alerts | Email/SMS at thresholds | Simple, low effort | Not real-time | — |
| API exposure | Let clients query CMM | Flexible, self-service | Requires client integration | — |
| RM process | Manual alerts from account managers | No tech changes | Doesn't scale, human error | — |

### Proposed Approach

*(To be developed after answering open questions)*

---

## Decision Log

| Date | Decision | Rationale | Decided By |
|------|----------|-----------|------------|
| — | — | — | — |
