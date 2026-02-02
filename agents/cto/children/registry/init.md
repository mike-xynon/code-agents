# Registry Agent

## Mission

Maintain and improve the Trading Registry system (`nq.trading`). Primary focus: prove the system runs locally with full test coverage.

## Repositories

Clone into your private home directory:
```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/nq.trading.git registry
git clone git@bitbucket.org:xynon/nq.trading.backoffice.web.git registry-web
```

## Key Paths (within ~/repos/registry)

| Path | Purpose |
|------|---------|
| `Trading.Api/` | Main API project |
| `Trading.Tests/` | Unit and integration tests |
| `Trading.Tests/Auth/` | Authenticated API tests |
| `Trading.Tests/Utils/ConfigHelper.cs` | Connection string logic |

## Current Objective

**Local dev infrastructure is COMPLETE.** Next objectives:

1. **Investigate container memory leak** - EF Core creates too many service providers
2. **Fix deposit allocation bug** - `/admin/deposit-allocation` has async issue
3. **Fix remaining 8 unit test failures** - Actual code bugs in workflows

## Completion Criteria

| Criteria | Status |
|----------|--------|
| Postgres container on 54320 | Done |
| SQL Edge container on 14330 | Done |
| Migrations applied | Done |
| Unit tests >90% passing | 52/60 (87%) |
| Integration tests passing | 33/34 (97%) |
| API serves authenticated requests | Done |
| Docker container working | Done |

## Workflow

1. Read `design.md` for architecture decisions and known issues
2. Read `report.md` for current progress and blockers
3. Clone repositories if not already done
4. Check `inbox/` for control messages from CTO
5. Work incrementally, updating `report.md` with progress
6. Report significant progress to `../../inbox/`

## Test Commands

```bash
# Run all tests
ASPNETCORE_ENVIRONMENT=Development dotnet test ~/repos/registry/Trading.Tests

# Run integration tests only
dotnet test ~/repos/registry/Trading.Tests --filter "FullyQualifiedName~IntegrationTestCases"

# Run auth tests only
dotnet test ~/repos/registry/Trading.Tests --filter "FullyQualifiedName~Auth"
```

## API Commands

```bash
# Run API on host
cd ~/repos/registry/Trading.Api
ASPNETCORE_ENVIRONMENT=Development \
ConnectionStrings__Database="Host=localhost;Port=54320;Database=nq_registry_local;Username=postgres;Password=TestPass123!" \
ConnectionStrings__Instruments="Server=localhost,14330;Database=InstrumentsTest;User Id=sa;Password=TestPass123!;TrustServerCertificate=True;" \
dotnet run

# Or use Docker (requires pre-build)
dotnet publish Trading.Api -c Release -o ./publish
docker build -t trading-api-local .
docker run -d --name trading-api-local -p 5038:8080 \
  -e "ConnectionStrings__Database=Host=host.docker.internal;Port=54320;..." \
  trading-api-local
```
