# QS-Matrix Template für alle Tickets

**Verwendung**: Diese Matrix MUSS in JEDEM Ticket integriert werden, um kontinuierliche Qualität während des Clean Room Neubaus zu garantieren.

---

## ✅ Integrierte Qualitätssicherungs-Matrix

**Kopiere diesen Abschnitt in jedes Ticket und checke während der Implementierung ab.**

### Standard #0: Code Reuse (MANDATORY CHECK)

- [ ] **Funktionssuche durchgeführt** - Vor jeder neuen Funktion: Existiert sie bereits in src/ oder src-old/?
- [ ] **Keine Duplikate erstellt** - Wenn ähnliche Funktion existiert: Erweitern statt neu schreiben
- [ ] **Core-Module genutzt** - Verwendet `core::paths`, `core::validation` statt eigene Utilities
- [ ] **Dokumentiert warum neu** - Wenn neue Funktion: Begründung warum nicht existierend verwendet

**Check-Kommando**:
```bash
# Suche ob Funktion bereits existiert
rg "pub fn function_name" src/ src-old/
grep "function_name" _workbench/analysis/050-all-functions.txt
```

---

### Standard #1: BBC English (MANDATORY CHECK)

- [ ] **Kommentare in BBC English** - Alle `//` und `///` Kommentare: `initialise` (nicht `initialize`)
- [ ] **Docstrings in BBC English** - Alle `//!` und `///` Docs: `behaviour`, `colour`, `optimise`
- [ ] **Code-Identifier reviewed** - Funktionsnamen mit American spellings dokumentiert/reviewed
- [ ] **Error messages in BBC English** - Alle Error-Texte: BBC spelling

**Häufige Korrekuren**:
```rust
// ❌ American English
initialize(), optimize(), analyze(), color, behavior

// ✅ BBC English  
initialise(), optimise(), analyse(), colour, behaviour
```

**Ausnahme**: Code-Identifier (Funktionsnamen) können American spelling haben wenn:
- Established in Rust ecosystem (`serialize` from serde)
- Domain-specific terminology
- Wird in 050 analysis dokumentiert und user-entschieden

---

### Standard #2: KISS - File Size <400 Lines (MANDATORY CHECK)

- [ ] **Line count checked** - `wc -l file.rs` zeigt <400 Zeilen
- [ ] **Bei Überschreitung: Split-Plan** - Wenn >400: Dokumentiere wie zu splitten
- [ ] **Kommentare zählen mit** - Header + Comments zählen zur Line-Limit
- [ ] **Keine künstliche Kompression** - Nicht mehrere Statements pro Zeile

**Check-Kommando**:
```bash
wc -l src/module/file.rs
# If >400: Create split ticket immediately
```

**Split-Strategie** (wenn >400):
```
file.rs (450 lines) →
  ├─ file_core.rs (200 lines) - Hauptlogik
  ├─ file_helpers.rs (150 lines) - Hilfsfunktionen
  └─ file_test.rs (100 lines) - Tests (sowieso separat)
```

---

### Standard #3: File Naming (MANDATORY CHECK)

- [ ] **Dateiname = Verantwortlichkeit** - Name beschreibt EINE klare Aufgabe
- [ ] **Keine generischen Namen** - KEINE `helpers.rs`, `utils.rs`, `common.rs`, `misc.rs`
- [ ] **Spezifisch, nicht vage** - `path_construction.rs` statt `paths.rs` wenn spezifisch
- [ ] **Konsistenz geprüft** - Namensschema passt zu anderen Dateien im Modul

**Gute Dateinamen**:
```
✅ src/core/path_construction.rs    (spezifisch)
✅ src/core/key_validation.rs       (spezifisch)
✅ src/api/db/query_executor.rs     (spezifisch)
```

**Schlechte Dateinamen**:
```
❌ src/core/helpers.rs              (zu generisch)
❌ src/core/utils.rs                (zu generisch)
❌ src/api/db/stuff.rs              (vage)
```

---

### Standard #4: One Function = One Job (MANDATORY CHECK)

- [ ] **Single Responsibility** - Jede Funktion macht EINE Sache
- [ ] **Funktionslänge <100 Zeilen** - Bei Überschreitung: Splitten
- [ ] **Parameter-Count <5** - Wenn >5 Parameter: Struct/Builder erwägen
- [ ] **Keine "handle/process/manage"** - Namen wie `handle_request` sind Red Flags (zu generisch)

**Check-Kommandos**:
```bash
# Finde lange Funktionen (>100 lines)
rg "^pub fn" src/module/ -A 100 | grep "^}" | wc -l

# Finde komplexe Signaturen (>5 params)
rg "pub fn \w+\([^)]*,[^)]*,[^)]*,[^)]*,[^)]*,[^)]*" src/module/
```

**Split-Strategie** (wenn Funktion zu komplex):
```rust
// ❌ God Function (macht zu viel)
pub fn process_query_and_return_result(...) { /* 150 lines */ }

// ✅ Split in kleinere Funktionen
pub fn parse_query(...) -> Query { ... }
pub fn execute_query(query: &Query) -> Result { ... }
pub fn format_result(result: Result) -> String { ... }
```

