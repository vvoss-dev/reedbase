# REED-CLEAN-080-01: Binary & CLI (Complete CLI Interface)

**Created**: 2025-11-06  
**Phase**: 8 (Binary & CLI)  
**Estimated Effort**: 6-10 hours  
**Dependencies**: All previous phases (1-7)  
**Blocks**: None (Phase 9 is final verification)

---

## Status

- [ ] Ticket understood
- [ ] Pre-implementation analysis complete
- [ ] Implementation complete
- [ ] Tests passing (integration tests)
- [ ] Quality standards verified (all 8)
- [ ] Regression tests passing
- [ ] Documentation complete
- [ ] Committed

---

## 🚨 GOLDEN RULE: "last ist die vorgabe"

**MANDATORY**: Before writing ANY code, perform complete analysis of `last/src/bin/`.

### Pre-Implementation Analysis

**Verification Date**: ________________ (MUST be filled before implementation!)

**Analysis Checklist**:
- [ ] All files in `last/src/bin/` read and understood
- [ ] All CLI commands enumerated below
- [ ] All formatters enumerated below
- [ ] All dependencies (clap, anyhow) documented
- [ ] Behaviour parity strategy confirmed

---

### Files in this ticket

```
last/src/bin/reedbase.rs              201 lines  → current/src/bin/reedbase.rs
last/src/bin/commands/mod.rs           12 lines  → current/src/bin/commands/mod.rs
last/src/bin/commands/query.rs         45 lines  → current/src/bin/commands/query.rs
last/src/bin/commands/exec.rs          31 lines  → current/src/bin/commands/exec.rs
last/src/bin/commands/shell.rs        192 lines  → current/src/bin/commands/shell.rs
last/src/bin/commands/tables.rs        60 lines  → current/src/bin/commands/tables.rs
last/src/bin/commands/indices.rs       75 lines  → current/src/bin/commands/indices.rs
last/src/bin/commands/stats.rs         48 lines  → current/src/bin/commands/stats.rs
last/src/bin/commands/explain.rs       34 lines  → current/src/bin/commands/explain.rs
last/src/bin/formatters/mod.rs        177 lines  → current/src/bin/formatters/mod.rs

Total: 875 lines → ~900 lines
```

**File Size Analysis**:
- ✅ reedbase.rs: 201 lines (< 400, no split needed)
- ✅ shell.rs: 192 lines (< 400, no split needed)
- ✅ formatters/mod.rs: 177 lines (< 400, no split needed)
- ✅ All other files: < 100 lines each

**Result**: All files under 400 lines - NO splits required ✅

---

### CLI Commands (7 total)

1. **`query`** - Execute SELECT query
   - Arguments: sql, path, format (table/json/csv), output, no_header
   - Uses Database::query()
   - Formatters: table, json, csv
   - Can write to file or stdout

2. **`exec`** - Execute INSERT/UPDATE/DELETE
   - Arguments: sql, path, user, quiet
   - Uses Database::execute()
   - Prints affected rows and execution time
   - Audit trail with username

3. **`shell`** - Interactive shell (REPL)
   - Arguments: path, user
   - Readline support
   - Command history
   - Supports query and exec commands
   - Exit with `.exit` or Ctrl+D

4. **`tables`** - List/manage tables
   - Arguments: path, create, drop, confirm, verbose
   - List all tables with row counts
   - Create new table
   - Drop table (requires --confirm)
   - Verbose mode shows statistics

5. **`indices`** - List/manage indices
   - Arguments: path, create, drop, rebuild, verbose
   - List all indices with types
   - Create index on table.column
   - Drop index
   - Rebuild index
   - Verbose mode shows statistics

6. **`stats`** - Show database statistics
   - Arguments: path, format (table/json)
   - Database-wide statistics
   - Table statistics
   - Index statistics

7. **`explain`** - Explain query execution plan
   - Arguments: sql, path, verbose
   - Shows query plan
   - Index usage
   - Estimated cost

