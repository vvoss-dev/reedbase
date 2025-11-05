# Cargo Workspace Cheatsheet

**WICHTIG**: ReedBase verwendet Cargo Workspace mit 2 Packages.

---

## 📂 Struktur

```
reedbase/
├── Cargo.toml              [workspace]
├── current/                ← NEUER Code (deine Arbeit)
│   ├── Cargo.toml          [package] name = "reedbase"
│   └── src/
└── last/                   ← ALTER Code (Referenz, Tests)
    ├── Cargo.toml          [package] name = "reedbase-last"
    └── src/
```

---

## ⚙️ Cargo Commands (WICHTIG!)

### Build

```bash
# ❌ FALSCH - Baut beide Packages (langsam)
cargo build

# ✅ RICHTIG - Baut nur current/ (schnell)
cargo build -p reedbase

# Oder explizit beide
cargo build --all
```

### Test

```bash
# ❌ FALSCH - Testet beide Packages (verwirrend)
cargo test

# ✅ RICHTIG - Teste nur current/ (neue Tests)
cargo test -p reedbase

# ✅ RICHTIG - Teste nur last/ (Baseline check)
cargo test -p reedbase-last

# ✅ RICHTIG - Teste spezifisches Modul in current/
cargo test -p reedbase --lib core

# ✅ RICHTIG - Teste spezifischen Test in current/
cargo test -p reedbase --lib core::tests::test_db_dir
```

### Clippy

```bash
# current/ nur
cargo clippy -p reedbase

# Beide
cargo clippy --all
```

### Bench

```bash
# current/ Benchmarks
cargo bench -p reedbase --bench module_bench

# Comparison Benchmark (current vs last)
cargo bench --bench comparison
```

### Check

```bash
# Schnellster Check für current/
cargo check -p reedbase

# Mit Warnings
cargo clippy -p reedbase -- -D warnings
```

---

## 📝 Pfade in Kommandos

### Quality Check

```bash
# ✅ RICHTIG - Mit current/ prefix
./scripts/quality-check.sh current/src/core/paths.rs

# ❌ FALSCH - Ohne workspace
./scripts/quality-check.sh src/core/paths.rs
```

### Regression Verify

```bash
# ✅ RICHTIG - Script weiß über current/ und last/
./scripts/regression-verify.sh core

# Script intern:
# - Vergleicht current/src/core mit last/src/core
# - Läuft cargo test -p reedbase --lib core
# - Läuft cargo test -p reedbase-last --lib core
```

### File Operations

```bash
# ✅ RICHTIG - Mit current/ prefix
wc -l current/src/core/paths.rs

# ✅ RICHTIG - Mit last/ prefix für Vergleich
wc -l last/src/core/paths.rs

# ❌ FALSCH - src/ existiert nicht (ist in current/ oder last/)
wc -l src/core/paths.rs
```

### Grep / Ripgrep

```bash
# ✅ RICHTIG - Suche in current/
rg "pub fn" current/src/core/

# ✅ RICHTIG - Suche in last/ (Referenz)
rg "pub fn" last/src/core/

# ✅ Beide durchsuchen
rg "pub fn" current/src/ last/src/
```

---

## 🎯 In Tickets verwenden

### Pre-Implementation

```bash
# Alte Tests finden
find last/src/module -name "*_test.rs"

# Alte Implementation analysieren
rg "pub fn function_name" last/src/module/
```

### During Implementation

```bash
# In current/ arbeiten
cd current/

# Neue Funktion schreiben
vim src/module/file.rs

# Test schreiben
vim src/module/file_test.rs

# Schnell testen
cargo test -p reedbase --lib module::tests::test_name
```

### Post-Implementation

```bash
# current/ Quality Check
./scripts/quality-check.sh current/src/module/file.rs

# Line count
wc -l current/src/module/file.rs

# Regression Check
./scripts/regression-verify.sh module
# → Vergleicht automatisch current/ mit last/

# Baseline noch grün?
cargo test -p reedbase-last --lib module
# ✅ Expected: Still passing

# Neue Tests grün?
cargo test -p reedbase --lib module
# ✅ Expected: All passing
```

### Commit