---

### Standard #5: Separate Test Files (MANDATORY CHECK)

- [ ] **Tests in _test.rs** - NIEMALS inline `#[cfg(test)] mod tests`
- [ ] **Test-Dateiname korrekt** - `file.rs` → `file_test.rs` (Snake-Case mit _test suffix)
- [ ] **Copyright Header** - Test-Dateien haben auch Copyright + SPDX
- [ ] **Imports korrekt** - `use super::*;` oder explizite imports

**Struktur**:
```
src/module/
├─ file.rs           (Implementation)
└─ file_test.rs      (Tests)
```

**Test-Datei Template**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for module::file

use super::*;

#[test]
fn test_specific_behaviour() {
    // Arrange
    // Act
    // Assert
}
```

---

### Standard #6: No Swiss Army Functions (MANDATORY CHECK)

- [ ] **Keine Multi-Purpose Funktionen** - Funktion macht nicht "X oder Y je nach Flag"
- [ ] **Boolean-Parameter vermieden** - `do_thing(x, true, false)` ist Red Flag
- [ ] **Keine langen Match-Statements** - Bei >5 Arms: Separate Funktionen erwägen
- [ ] **Single Entry Point** - Eine Funktion = ein klarer Zweck

**Red Flags**:
```rust
// ❌ Swiss Army Knife
pub fn process(data: Data, mode: Mode, flag1: bool, flag2: bool) {
    match mode {
        Mode::A if flag1 => { /* 30 lines */ }
        Mode::A if !flag1 => { /* 25 lines */ }
        Mode::B if flag2 => { /* 40 lines */ }
        // ... 5 more arms
    }
}

// ✅ Separate, focused functions
pub fn process_mode_a(data: Data) -> Result<Output> { ... }
pub fn process_mode_b(data: Data) -> Result<Output> { ... }
```

---

### Standard #7: No Generic Names (MANDATORY CHECK)

- [ ] **Spezifische Funktionsnamen** - `validate_key()` statt `validate()`
- [ ] **Spezifische Struct-Namen** - `QueryExecutor` statt `Executor`
- [ ] **Spezifische Variable-Namen** - `table_name` statt `name`, `user_id` statt `id`
- [ ] **Kontext klar** - Namen sind ohne Kontext verständlich

**Beispiele**:
```rust
// ❌ Zu generisch
pub fn validate(s: &str) -> bool { ... }
pub struct Builder { ... }
pub fn process(data: Data) -> Result { ... }

// ✅ Spezifisch
pub fn validate_table_name(name: &str) -> Result<(), ReedError> { ... }
pub struct QueryBuilder { ... }
pub fn execute_insert_query(query: &InsertQuery) -> Result<usize> { ... }
```

---

### Standard #8: Architecture - NO MVC (MANDATORY CHECK)

- [ ] **Keine Controller** - Keine `handle_request()` Funktionen in lib code
- [ ] **Keine Models mit Behaviour** - Structs sind pure data, keine `impl { fn save() }`
- [ ] **Keine Views** - Kein `Display`, `format!`, `println!` in lib (nur in bin/)
- [ ] **Pure Functions** - Data in → Data out, keine Side-Effects (außer dokumentiert)

**ReedBase Architecture** (Layered, nicht MVC):
```
src/ops/        → Operations (backup, metrics, versioning)
src/process/    → Processing (concurrent, locks)
src/validate/   → Validation (schema, RBKS)
src/api/        → API (db, reedql)
src/store/      → Storage (btree, tables, indices)
src/core/       → Core utilities (paths, validation)
```

**Erlaubt**:
```rust
// ✅ Pure function
pub fn execute_query(query: &Query, tables: &[Table]) -> Result<Vec<Row>>

// ✅ Trait-based
pub trait Index {
    fn lookup(&self, key: &str) -> Option<&Row>;
}

// ✅ Builder (no behaviour on data)
pub struct QueryBuilder { ... }
```

**NICHT erlaubt**:
```rust
// ❌ Controller pattern
pub fn handle_insert_request(req: InsertRequest) -> InsertResponse

// ❌ Model with behaviour  
impl Table {
    pub fn save(&mut self) { /* writes to disk */ }
}

// ❌ View in lib
impl Display for Row {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result { ... }
}
```

---

## 🎯 Verwendung in Tickets

### Integration in Ticket-Template

Jedes Ticket bekommt diesen Abschnitt **vor** "Implementation Steps":

```markdown
## ✅ Qualitätssicherung + Regression Testing (MANDATORY!)

### Pre-Implementation
- [ ] Standard #0: Funktionssuche durchgeführt (keine Duplikate)
- [ ] Standard #3: Dateiname spezifisch (keine generischen Namen)
- [ ] Standard #8: Architektur-Layer korrekt (NO MVC)
- [ ] **Regression: Alte Tests in src-old/ identifiziert**
- [ ] **Regression: Erwartetes Verhalten dokumentiert**

