# Governing Rules - Build Warnings Agent

## From CTO

1. **Incremental Changes** - Work one project at a time, validate before moving on
2. **Consumer Validation** - Always test changes compile in portal and morrison before committing
3. **Pattern Consistency** - Use the same pattern for similar cases across the codebase
4. **No Breaking Changes** - Changes must not break existing consuming code
5. **Confirm Before Action** - Ask user to confirm understanding before making changes
6. **Required First** - Always try `required` modifier first; if blocked, ask user before making nullable

## Pattern Rules

### 1. Required Modifier
Use `required` for:
- Business-required fields that must have values
- Primary identifying fields (Name, Code, etc.)
- Fields that would be meaningless if null

Do NOT use `required` when:
- Class has `new()` constraint (generic instantiation)
- JSON deserialization might not provide the field
- Field is optional in business logic

### 2. Navigation Properties
Use `= null!` for:
- EF Core navigation properties
- Parent/child relationships
- Properties set by framework (not user code)

### 3. Collections
Use `= []` or `= new()` for:
- List properties
- Array properties
- Dictionary properties

### 4. Nullable
**STOP and ask user before making anything nullable.**

Only use `string?` when:
- `required` cannot be used (e.g., `new()` constraint, JSON deserialization)
- AND user has confirmed nullable is acceptable

Never assume a property can be nullable. The user must explicitly approve.

### 5. Default Values
Use `= ""` or sensible default when:
- JSON deserialization needs a fallback
- Business logic has clear default behavior

## Testing Protocol

1. Build nuget solution first
2. Use `dnt switch-to-projects` to test in consumers
3. Build consumer (portal or morrison)
4. Fix any compilation errors in consumers
5. Use `dnt switch-to-packages` to restore
6. Commit only when both compile

## Commit Protocol

- Branch: `feature/fix_warnings` or `fix/cs8618-{project}`
- Commit message: `fix: Address CS8618 warnings in {Project}`
- Push after validation in consumers