---

### Formatters (3 total)

1. **`format_table(result: &QueryResult) -> String`**
   - Human-readable ASCII table with borders
   - Auto-sized columns
   - Shows row count
   - Example:
     ```
     +------+-----+
     | name | age |
     +------+-----+
     | Alice| 30  |
     | Bob  | 25  |
     +------+-----+
     2 rows
     ```

2. **`format_json(result: &QueryResult) -> String`**
   - JSON array of objects
   - Escaped quotes
   - Pretty-printed
   - Example:
     ```json
     [
       {"name": "Alice", "age": "30"},
       {"name": "Bob", "age": "25"}
     ]
     ```

3. **`format_csv(result: &QueryResult, include_header: bool) -> String`**
   - Comma-separated values
   - Optional header row
   - Escaped commas and quotes
   - Example:
     ```csv
     name,age
     Alice,30
     Bob,25
     ```

---

### Dependencies

**External crates** (add to Cargo.toml):
```toml
[dependencies]
clap = { version = "4.4", features = ["derive"] }
anyhow = "1.0"
rustyline = "13.0"  # For shell/REPL
```

**Internal modules**:
- `reedbase::Database` - Main database API
- `reedbase::reedql::QueryResult` - Query result type

---

### Verification Commands

**Before implementation** (analyse last/):
```bash
# Count lines per file
wc -l last/src/bin/**/*.rs last/src/bin/*.rs

# Check CLI structure
cat last/src/bin/reedbase.rs | head -50

# Check commands
ls -la last/src/bin/commands/
```

**During implementation** (build current/):
```bash
# Compile binary
cargo build --release -p reedbase

# Test CLI
./target/release/reedbase --help
./target/release/reedbase query --help
```

**After implementation** (verify parity):
```bash
# Test query command
./target/release/reedbase query "SELECT * FROM text" .reed

# Test exec command
./target/release/reedbase exec "INSERT INTO text VALUES ('test', 'data')" .reed --user test

# Test shell
./target/release/reedbase shell .reed

# No clippy warnings
cargo clippy -p reedbase --bin reedbase -- -D warnings
```

---

### Bestätigung (Confirmation)

**I hereby confirm**:
- ✅ I have read ALL files in `last/src/bin/`
- ✅ I understand the CLI structure (clap derive API)
- ✅ I understand all 7 commands and their arguments
- ✅ I understand the 3 formatters (table/json/csv)
- ✅ I understand the shell/REPL implementation
- ✅ I will achieve 100% behaviour parity with last/
- ✅ I will NOT add features, optimisations, or "improvements"
- ✅ I will maintain ALL existing command arguments exactly
- ✅ This is the ONLY layer where Display/println! is allowed

**Signature**: ________________ **Date**: ________________

---

## Context & Scope

### What is this module?

The **bin module** provides the command-line interface for ReedBase. It wraps the library API in a user-friendly CLI with subcommands, formatters, and an interactive shell.

**Key characteristics**:
- **clap-based**: Uses clap derive API for argument parsing
- **User-friendly**: Human-readable output formats
- **Interactive**: REPL shell with history
- **Flexible**: Multiple output formats (table/json/csv)
- **Safe**: Requires --confirm for destructive operations

### Why this module?

1. **Usability**: Makes ReedBase accessible without writing code
2. **Testing**: Quick way to test database operations
3. **Scripting**: Can be used in shell scripts (CSV output)
4. **Debugging**: Interactive shell for exploration
5. **Production**: Production-ready CLI tool

### Architecture Context

**Position in architecture**:
```
bin/                ← THIS MODULE (CLI layer)
  ├── reedbase.rs   (main entry point)
  ├── commands/     (command implementations)
  └── formatters/   (output formatting)

Uses ALL library layers:
  ├── api/          (Database API)
  ├── ops/          (backup, versioning, metrics, log, merge)
  ├── process/      (concurrent)
  ├── validate/     (schema, rbks)
  ├── store/        (btree, tables, indices)
  └── core/         (paths, validation)
```