```bash
git add current/src/module/

git commit -m "[CLEAN-XXX] feat(module): implement feature

✅ QS-Matrix verified
✅ Regression tests: XX/XX passing (current/ vs last/)
✅ Behaviour identical to last/

Workspace:
- cargo test -p reedbase: All tests passing
- cargo test -p reedbase-last: Baseline still green"
```

---

## 🚨 Häufige Fehler

### Fehler 1: Falscher Package Name

```bash
# ❌ FALSCH
cargo test -p reedbase-current
# Error: package 'reedbase-current' not found

# ✅ RICHTIG
cargo test -p reedbase
# (Package heißt "reedbase", nicht "reedbase-current")
```

### Fehler 2: Workspace Root bauen

```bash
# ❌ FALSCH - Im root laufen lassen
cd reedbase/
cargo test
# → Testet BEIDE Packages (verwirrend!)

# ✅ RICHTIG - Package spezifizieren
cargo test -p reedbase
```

### Fehler 3: Pfade ohne Workspace

```bash
# ❌ FALSCH
./scripts/quality-check.sh src/core/paths.rs
# Error: src/core/paths.rs: No such file or directory

# ✅ RICHTIG
./scripts/quality-check.sh current/src/core/paths.rs
```

### Fehler 4: In falsches Verzeichnis wechseln

```bash
# ⚠️ VERMEIDEN - In Package-Verzeichnis wechseln
cd current/
cargo test
# → Funktioniert, aber verliert Workspace-Kontext

# ✅ BESSER - Im root bleiben
cd reedbase/
cargo test -p reedbase
```

---

## 📋 Quick Reference

| Aktion | Kommando |
|--------|----------|
| **Build current** | `cargo build -p reedbase` |
| **Test current** | `cargo test -p reedbase` |
| **Test last** | `cargo test -p reedbase-last` |
| **Check current** | `cargo check -p reedbase` |
| **Clippy current** | `cargo clippy -p reedbase` |
| **Quality check** | `./scripts/quality-check.sh current/src/module/file.rs` |
| **Regression** | `./scripts/regression-verify.sh module` |
| **Bench current** | `cargo bench -p reedbase --bench name` |
| **Line count** | `wc -l current/src/module/file.rs` |
| **Find tests** | `find last/src/module -name "*_test.rs"` |
| **Search code** | `rg "pattern" current/src/` |

---

## 💡 Tipps

### Tip 1: Shell Alias für schnellere Entwicklung

```bash
# In ~/.bashrc oder ~/.zshrc
alias ct="cargo test -p reedbase"
alias cb="cargo build -p reedbase"
alias cc="cargo check -p reedbase"
alias cl="cargo clippy -p reedbase"

# Dann einfach:
ct --lib core
```

### Tip 2: Watch Mode für current/

```bash
# Auto-rebuild bei Änderungen
cargo watch -p reedbase -x "test --lib core"

# Mit clear screen
cargo watch -c -p reedbase -x test
```

### Tip 3: Schneller Feedback Loop

```bash
# 1. Datei editieren
vim current/src/core/paths.rs

# 2. Schnell checken (nur compile, kein link)
cargo check -p reedbase

# 3. Wenn OK, Tests
cargo test -p reedbase --lib core::tests::test_db_dir

# 4. Wenn OK, Quality Check
./scripts/quality-check.sh current/src/core/paths.rs
```

### Tip 4: Vergleich alt vs neu

```bash
# Funktionen vergleichen
diff <(rg "^pub fn" last/src/core/ | sort) \
     <(rg "^pub fn" current/src/core/ | sort)

# Line counts vergleichen
wc -l last/src/core/*.rs current/src/core/*.rs
```

---

## 🎯 Template für Tickets

**Kopiere das in jedes Ticket**:

```markdown
## Workspace Commands

```bash
# Development (während Implementierung)
cargo check -p reedbase          # Schneller Compile Check
cargo test -p reedbase --lib module   # Modul testen

# Verification (vor Commit)
./scripts/quality-check.sh current/src/module/file.rs
./scripts/regression-verify.sh module
cargo test -p reedbase-last --lib module  # Baseline check
cargo test -p reedbase --lib module       # New tests

# Commit
git add current/src/module/
git commit -m "[CLEAN-XXX] ..."
```
```

---

**Verwende dieses Cheatsheet in jedem Ticket!**
