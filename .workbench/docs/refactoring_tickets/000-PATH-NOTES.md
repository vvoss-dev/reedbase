# Path Reference Notes

## Important: Folder Structure Transition

Tickets 100-600 reference paths in the **current (flat) structure**.

If you execute **002-[STRUCT]-00** (folder reorganization) first, update path references in tickets:

### Path Mapping (Old → New)

| Current Path | After 002-[STRUCT]-00 |
|--------------|----------------------|
| `src/database/` | `src/api/db/` |
| `src/reedql/` | `src/api/reedql/` |
| `src/bin/` | `src/api/cli/` |
| `src/btree/` | `src/store/btree/` |
| `src/tables/` | `src/store/tables/` |
| `src/indices/` | `src/store/indices/` |
| `src/registry/` | `src/store/registry/` |
| `src/schema/` | `src/validate/schema/` |
| `src/functions/` | `src/validate/functions/` |
| `src/concurrent/` | `src/process/locks/` |
| `src/conflict/` | `src/process/conflict/` |
| `src/merge/` | `src/process/merge/` |
| `src/version/` | `src/process/version/` |
| `src/backup/` | `src/ops/backup/` |
| `src/metrics/` | `src/ops/metrics/` |
| `src/log/` | `src/ops/log/` |

## Execution Options

### Option A: Restructure First (Recommended)
```
1. Execute 001-[PREP]-00 (fix tests)
2. Execute 002-[STRUCT]-00 (reorganize folders)
3. Update path references in tickets 100-600
4. Execute remaining tickets with new paths
```

### Option B: Restructure Later
```
1. Execute 001-[PREP]-00 (fix tests)
2. Execute 100-600 with current paths
3. Execute 002-[STRUCT]-00 last (rename everything)
```

### Option C: Skip Restructure
```
1. Execute 001, 100-600 with current paths
2. Keep flat structure
3. Delete 002-[STRUCT]-00 ticket
```

## How to Update a Ticket

When you start a ticket after 002-[STRUCT]-00:

1. **Read this file** to get path mapping
2. **Find-replace** in the ticket:
   ```bash
   # Example: Update 100-[TESTS]-00
   sed -i '' 's|src/database/|src/api/db/|g' 100-[TESTS]-00-*.md
   sed -i '' 's|src/btree/|src/store/btree/|g' 100-[TESTS]-00-*.md
   # etc.
   ```
3. **Or mentally translate** while reading (simple mapping)

## Quick Reference Card

Print this for quick lookup:

```
database/    → api/db/
reedql/      → api/reedql/
bin/         → api/cli/
btree/       → store/btree/
tables/      → store/tables/
indices/     → store/indices/
registry/    → store/registry/
schema/      → validate/schema/
functions/   → validate/functions/
concurrent/  → process/locks/
conflict/    → process/conflict/
merge/       → process/merge/
version/     → process/version/
backup/      → ops/backup/
metrics/     → ops/metrics/
log/         → ops/log/
```

## Status

- [ ] 002-[STRUCT]-00 executed (folder reorganization complete)
- [ ] Tickets 100-600 paths updated
- [ ] This file can be deleted after all tickets complete

---

**TL;DR**: Tickets use old paths. If you do 002-[STRUCT]-00 first, use the table above to translate paths.