**IMPORTANT**: This is the **ONLY layer** where:
- ✅ `Display` traits are allowed
- ✅ `println!`, `eprintln!` are allowed
- ✅ User-facing formatting is allowed

All other layers must return structured data.

---

## Implementation Steps

### Step 1: Add Dependencies to Cargo.toml

**Update `current/Cargo.toml`**:
```toml
[dependencies]
clap = { version = "4.4", features = ["derive"] }
anyhow = "1.0"
rustyline = "13.0"

[[bin]]
name = "reedbase"
path = "src/bin/reedbase.rs"
```

Verify versions match `last/Cargo.toml`.

---

### Step 2: Create Binary Entry Point (reedbase.rs)

**Reference**: `last/src/bin/reedbase.rs` (201 lines)

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! ReedBase CLI Tool (ReedQL Command)
//!
//! Command-line interface for ReedBase operations.

use clap::{Parser, Subcommand};
use std::path::PathBuf;

mod commands;
mod formatters;

use commands::{exec, explain, indices, query, shell, stats, tables};

#[derive(Parser)]
#[command(name = "reedbase")]
#[command(author = "Vivian Voss <ask@vvoss.dev>")]
#[command(version = "0.2.0-beta")]
#[command(about = "ReedBase CLI - SQL-like database operations", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Execute a SELECT query
    Query {
        /// ReedQL SELECT query (quoted)
        sql: String,

        /// Path to ReedBase directory (e.g., .reed)
        path: PathBuf,

        /// Output format: table|json|csv
        #[arg(short, long, default_value = "table")]
        format: String,

        /// Write output to file
        #[arg(short, long)]
        output: Option<PathBuf>,

        /// Omit header row (CSV only)
        #[arg(long)]
        no_header: bool,
    },

    /// Execute INSERT/UPDATE/DELETE command
    Exec {
        /// ReedQL command (quoted)
        sql: String,

        /// Path to ReedBase directory
        path: PathBuf,

        /// Username for audit trail
        #[arg(short, long)]
        user: Option<String>,

        /// Don't print affected rows
        #[arg(short, long)]
        quiet: bool,
    },

    /// Open interactive shell
    Shell {
        /// Path to ReedBase directory
        path: PathBuf,

        /// Default username for exec commands
        #[arg(short, long)]
        user: Option<String>,
    },

    /// List or manage tables
    Tables {
        /// Path to ReedBase directory
        path: PathBuf,

        /// Create new table
        #[arg(short, long)]
        create: Option<String>,

        /// Drop table (requires --confirm)
        #[arg(short, long)]
        drop: Option<String>,

        /// Confirm destructive operation
        #[arg(long)]
        confirm: bool,

        /// Show table statistics
        #[arg(short, long)]
        verbose: bool,
    },

    /// List or manage indices
    Indices {
        /// Path to ReedBase directory
        path: PathBuf,

        /// Create index on table.column
        #[arg(short, long)]
        create: Option<String>,

        /// Drop index
        #[arg(short, long)]
        drop: Option<String>,

        /// Rebuild index
        #[arg(short, long)]
        rebuild: Option<String>,

        /// Show index statistics
        #[arg(short, long)]
        verbose: bool,
    },

    /// Show database statistics
    Stats {
        /// Path to ReedBase directory
        path: PathBuf,

        /// Output format: table|json
        #[arg(short, long, default_value = "table")]
        format: String,
    },

    /// Explain query execution plan
    Explain {
        /// ReedQL query (quoted)
        sql: String,

        /// Path to ReedBase directory
        path: PathBuf,

        /// Show detailed plan
        #[arg(short, long)]
        verbose: bool,
    },
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Query {
            sql,
            path,
            format,
            output,
            no_header,
        } => query::execute(&sql, &path, &format, output.as_deref(), no_header)?,

        Commands::Exec {
            sql,
            path,
            user,
            quiet,
        } => {
            let username = user
                .unwrap_or_else(|| std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()));
            exec::execute(&sql, &path, &username, quiet)?;
        }

        Commands::Shell { path, user } => {
            let username = user
                .unwrap_or_else(|| std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()));
            shell::run(&path, &username)?;
        }

        Commands::Tables {
            path,
            create,
            drop,
            confirm,
            verbose,
        } => tables::execute(&path, create.as_deref(), drop.as_deref(), confirm, verbose)?,

        Commands::Indices {
            path,
            create,
            drop,
            rebuild,
            verbose,
        } => indices::execute(
            &path,
            create.as_deref(),
            drop.as_deref(),
            rebuild.as_deref(),
            verbose,
        )?,

        Commands::Stats { path, format } => stats::execute(&path, &format)?,

        Commands::Explain { sql, path, verbose } => explain::execute(&sql, &path, verbose)?,
    }

    Ok(())
}
```

**Critical behaviours**:
- clap derive API (Parser, Subcommand)
- Default user from $USER environment variable
- Error handling with anyhow::Result
- Version number matches package version

---

### Step 3: Implement Query Command (commands/query.rs)

**Reference**: `last/src/bin/commands/query.rs` (45 lines)

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Query command implementation.

use anyhow::{Context, Result};
use reedbase::Database;
use std::path::Path;

use crate::formatters;

pub fn execute(
    sql: &str,
    path: &Path,
    format: &str,
    output: Option<&Path>,
    no_header: bool,
) -> Result<()> {
    // Open database
    let db = Database::open(path)
        .with_context(|| format!("Failed to open database at {}", path.display()))?;

    // Execute query
    let result = db
        .query(sql)
        .with_context(|| format!("Query failed: {}", sql))?;

    // Format output
    let output_str = match format {
        "json" => formatters::format_json(&result),
        "csv" => formatters::format_csv(&result, !no_header),
        _ => formatters::format_table(&result),
    };

    // Write to file or stdout
    if let Some(output_path) = output {
        std::fs::write(output_path, &output_str)
            .with_context(|| format!("Failed to write to {}", output_path.display()))?;
        println!("Output written to {}", output_path.display());
    } else {
        print!("{}", output_str);
    }

    Ok(())
}
```

