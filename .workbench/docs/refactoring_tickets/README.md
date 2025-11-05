# Refactoring Tickets

**Purpose**: Systematic refactoring of ReedBase to mustergültig (exemplary) standards before v0.2.0-beta launch.

## Ticket Naming Convention

```
{context}-{ticket-number}-{sub-number}-{short-desc}.md
```

**Examples**:
- `TESTS-001-00-extract-inline-tests.md` - Extract inline test modules
- `SPLIT-002-00-btree-tree.md` - Split btree/tree.rs
- `RENAME-003-00-generic-names.md` - Rename generic filenames
- `CLEANUP-004-00-mod-files.md` - Clean up mod.rs files

## Contexts

- **TESTS**: Test-related refactoring (inline → _test.rs)
- **SPLIT**: File splitting (large files → focused modules)
- **RENAME**: File/function renaming (generic → specific)
- **CLEANUP**: General cleanup (mod.rs, docs, etc.)
- **FIX**: Bug fixes discovered during refactoring
- **VERIFY**: Verification and testing tasks

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
