# Build Warnings Agent - Design & Patterns

## Problem Statement

CS8618 warnings indicate non-nullable properties that aren't initialized. These warnings need resolution that:
1. Maintains type safety (doesn't just suppress warnings)
2. Works with EF Core conventions
3. Works with JSON serialization/deserialization
4. Doesn't break consuming projects

## Pattern Decision Tree

```
Is the property a navigation property (EF relationship)?
├── Yes ↓
│   Is it a required relationship (FK is non-nullable)?
│   ├── Yes → Non-nullable FK (Guid) + Nullable nav with [Required] attribute
│   └── No  → Nullable FK (Guid?) + Nullable nav (Entity?)
└── No ↓

Is it a collection?
├── Yes → Use `= []` or `= new()`
└── No ↓

Try to use `required` modifier first.

Does `required` work?
├── Yes → Use `required` (DONE)
└── No (blocked by `new()` constraint, JSON deserialization, etc.) ↓

    STOP: Ask user before proceeding.
    "Can this property be nullable? Should it be?"

    User confirms nullable is acceptable?
    ├── Yes → Use `string?`
    └── No → Use default value `= ""` or discuss alternative
```

**Key Rule:** Never assume a property can be nullable. Always ask the user for confirmation when `required` cannot be used.

## Pattern Examples

### 1. Required Modifier (Preferred for business-required)
```csharp
public class Instrument
{
    public required string Code { get; set; }
    public required string Name { get; set; }
    public required string Sector { get; set; }
}
```

### 2. Navigation Properties (EF Core)

**Required relationship (non-nullable FK):**
```csharp
public class AssetModelItem
{
    public Guid AssetModelId { get; set; }           // Non-nullable FK - DB constraint
    [Required]
    public AssetModel? AssetModel { get; set; }      // Nullable nav + Required validation
}
```

**Optional relationship (nullable FK):**
```csharp
public class Order
{
    public Guid? ParentOrderId { get; set; }         // Nullable FK - optional in DB
    public Order? ParentOrder { get; set; }          // Nullable nav
}
```

**Why NOT `= null!`:** It hides nullability issues and doesn't work well with EF Core's model detection for required relationships.

### 3. Collections
```csharp
public class Portfolio
{
    public List<Position> Positions { get; set; } = [];
    public Dictionary<string, object> Metadata { get; set; } = new();
}
```

### 4. When `new()` Constraint Blocks `required`
```csharp
// BEFORE (causes CS9040 error)
public class NqEmploymentDetail
{
    public required string Occupation { get; set; }
}

// AFTER
public class NqEmploymentDetail
{
    public string? Occupation { get; set; }  // Nullable because new() constraint
}
```

### 5. JSON Deserialization with Default
```csharp
public sealed class LimitRuleCriteria : RuleCriteria
{
    public string FocusValue { get; set; } = "*";  // Default for missing JSON
}
```

### 6. System-Created Entities
When creating entities in system/background processes, use the constant:
```csharp
var entity = new BankAccount
{
    Id = Guid.NewGuid(),
    CreatedBy = EntityBase.SystemCreatedBy,  // Use constant, not "system" string
};
```

## Project-Specific Notes

### NQ.AssetModels
- Entity classes use `required` for business fields
- Navigation properties use `= null!`
- Applied successfully, merged to main

### NQ.Facts.Model.Core
- Same pattern as AssetModels
- Exception: `NqEmploymentDetail` uses nullable due to `new()` constraint
- Applied successfully, merged to main

### NQ.Trading.Models
- **FinancialYearSummary** - Pending analysis
  - Sub-objects (AccountFlows, MoneyIn, etc.) currently use `= null!`
  - Builder pattern always creates them
  - Tests create partial objects for specific scenarios
  - Recommendation: Use `= new()` for simple DTOs, nullable for complex ones

- High warning count (653) - largest remaining project

### NQ.Copilot
- Currently excluded from this work
- Has separate Trading mode implementation in progress

## Known Issues

### `required` + `new()` Constraint Conflict
Error CS9040: Cannot satisfy `new()` constraint because type has required members.

**Solution:** Change `required string` to `string?` for classes used in generic contexts with `new()` constraint.

### JSON Deserialization Missing Required Fields
When JSON doesn't include a required field, deserialization fails.

**Solution:** Use default value instead of `required`:
```csharp
public string Field { get; set; } = "default";
```

## Warning Counts (Last Updated: 2026-02-03)

| Project | Warnings | Status |
|---------|----------|--------|
| NQ.Trading.Models | 653 | In Progress |
| NQ.Copilot | 290 | Not Started |
| NQ.Hosting | 180 | Not Started |
| NQ.Facts.Model.Core | 0 | Complete |
| NQ.AssetModels | 0 | Complete |

## Consumer Projects

Changes must compile in:
- `portal` - Main UI/API application
- `nq-morrison` - OMS trading system

Use `dnt switch-to-projects` tool to test local changes before publishing.
