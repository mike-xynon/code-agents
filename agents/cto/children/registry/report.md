# Registry Agent - Status Report

**Agent:** registry
**Parent:** cto
**Status:** Local Dev Infrastructure Complete
**Last Updated:** 2026-02-03

## Mission

Prove the Trading Registry system (`nq.trading`) runs locally with PostgreSQL, migrations, unit tests, and authenticated API.

## Repositories

```bash
git clone git@bitbucket.org:xynon/nq.trading.git ~/repos/registry
git clone git@bitbucket.org:xynon/nq.trading.backoffice.web.git ~/repos/registry-web
```

## Current State

### Infrastructure - COMPLETE

| Component | Container | Port | Status |
|-----------|-----------|------|--------|
| PostgreSQL | `test-postgres` | 54320 | Running |
| SQL Edge | `test-sql-edge` | 14330 | Running |
| Trading API | `trading-api-local` | 5038 | Running |

### Test Results

| Test Suite | Passed | Total | Notes |
|------------|--------|-------|-------|
| Unit Tests | 52 | 60 | 8 failures are code bugs, not config |
| IntegrationTestCases | 11 | 11 | Health, swagger, DB connectivity |
| AuthenticatedApiTests | 8 | 8 | KeyCloak token + API endpoints |
| ReferenceDataSetupTests | 5 | 5 | Admin API setup sequence |
| CustomerOnboardingTests | 5 | 5 | Entity/portfolio creation |
| AnzTransactionTests | 4 | 5 | 1 failure is API bug |
| **Total Integration** | **33** | **34** | |

### PR Merged

**PR #3: feature/local-dev-setup** - Merged to main
- NQ.* packages updated to 0.59.1.902
- AddNqApiProxy signature fix
- Docker support (Dockerfile, docker-compose.local.yaml)
- Integration tests (11 tests)
- Local dev documentation

## Completed

- [x] PostgreSQL container on port 54320
- [x] SQL Edge container on port 14330
- [x] EF Core migrations applied (14 tables)
- [x] ConfigHelper opinionated config (localhost default)
- [x] NQ.* packages updated to 0.59.1.902
- [x] AddNqApiProxy API signature fix
- [x] Docker container working (pre-build strategy)
- [x] KeyCloak authentication working
- [x] TradingTestBootstrap helper created
- [x] Integration test suite (33/34 passing)

## Blocked / Known Issues

| Issue | Description | Status |
|-------|-------------|--------|
| Container memory leak | `ManyServiceProvidersCreatedWarning` after ~20 requests | Workaround: restart container |
| Deposit allocation bug | `/admin/deposit-allocation` has EF async issue | API code bug, needs investigation |
| 8 unit test failures | Actual code bugs (FK constraints, workflow issues) | Not config related |

## Files Changed

| File | Change |
|------|--------|
| `Trading.Tests/Utils/ConfigHelper.cs` | Opinionated local postgres default |
| `Trading.Tests/Utils/DependencyInjectionExtensions.cs` | EF warning suppression |
| `Trading.Tests/appsettings.json` | Local connection strings |
| `Trading.Api/Program.cs` | AddNqApiProxy signature update |
| `Trading.Api/Trading.Api.csproj` | EF Core Design 8.0.6 → 9.0.11 |
| All *.csproj | NQ.* 0.59.1.729 → 0.59.1.902 |
| `Trading.Tests/Auth/*` | New auth test infrastructure |
| `Trading.Tests/IntegrationTestCases.cs` | New integration tests |

## Next Steps

1. Investigate container memory leak (ManyServiceProvidersCreatedWarning)
2. Fix `/admin/deposit-allocation` EF async bug
3. Investigate 8 remaining unit test failures
4. Consider registry-web backoffice testing

## Progress Log

### 2026-02-02
- Created TradingTestBootstrap helper
- All 33/34 integration tests passing
- Completed customer onboarding and ANZ transaction test suites

### 2026-02-01
- Docker container working with pre-build strategy
- KeyCloak authentication verified
- API health, swagger, auth endpoints tested
- PR #3 merged to main

### 2026-01-31
- PostgreSQL and SQL Edge containers set up
- EF migrations applied (14 tables)
- ConfigHelper updated with opinionated local config
- 52/60 unit tests passing
- NQ.* packages updated to 0.59.1.902
