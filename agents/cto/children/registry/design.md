# Registry Agent Design Notes

## Objective

Prove the Registry system (`nq.trading`) runs locally with:
- PostgreSQL database + migrations
- Unit tests passing
- API serving requests with authentication

## Repositories

Clone to `~/repos/`:
```bash
git clone git@bitbucket.org:xynon/nq.trading.git ~/repos/registry
git clone git@bitbucket.org:xynon/nq.trading.backoffice.web.git ~/repos/registry-web
```

## Local Infrastructure

| Component | Container | Port | Database |
|-----------|-----------|------|----------|
| PostgreSQL | `test-postgres` | 54320 | `nq_registry_local` |
| SQL Edge | `test-sql-edge` | 14330 | `InstrumentsTest` |
| Trading API | `trading-api-local` | 5038 | - |

### Connection Strings

```
# PostgreSQL (Registry)
Host=localhost;Port=54320;Database=nq_registry_local;Username=postgres;Password=TestPass123!

# SQL Edge (Instruments)
Server=localhost,14330;Database=InstrumentsTest;User Id=sa;Password=TestPass123!;TrustServerCertificate=True;
```

## Architecture Decisions

### 1. Opinionated Test Config

**Decision:** `ConfigHelper.cs` returns hardcoded local postgres by default for developer machines.

**Rationale:** Zero-config for developers. Just start postgres on 54320, tests work.

**Detection Logic:**
- Check env var `ConnectionStrings__Database` first (explicit override wins)
- Check `CODEBUILD_BUILD_ID` for CI environment
- Default to local postgres convention

### 2. Docker Build Strategy

**Decision:** Pre-build on host, copy binaries to container.

**Rationale:** NQ.* packages are in private Xynon NuGet repo. Docker build fails at restore without credentials. Building on host uses ambient NuGet credentials.

**Commands:**
```bash
dotnet publish Trading.Api -c Release -o ./publish
docker build -t trading-api-local .
```

### 3. EF Core Warning Suppression

**Decision:** Add `AddTestTradingDbContext()` method that suppresses `ManyServiceProvidersCreatedWarning`.

**Rationale:** Each test class creates its own ServiceProvider. EF Core warns after 20+ providers. This is expected in test isolation, not a real issue.

**File:** `Trading.Tests/Utils/DependencyInjectionExtensions.cs`

### 4. TradingTestBootstrap Helper

**Decision:** Create initialization helper that runs setup steps in order.

**Steps:**
1. Create root entity (`POST /admin/create-root-entity?portfolioType=VMA`)
2. Create cash locations (`PUT /admin/create-root-cash-locations`)
3. Create root cash holdings (`PUT /admin/create-root-cash-holdings`)
4. Activate root entity (`PATCH /admin/activate-entity/{id}`)

**File:** `Trading.Tests/Auth/TradingTestBootstrap.cs`

### 5. KeyCloak Authentication

**Config:**
- Base URL: `https://auth.xynon.xyz`
- Realm: `master`
- Client ID: `registry`

**File:** `Trading.Tests/Auth/KeyCloakAuthHelper.cs`

## Code References

| File | Purpose |
|------|---------|
| `Trading.Tests/Utils/ConfigHelper.cs` | Opinionated connection string logic |
| `Trading.Tests/Utils/DependencyInjectionExtensions.cs` | Test DbContext with warning suppression |
| `Trading.Tests/Auth/TradingTestBootstrap.cs` | Environment initialization helper |
| `Trading.Tests/Auth/KeyCloakAuthHelper.cs` | Token acquisition for authenticated tests |
| `Trading.Tests/Auth/AuthenticatedApiTests.cs` | API endpoint tests with auth |
| `Trading.Tests/IntegrationTestCases.cs` | Health, swagger, database connectivity tests |

## Known Issues

### 1. Container Memory Leak

**Symptom:** API container returns 500 errors after ~20 DbContext operations.

**Cause:** EF Core `ManyServiceProvidersCreatedWarning` - too many service providers created.

**Workaround:** `docker restart trading-api-local`

**Proper Fix:** Investigate why API creates multiple service providers per request.

### 2. Deposit Allocation API Bug

**Endpoint:** `POST /admin/deposit-allocation`

**Error:** `The provider for the source IQueryable doesn't implement IDbAsyncQueryProvider`

**Status:** API code bug, not test issue. Needs investigation in `nq.trading` codebase.

## Test Run Commands

```bash
# All tests (requires ASPNETCORE_ENVIRONMENT for business day check bypass)
ASPNETCORE_ENVIRONMENT=Development dotnet test Trading.Tests

# Integration tests only
dotnet test Trading.Tests --filter "FullyQualifiedName~IntegrationTestCases"

# Auth tests only
dotnet test Trading.Tests --filter "FullyQualifiedName~Auth"

# Run API on host
cd Trading.Api
ASPNETCORE_ENVIRONMENT=Development \
ConnectionStrings__Database="Host=localhost;Port=54320;Database=nq_registry_local;Username=postgres;Password=TestPass123!" \
ConnectionStrings__Instruments="Server=localhost,14330;Database=InstrumentsTest;User Id=sa;Password=TestPass123!;TrustServerCertificate=True;" \
dotnet run
```
