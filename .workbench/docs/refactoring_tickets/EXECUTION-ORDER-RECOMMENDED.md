# EMPFOHLENE AUSFÜHRUNGSREIHENFOLGE (Löst Kohärenz-Probleme)

## 🎯 OPTIMALE REIHENFOLGE

Diese Reihenfolge löst ALLE Kohärenz-Probleme:

### Phase 0: Vorbereitung & Foundation
```
050-[REUSE]-00  Architecture & Redundancy Audit (CRITICAL FIRST!)
    ↓ Creates core/ module, eliminates duplicates, establishes architecture
    ↓ Output: Consolidation plan + sub-tickets (051-07X)
    ↓
051-07X         Execute consolidation sub-tickets (from 050 analysis)
    ↓ Centralise paths, validation, eliminate duplicates
    ↓ Result: 100% redundancy-free codebase with core/ module
    ↓
001-[PREP]-00   Fix failing tests (after redundancy elimination)
    ↓
002-[STRUCT]-00 Folder reorganisation (DO NOW - before everything else!)
    ↓
    (Ab jetzt arbeiten ALLE Tickets mit finaler Struktur + core/)
```

**Warum 050 ZUERST?**
- ✅ **CRITICAL**: Establishes core/ module for default functions
- ✅ **CRITICAL**: Eliminates redundancy BEFORE other refactoring
- ✅ **CRITICAL**: Validates NO MVC architecture
- ✅ Prevents re-creating duplicates during other refactoring
- ✅ Clear module boundaries before folder restructure

**Warum 002 nach 050?**
- ✅ Alle nachfolgenden Tickets arbeiten mit `api/db/`, `store/btree/`, `core/` etc.
- ✅ Keine duale Pfad-Verwirrung mehr
- ✅ Einmalige Import-Update-Arbeit, dann fertig

---

### Phase 1: Analyse (Parallelisierbar)
```
150-[LANG]-00 ┐
151-154       │
              ├──→ Alle 3 parallel ausführen
210-[AUDIT]-00│
211-213       │
              │
250-[FUNC]-00 │
251-253       ┘

Output: Analysis reports in _workbench/analysis/
```

**Nach Phase 1: PAUSE für User-Review**
```
User reviewed:
- _workbench/analysis/american_spellings.md
- _workbench/analysis/generic_files_found.md  
- _workbench/analysis/long_functions.md

User creates fix tickets:
- 155-156: BBC English function renames (if needed)
- 214-220: Additional generic file renames (found by 211-213)
- 254-265: Function splits (found by 251-253)
```

---

### Phase 2: File Splits (DO BEFORE Test Extraction!)
```
300-[SPLIT]-00  Overview
301-[SPLIT]-00  btree/tree.rs → 5 files
302-[SPLIT]-00  reedql/parser.rs → 4 files
303-[SPLIT]-00  reedql/executor.rs → 3 files
304-[SPLIT]-00  btree/page.rs → 2 files
305-[SPLIT]-00  database/execute.rs → 4 files (OPTIONAL)
306-[SPLIT]-00  formatters/mod.rs → 4 files (OPTIONAL)
```

**Warum JETZT?**
- ✅ Löst Problem 2: Test extraction arbeitet dann mit finalen Files
- ✅ z.B. `execute_insert_test.rs` statt ein grosses `execute_test.rs`

---

### Phase 3: Test Extraction (Nach File Splits!)
```
100-[TESTS]-00  Overview
101-[TESTS]-00  api/db/types.rs → types_test.rs
102-[TESTS]-00  api/db/execute_insert.rs → execute_insert_test.rs (nach Split!)
103-[TESTS]-00  api/db/execute_update.rs → execute_update_test.rs (nach Split!)
...
117-[TESTS]-00  store/indices/builder.rs → builder_test.rs
```

**Wichtig**: Wenn 305 gemacht wurde, dann:
- 102 extrahiert Tests aus `execute_insert.rs` (nicht `execute.rs`)
- Tests passen direkt zu finalen Files

