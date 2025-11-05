# Refactoring Tickets

**Purpose**: Systematic refactoring of ReedBase to mustergültig (exemplary) standards before v0.2.0-beta launch.

## Ticket Naming Convention

```
{number}-[{context}]-{sub}-{short-desc}.md
```

**Examples**:
- `001-[PREP]-00-fix-test-registry.md` - Fix failing tests
- `002-[STRUCT]-00-reorganize-folders.md` - Reorganize folder structure
- `100-[TESTS]-00-extract-inline-tests-overview.md` - Extract inline test modules
- `301-[SPLIT]-00-btree-tree.md` - Split btree/tree.rs
- `200-[RENAME]-00-generic-filenames.md` - Rename generic filenames

## Contexts

- **[PREP]**: Preparation & bug fixes (001-099)
- **[STRUCT]**: Structure reorganization (001-099)
- **[TESTS]**: Test-related refactoring (100-199)
- **[RENAME]**: File/function renaming (200-299)
- **[SPLIT]**: File splitting (300-399)
- **[VERIFY]**: Verification and testing (600-699)
- **[LAUNCH]**: Final commit & launch (900-999)

## Ticket Format

Each ticket contains:

```markdown
# {Context}-{Number}-{Sub}: {Title}

## Status
- [ ] Not Started
- [ ] In Progress
- [x] Complete

## Priority
- Critical / High / Medium / Low

## Estimated Effort
- Time estimate (hours)

## Context
Why this needs to be done

## Current State
What exists now (with file paths and line numbers)

## Target State
What it should look like after refactoring

## Breaking Changes
- None / Internal / Public API

## Dependencies
- Other tickets that must be completed first

## Implementation Steps
1. Step by step plan
2. With verification points

## Verification
- [ ] Tests pass
- [ ] Code compiles
- [ ] Documentation updated
- [ ] Follows CLAUDE.md standards

## Files Affected
- List of all files that will change
```

## Execution Order

Tickets are numbered to indicate execution order:
- **001-099**: Preparation & fixes
- **100-199**: Test extraction (Stufe 1)
- **200-299**: File renaming (Stufe 1)
- **300-399**: Large file splitting (Stufe 2)
- **400-499**: Deep refactoring (Stufe 2)
- **500-599**: Cleanup & polish (Stufe 3)
- **600-699**: Verification & documentation
- **900-999**: Final commit & launch prep

## Current Status

**Total Tickets**: TBD  
**Completed**: 0  
**In Progress**: 0  
**Not Started**: TBD

See individual ticket files for detailed status.
