# Build Warnings Agent

## Mission

Eliminate CS8618 build warnings across NQ NuGet libraries using consistent, type-safe patterns that don't break consuming projects.

## Repository

Clone into your private home directory (`~/repos/`):

| Name | Bitbucket Repo | Purpose |
|------|----------------|---------|
| nuget | `xynon/nq-nugetlibraries` | Shared NuGet packages (target) |
| portal | `xynon/portal` | Consumer validation |
| morrison | `xynon/nq-morrison` | Consumer validation (OMS) |

```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/nq-nugetlibraries.git nuget
git clone git@bitbucket.org:xynon/portal.git portal
git clone git@bitbucket.org:xynon/nq-morrison.git morrison
```

## Warning Context

CS8618: "Non-nullable property 'X' must contain a non-null value when exiting constructor"

This occurs when a property is declared as non-nullable (`string Name`) but isn't initialized in the constructor.

## Patterns (See design.md for full details)

| Pattern | When to Use |
|---------|-------------|
| `required` modifier | Business-required fields that must be set at construction |
| `= null!` | Navigation properties, EF Core relationships |
| `= new()` or `= []` | Collections, simple DTOs |
| `string?` | Optional fields, or when `new()` constraint needed |
| `= ""` or `= "default"` | Strings with sensible defaults |

## Current State

**Completed:**
- NQ.AssetModels entities (27 files) - `required` pattern applied
- NQ.Facts.Model.Core entities (30 files) - `required` pattern applied
- Consumer validation in Morrison and Portal

**In Progress:**
- NQ.Trading.Models - 653 warnings (largest source)
- FinancialYearSummary analysis pending

**Blockers:**
- None currently

## Workflow

1. Read `design.md` to understand pattern decisions
2. Check `report.md` for current progress and warning counts
3. Build to get current warning count: `dotnet build 2>&1 | Select-String "warning CS8618"`
4. Focus on one project at a time
5. Test changes compile in consuming projects using `dnt switch-to-projects`
6. Update report.md with progress
7. Message parent at `../../inbox/build-warnings-YYYY-MM-DD-HHMM.md` when blocked or complete

## First Steps (New Session)

1. Read `design.md` for pattern decisions
2. Read `report.md` for current progress
3. Check `inbox/` for control messages
4. Build nuget repo to get current warning count
5. Confirm next task with user before implementing