---

### Step 4: Implement Exec Command (commands/exec.rs)

**Reference**: `last/src/bin/commands/exec.rs` (31 lines)

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Exec command implementation.

use anyhow::{Context, Result};
use reedbase::Database;
use std::path::Path;

pub fn execute(sql: &str, path: &Path, user: &str, quiet: bool) -> Result<()> {
    // Open database
    let db = Database::open(path)
        .with_context(|| format!("Failed to open database at {}", path.display()))?;

    // Execute command
    let result = db
        .execute(sql, user)
        .with_context(|| format!("Command failed: {}", sql))?;

    // Print result
    if !quiet {
        println!(
            "{} row{} affected ({:.2}ms)",
            result.rows_affected,
            if result.rows_affected == 1 { "" } else { "s" },
            result.execution_time_us as f64 / 1000.0
        );
    }

    Ok(())
}
```

---

### Step 5: Implement Shell/REPL (commands/shell.rs)

**Reference**: `last/src/bin/commands/shell.rs` (192 lines)

**Key features**:
- rustyline for readline support
- Command history
- `.exit` to quit
- Handles both query and exec commands
- Error handling without exit

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Interactive shell command implementation.

use anyhow::{Context, Result};
use reedbase::Database;
use rustyline::error::ReadlineError;
use rustyline::DefaultEditor;
use std::path::Path;

use crate::formatters;

pub fn run(path: &Path, user: &str) -> Result<()> {
    // Open database
    let db = Database::open(path)
        .with_context(|| format!("Failed to open database at {}", path.display()))?;

    // Create readline editor
    let mut rl = DefaultEditor::new()
        .with_context(|| "Failed to initialise readline")?;

    println!("ReedBase Shell v0.2.0-beta");
    println!("Type '.exit' to quit");
    println!();

    loop {
        let readline = rl.readline("reedbase> ");

        match readline {
            Ok(line) => {
                if line.trim().is_empty() {
                    continue;
                }

                // Add to history
                let _ = rl.add_history_entry(&line);

                // Check for special commands
                if line.trim() == ".exit" {
                    break;
                }

                // Determine if query or exec
                let sql = line.trim();
                if sql.to_uppercase().starts_with("SELECT") {
                    // Query command
                    match db.query(sql) {
                        Ok(result) => {
                            print!("{}", formatters::format_table(&result));
                        }
                        Err(e) => {
                            eprintln!("Error: {}", e);
                        }
                    }
                } else {
                    // Exec command
                    match db.execute(sql, user) {
                        Ok(result) => {
                            println!(
                                "{} row{} affected ({:.2}ms)",
                                result.rows_affected,
                                if result.rows_affected == 1 { "" } else { "s" },
                                result.execution_time_us as f64 / 1000.0
                            );
                        }
                        Err(e) => {
                            eprintln!("Error: {}", e);
                        }
                    }
                }
            }

            Err(ReadlineError::Interrupted) => {
                // Ctrl+C
                println!("^C");
                continue;
            }

            Err(ReadlineError::Eof) => {
                // Ctrl+D
                break;
            }

            Err(err) => {
                eprintln!("Error: {:?}", err);
                break;
            }
        }
    }

    Ok(())
}
```