### During Implementation  
- [ ] Standard #1: BBC English (comments, docstrings, errors)
- [ ] Standard #4: Single Responsibility (eine Funktion = ein Job)
- [ ] Standard #6: No Swiss Army (keine Multi-Purpose Functions)
- [ ] Standard #7: Spezifische Namen (Funktionen, Variablen, Structs)
- [ ] **Regression: Tests von src-old/ nach src/ adaptiert**
- [ ] **Regression: Outputs mit src-old/ verglichen**

### Post-Implementation
- [ ] Standard #2: Line count <400 (wc -l file.rs)
- [ ] Standard #5: Tests in separate _test.rs file
- [ ] Standard #0: Keine Duplikate erstellt (verify nochmal)
- [ ] **Regression: Alle alten Tests grün (cargo test)**
- [ ] **Regression: Behaviour identisch zu src-old/**

### Final Verification
```bash
# CLAUDE.md compliance check
./scripts/quality-check.sh src/module/file.rs

# Regression verification
./scripts/regression-verify.sh module
# ✅ Expected: All checks PASS

# Performance check (if benchmarks exist)
cargo bench --bench module_bench
# ✅ Expected: Within 10% of src-old/ performance

# Commit with full verification
git commit -m "[CLEAN-XXX] feat(module): implement feature

✅ QS-Matrix verified (all 8 CLAUDE.md standards)
✅ Regression tests: XX/XX passing
✅ Behaviour identical to src-old/
✅ Performance: Within X% of baseline

All checks passing."
```

## Implementation Steps
[... Rest des Tickets ...]
```

---

## 🔧 Automatisierte Checks (Optional, aber empfohlen)

### Script: `scripts/quality-check.sh`

```bash
#!/usr/bin/env bash
# Quality check script for CLAUDE.md compliance

set -e

FILE=$1

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file.rs>"
    exit 1
fi

echo "🔍 Checking $FILE against CLAUDE.md standards..."

# Standard #2: File size <400 lines
LINES=$(wc -l < "$FILE")
if [ "$LINES" -gt 400 ]; then
    echo "❌ Standard #2: File has $LINES lines (limit: 400)"
    exit 1
else
    echo "✅ Standard #2: File size OK ($LINES lines)"
fi

# Standard #3: Generic names
BASENAME=$(basename "$FILE")
if [[ "$BASENAME" =~ ^(helpers|utils|common|misc|stuff)\.rs$ ]]; then
    echo "❌ Standard #3: Generic filename detected: $BASENAME"
    exit 1
else
    echo "✅ Standard #3: Filename specific"
fi

# Standard #5: No inline tests
if grep -q "#\[cfg(test)\] mod" "$FILE"; then
    echo "❌ Standard #5: Inline test module detected (use _test.rs)"
    exit 1
else
    echo "✅ Standard #5: No inline tests"
fi

# Standard #1: American English check (warnings)
AMERICAN=$(rg -i "initialize|optimize|analyze|color(?!_)|behavior" "$FILE" || true)
if [ -n "$AMERICAN" ]; then
    echo "⚠️  Standard #1: Possible American English detected:"
    echo "$AMERICAN"
    echo "(Review manually - code identifiers may be OK)"
fi

# Standard #4: Long functions
LONG_FUNCS=$(rg "^pub fn \w+" "$FILE" -A 100 | rg "^}" -c || echo "0")
if [ "$LONG_FUNCS" -gt 0 ]; then
    echo "⚠️  Standard #4: Check functions >100 lines manually"
fi

# Standard #6: Swiss Army patterns
SWISS=$(rg "pub fn (handle|process|manage)_" "$FILE" || true)
if [ -n "$SWISS" ]; then
    echo "⚠️  Standard #6: Generic function names detected (check if Swiss Army):"
    echo "$SWISS"
fi

echo ""
echo "✅ All automated checks passed!"
echo "⚠️  Manual review required for warnings"
```

---

## 📋 Checklist für Ticket-Erstellung

Wenn du ein neues Ticket erstellst:

1. ✅ Kopiere QS-Matrix in Ticket (vor Implementation Steps)
2. ✅ Passe spezifische Checks an (z.B. wenn kein Test nötig)
3. ✅ Füge Pre/During/Post-Implementation Checks hinzu
4. ✅ Verwende `quality-check.sh` Script im Final Verification
5. ✅ Dokumentiere erwartete Findings (Line count, function count, etc.)

---

## 🎯 Kontinuierliche Qualität = Jedes Ticket erfüllt ALLE Standards

**Resultat**: 
- Nach jedem Ticket: 100% CLAUDE.md compliant code
- Keine "nachträgliche QS" nötig
- Keine "Technical Debt" akkumuliert
- v0.2.0-beta Launch: Perfekter Code von Tag 1

---

**Verwendung**: Dieses Template ist Pflicht für alle Clean Room Rebuild Tickets (010-999).