---

### Phase 4: BBC English Fixes
```
151-[LANG]-01  Fix -ize endings (comments auto, functions manual)
152-[LANG]-02  Fix -yze endings
153-[LANG]-03  Fix -or endings
154-[LANG]-04  Fix -er endings
155-156...     Additional function renames (from 151 findings)
```

---

### Phase 5: Renames & Audit Results
```
200-[RENAME]-00 Known violations (helpers.rs, builder_tests.rs)
214-220...      Additional renames (from 211-213 findings)
```

---

### Phase 6: Function Refactoring
```
254-265...  Function splits (from 251-253 findings)
```

---

### Phase 7: Verification
```
600-[VERIFY]-00 Final CLAUDE.md compliance check
```

---

### Phase 8: Launch
```
900-[LAUNCH]-00 Squash all commits, push to GitHub
```

---

## 🔧 LÖSUNGEN FÜR ALLE 6 PROBLEME

### Problem 1: Dynamische Tickets ✅ GELÖST
**Lösung**: Analysis → User Review → Ticket Creation (dokumentiert in ANALYSIS-TO-FIX-WORKFLOW.md)

### Problem 2: Test/Split Konflikt ✅ GELÖST
**Lösung**: File Splits (Phase 2) VOR Test Extraction (Phase 3)
- Tests werden für finale split files erstellt
- Kein Re-Work nötig

### Problem 3: Pfad-Timing ✅ GELÖST
**Lösung**: 002-[STRUCT]-00 SOFORT nach 001 (Phase 0)
- Alle anderen Tickets arbeiten mit finaler Struktur
- Duale Pfade nur noch als Fallback

### Problem 4: BBC English User-Decisions ✅ GELÖST
**Lösung**: 
- 151-154 erstellen Analyse-Reports
- User reviewed und entscheidet
- 155+ werden nur bei Bedarf erstellt

### Problem 5: Fehlende Dependencies ✅ GELÖST
**Lösung**: Execution Order garantiert richtige Reihenfolge
- File Splits vor Test Extraction
- Keine Dependencies nötig (Reihenfolge regelt es)

### Problem 6: Audit → Fix Workflow ✅ GELÖST
**Lösung**: Siehe ANALYSIS-TO-FIX-WORKFLOW.md
- 211-213 → Analysis reports
- User reviewed → creates 214-220
- Clear workflow documented

---

## ⏱️ ZEITAUFWAND MIT DIESER REIHENFOLGE

**Phase 0**: 2.5h (001: 30min, 002: 2h)
**Phase 1**: 3h (Analyse parallel)
  → PAUSE: User Review (1h)
  → PAUSE: Create Fix Tickets (1h)
**Phase 2**: 4-7h (File Splits, optional 305-306)
**Phase 3**: 2.5h (Test Extraction)
**Phase 4**: 1h (BBC English)
**Phase 5**: 1h (Renames + Audit Results)
**Phase 6**: 3-5h (Function Refactoring)
**Phase 7**: 1h (Verification)
**Phase 8**: 15min (Launch)

**Total: ~19-24 hours** (inkl. User Review Zeit)

---

## 🎯 EMPFEHLUNG

**Option A: Vollständig (Mustergültig)**
- Alle Phasen wie oben
- 100% CLAUDE.md compliance
- 19-24 Stunden
- 🏆 Exemplary codebase

**Option B: High Value (Empfohlen)**
- Phase 0-5 komplett
- Phase 6: Nur HIGH priority function splits (3h statt 5h)
- Skip 305-306 (MEDIUM/LOW file splits)
- ~15-18 Stunden
- ✅ Good compliance

**Option C: Minimum (Schnell)**
- Phase 0-5 komplett
- Skip Phase 6 (Function Refactoring)
- Skip 305-306
- ~12-15 Stunden
- ⚠️ Incomplete compliance (Standards #4 & #6 teilweise)