---

### Step 6: Implement Remaining Commands

**Create these files** (see last/src/bin/commands/ for full implementations):

- `commands/tables.rs` (60 lines) - List/create/drop tables
- `commands/indices.rs` (75 lines) - List/create/drop/rebuild indices
- `commands/stats.rs` (48 lines) - Show database statistics
- `commands/explain.rs` (34 lines) - Explain query plan

**All follow same pattern**:
1. Open database with context
2. Call database API
3. Format and print output
4. Error handling with anyhow

---

### Step 7: Implement Formatters (formatters/mod.rs)

**Reference**: `last/src/bin/formatters/mod.rs` (177 lines)

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Output formatters for query results.

use reedbase::reedql::QueryResult;

/// Formats result as human-readable table.
pub fn format_table(result: &QueryResult) -> String {
    match result {
        QueryResult::Rows(rows) => {
            if rows.is_empty() {
                return "0 rows\n".to_string();
            }

            // Get column names (from first row)
            let mut columns: Vec<String> = rows[0].keys().cloned().collect();
            columns.sort();

            // Calculate column widths
            let mut widths: std::collections::HashMap<String, usize> =
                columns.iter().map(|c| (c.clone(), c.len())).collect();

            for row in rows {
                for col in &columns {
                    if let Some(value) = row.get(col) {
                        let current = widths.get(col).copied().unwrap_or(0);
                        widths.insert(col.clone(), current.max(value.len()));
                    }
                }
            }

            // Build table (see last/src/bin/formatters/mod.rs for full implementation)
            // ... borders, header, separator, rows ...

            output
        }

        QueryResult::Aggregation(value) => {
            format!("{}\n", value)
        }
    }
}

/// Formats result as JSON.
pub fn format_json(result: &QueryResult) -> String {
    match result {
        QueryResult::Rows(rows) => {
            // JSON array of objects
            // ... (see last/src/bin/formatters/mod.rs)
        }
        QueryResult::Aggregation(value) => {
            format!("{}\n", value)
        }
    }
}

/// Formats result as CSV.
pub fn format_csv(result: &QueryResult, include_header: bool) -> String {
    match result {
        QueryResult::Rows(rows) => {
            // CSV with optional header
            // Escape commas and quotes
            // ... (see last/src/bin/formatters/mod.rs)
        }
        QueryResult::Aggregation(value) => {
            format!("{}\n", value)
        }
    }
}
```

**Critical behaviours**:
- format_table: Auto-sized columns, ASCII borders
- format_json: Escaped quotes, pretty-printed
- format_csv: Escaped commas/quotes, optional header

---

### Step 8: Create Commands Module Root

**Create `commands/mod.rs`**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! CLI command implementations.

pub mod exec;
pub mod explain;
pub mod indices;
pub mod query;
pub mod shell;
pub mod stats;
pub mod tables;
```

---

### Step 9: Build and Test

```bash
# Build binary
cargo build --release -p reedbase

# Test help
./target/release/reedbase --help
./target/release/reedbase query --help

# Test commands (requires test database)
./target/release/reedbase query "SELECT * FROM text" .reed
./target/release/reedbase exec "INSERT INTO text VALUES ('test', 'data')" .reed --user test
./target/release/reedbase shell .reed

# Check binary size
ls -lh target/release/reedbase
```

---

### Step 10: Verify Behaviour Parity

**Manual testing**:

1. **Query command with different formats**:
   ```bash
   reedbase query "SELECT * FROM text" .reed --format table
   reedbase query "SELECT * FROM text" .reed --format json
   reedbase query "SELECT * FROM text" .reed --format csv --no-header
   ```

2. **Exec command**:
   ```bash
   reedbase exec "INSERT INTO text VALUES ('key1', 'value1')" .reed --user test
   ```

3. **Shell/REPL**:
   ```bash
   reedbase shell .reed
   > SELECT * FROM text
   > INSERT INTO text VALUES ('key2', 'value2')
   > .exit
   ```

4. **Tables command**:
   ```bash
   reedbase tables .reed
   reedbase tables .reed --verbose
   ```

5. **Output to file**:
   ```bash
   reedbase query "SELECT * FROM text" .reed --output result.csv --format csv
   cat result.csv
   ```

---

## Quality Standards (8 Total)

### Standard #0: Code Reuse ✅
- [x] No duplicate formatters (3 distinct formatters)
- [x] Using clap for argument parsing (no custom parser)
- [x] Using rustyline for shell (no custom readline)
- [x] Using anyhow for error handling (no custom error types)

**Why compliant**: Uses standard crates, each command is focused.

---

### Standard #1: BBC English ✅
- [x] All comments use British spelling
- [x] "initialise" not "initialize"
- [x] "optimise" not "optimize"

**Examples**:
```rust
/// Initialises the shell.  ✅
// not: "Initializes the shell"
```

---

### Standard #2: KISS - Files <400 Lines ✅
- [x] reedbase.rs: 201 lines (< 400) ✅
- [x] shell.rs: 192 lines (< 400) ✅
- [x] formatters/mod.rs: 177 lines (< 400) ✅
- [x] All other files: < 100 lines each

**Verification**:
```bash
wc -l current/src/bin/**/*.rs current/src/bin/*.rs
# All files must be < 400 lines
```

---

### Standard #3: Specific File Naming ✅
- [x] query.rs (query command) ✅
- [x] exec.rs (exec command) ✅
- [x] shell.rs (shell/REPL) ✅
- [x] tables.rs (tables command) ✅
- [x] formatters/mod.rs (output formatters) ✅

**NOT**:
- ❌ commands.rs (too generic)
- ❌ utils.rs
- ❌ helpers.rs

---

### Standard #4: One Function = One Job ✅
- [x] `format_table()` - ONLY formats as table
- [x] `format_json()` - ONLY formats as JSON
- [x] `format_csv()` - ONLY formats as CSV
- [x] Each command = one execute() function
- [x] No boolean flags (format string instead)

---

### Standard #5: Separate Test Files ✅
- [x] Integration tests in tests/ directory (not inline)
- [x] No #[cfg(test)] modules in bin/

**Note**: CLI is primarily tested via integration tests, not unit tests.

---

### Standard #6: No Swiss Army Functions ✅
- [x] No `handle_command()` doing many things
- [x] Each command has its own execute() function
- [x] Formatters are separate functions (not one with mode flag)

---

### Standard #7: No Generic Names ✅
- [x] `format_table()` not `format()` (context: table)
- [x] `execute()` in each command file (local context clear)
- [x] `query::execute()`, `exec::execute()` (module namespaced)

---

### Standard #8: Architecture - This is the CLI Layer ✅
- [x] This is the ONLY layer where Display/println! is allowed
- [x] Wraps library API (doesn't implement logic)
- [x] No business logic in CLI (all in library)
- [x] Pure presentation layer

**Why compliant**: CLI is presentation layer, library is logic layer.

---

## Testing Requirements

### Integration Tests

**CLI integration tests** (in `current/tests/cli_test.rs`):
```rust
#[test]
fn test_cli_query_command() {
    // Setup test database
    // Run: reedbase query "SELECT * FROM test" /tmp/test
    // Verify output format
}

#[test]
fn test_cli_exec_command() {
    // Setup test database
    // Run: reedbase exec "INSERT INTO test VALUES (...)" /tmp/test
    // Verify rows affected
}

#[test]
fn test_cli_output_formats() {
    // Test --format table
    // Test --format json
    // Test --format csv
    // Verify each format
}
```

### Manual Testing Checklist

- [ ] `reedbase --help` shows all commands
- [ ] `reedbase query --help` shows query options
- [ ] Query with table format works
- [ ] Query with json format works
- [ ] Query with csv format works
- [ ] Query with --output writes to file
- [ ] Exec command affects rows
- [ ] Exec command prints execution time
- [ ] Shell starts and accepts commands
- [ ] Shell history works (up arrow)
- [ ] Shell exits with .exit
- [ ] Tables command lists tables
- [ ] Indices command lists indices
- [ ] Stats command shows statistics
- [ ] Explain command shows query plan

---

## Success Criteria

### Functional Requirements ✅
- [x] All 7 commands implemented (query, exec, shell, tables, indices, stats, explain)
- [x] All 3 formatters implemented (table, json, csv)
- [x] clap-based argument parsing
- [x] rustyline-based shell/REPL
- [x] anyhow-based error handling
- [x] Output to file or stdout
- [x] User from $USER environment variable

### Quality Requirements ✅
- [x] All files < 400 lines (Standard #2)
- [x] BBC English throughout (Standard #1)
- [x] Specific file names (Standard #3)
- [x] One function = one job (Standard #4)
- [x] Separate test files (Standard #5)
- [x] No Swiss Army functions (Standard #6)
- [x] No generic names (Standard #7)
- [x] Proper layering (Standard #8)
- [x] No code duplication (Standard #0)

### Regression Requirements ✅
- [x] All commands from last/ implemented
- [x] Behaviour parity with last/src/bin/
- [x] Identical output formats
- [x] Identical argument handling
- [x] Identical error messages

### Documentation Requirements ✅
- [x] Help text for all commands
- [x] Examples in --help
- [x] README with CLI usage
- [x] Man page (optional)

---

## Commit Message

```
[CLEAN-080-01] feat(bin): implement complete CLI interface

✅ QS-Matrix verified (all 8 CLAUDE.md standards)
✅ Integration tests: All commands tested
✅ Behaviour identical to last/src/bin/

Implemented complete command-line interface:

Main Entry (reedbase.rs, 201 lines):
- clap derive API for argument parsing
- 7 subcommands with full argument support
- Default user from $USER environment
- anyhow error handling

Commands (commands/, 497 lines total):
- query: Execute SELECT with format options (table/json/csv)
- exec: Execute INSERT/UPDATE/DELETE with audit trail
- shell: Interactive REPL with rustyline
- tables: List/create/drop tables
- indices: List/create/drop/rebuild indices
- stats: Show database statistics
- explain: Show query execution plan

Formatters (formatters/mod.rs, 177 lines):
- format_table(): ASCII table with borders and auto-sizing
- format_json(): Pretty-printed JSON array
- format_csv(): RFC 4180 compliant CSV with escaping

CLI Features:
- Multiple output formats (table/json/csv)
- Output to file or stdout
- Interactive shell with command history
- Safety: --confirm required for destructive operations
- Verbose mode for detailed statistics
- User audit trail with username

Example Usage:
$ reedbase query "SELECT * FROM text" .reed --format json
$ reedbase exec "INSERT INTO text VALUES ('k', 'v')" .reed --user admin
$ reedbase shell .reed
reedbase> SELECT * FROM text
reedbase> .exit

Quality Standards:
✅ #0: No duplicate code (uses clap/rustyline/anyhow)
✅ #1: BBC English throughout ("initialise")
✅ #2: All files <400 lines (largest: reedbase.rs 201)
✅ #3: Specific naming (query, exec, shell, formatters)
✅ #4: One function = one job (separate formatters)
✅ #5: Integration tests in tests/ (not inline)
✅ #6: No Swiss Army functions (each command separate)
✅ #7: Contextual names (format_table, format_json)
✅ #8: Proper layering (CLI wraps library, no logic)

Workspace packages:
- reedbase (current): CLI complete
- reedbase-last (last): Baseline still working

Dependencies:
- clap 4.4 (derive API)
- anyhow 1.0 (error handling)
- rustyline 13.0 (interactive shell)

Files:
- current/src/bin/reedbase.rs (201 lines)
- current/src/bin/commands/mod.rs (12 lines)
- current/src/bin/commands/query.rs (45 lines)
- current/src/bin/commands/exec.rs (31 lines)
- current/src/bin/commands/shell.rs (192 lines)
- current/src/bin/commands/tables.rs (60 lines)
- current/src/bin/commands/indices.rs (75 lines)
- current/src/bin/commands/stats.rs (48 lines)
- current/src/bin/commands/explain.rs (34 lines)
- current/src/bin/formatters/mod.rs (177 lines)
```

---

## Notes

### Key Implementation Details

1. **clap Derive API**:
   - Use #[derive(Parser, Subcommand)]
   - Automatic --help generation
   - Type-safe argument parsing

2. **Error Handling**:
   - anyhow::Result for all functions
   - .with_context() for error context
   - User-friendly error messages

3. **Shell/REPL**:
   - rustyline for readline support
   - Command history with up/down arrows
   - .exit to quit
   - Distinguish SELECT (query) vs other (exec)

4. **Formatters**:
   - Auto-sized columns for table format
   - Escaped quotes for JSON
   - Escaped commas/quotes for CSV
   - Optional header for CSV

5. **User Defaults**:
   - $USER environment variable as default
   - Fallback to "unknown" if not set

### Common Pitfalls to Avoid

1. ❌ Don't inline business logic in CLI (keep in library)
2. ❌ Don't use println! in library (only in bin/)
3. ❌ Don't forget to escape CSV values (commas, quotes)
4. ❌ Don't forget --confirm for destructive operations
5. ❌ Don't break shell on error (catch and print)
6. ❌ Don't forget command history in shell

### Migration Gotchas

1. **Package name**:
   - Import: `use reedbase::Database` (not reedbase_last)
   
2. **Binary path**:
   - Old: `last/src/bin/reedbase.rs`
   - New: `current/src/bin/reedbase.rs`

3. **Cargo.toml**:
   - Must have [[bin]] section
   - Dependencies: clap, anyhow, rustyline

---

**Ticket Complete**: Ready for implementation following Clean Room Rebuild Protocol.
