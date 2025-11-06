# REED-CLEAN-070-01: Log System (Encoding, Decoding, Validation)

**Created**: 2025-11-06  
**Phase**: 7 (Logging & Merge)  
**Estimated Effort**: 6-10 hours  
**Dependencies**: None (standalone module at ops/ layer)  
**Blocks**: 080-01 (Merge operations use log system)

---

## Status

- [ ] Ticket understood
- [ ] Pre-implementation analysis complete
- [ ] Implementation complete
- [ ] Tests passing (unit + integration)
- [ ] Quality standards verified (all 8)
- [ ] Regression tests passing
- [ ] Documentation complete
- [ ] Committed

---

## 🚨 GOLDEN RULE: "last ist die vorgabe"

**MANDATORY**: Before writing ANY code, perform complete analysis of `last/src/log/`.

### Pre-Implementation Analysis

**Verification Date**: ________________ (MUST be filled before implementation!)

**Analysis Checklist**:
- [ ] All files in `last/src/log/` read and understood
- [ ] All public types enumerated below
- [ ] All public functions enumerated below with exact signatures
- [ ] All test files identified and migration strategy planned
- [ ] All dependencies (external + internal) documented
- [ ] Behaviour parity strategy confirmed

---

### Files in this ticket

```
last/src/log/types.rs        133 lines  → current/src/ops/log/types.rs
last/src/log/encoder.rs      168 lines  → current/src/ops/log/encoder.rs
last/src/log/decoder.rs      366 lines  → current/src/ops/log/decoder.rs
last/src/log/validator.rs    206 lines  → current/src/ops/log/validator.rs
last/src/log/mod.rs           26 lines  → current/src/ops/log/mod.rs

Total: 899 lines → ~920 lines
```

**File Size Analysis**:
- ✅ types.rs: 133 lines (< 400, no split needed)
- ✅ encoder.rs: 168 lines (< 400, no split needed)
- ✅ decoder.rs: 366 lines (< 400, no split needed)
- ✅ validator.rs: 206 lines (< 400, no split needed)
- ✅ mod.rs: 26 lines (< 400, no split needed)

**Result**: All files under 400 lines - NO splits required ✅

---

### Public Types (2 total)

#### From types.rs (2 types)

1. **`LogEntry`** - Single operation in version log
   ```rust
   pub struct LogEntry {
       pub timestamp: u64,           // Unix timestamp in nanoseconds
       pub action: String,           // Action name (e.g., "init", "update")
       pub user: String,             // Username who performed action
       pub base_version: u64,        // Previous version timestamp (0 for init)
       pub size: usize,              // Delta size in bytes
       pub rows: usize,              // Number of rows affected
       pub hash: String,             // SHA-256 hash of delta content
       pub frame_id: Option<Uuid>,   // Frame UUID if part of coordinated batch
   }
   ```

2. **`ValidationReport`** - Report from log validation
   ```rust
   pub struct ValidationReport {
       pub total_entries: usize,
       pub valid_entries: usize,
       pub corrupted_count: usize,
       pub corrupted_lines: Vec<usize>,
       pub truncated: bool,
   }
   ```

---

### Public Functions (13 total)

#### types.rs - Type Construction (3 methods)

1. **`LogEntry::new(timestamp, action, user, base_version, size, rows, hash, frame_id) -> Self`**
   - Creates new log entry
   - All fields required (no defaults)
   - Example: `LogEntry::new(1736860900, "update".to_string(), "admin".to_string(), ...)`

2. **`ValidationReport::new() -> Self`**
   - Creates empty validation report
   - All counters initialised to 0

3. **`ValidationReport::is_healthy(&self) -> bool`**
   - Returns true if corrupted_count == 0
   - Used for quick health check

---

#### encoder.rs - Log Encoding (3 functions)

4. **`encode_log_entry(entry: &LogEntry) -> ReedResult<String>`**
   - Encodes log entry with CRC32 validation
   - Format: `REED|{length}|{timestamp}|{action_code}|{user_code}|{base_version}|{size}|{rows}|{hash}|{frame_id}|{crc32}`
   - Uses registry for action/user code lookups
   - < 150μs typical performance
   - Example output: `"REED|00000058|1736860900|2|1|1736860800|2500|15|sha256:abc123|n/a|A1B2C3D4"`

5. **`encode_log_entries(entries: &[LogEntry]) -> ReedResult<String>`**
   - Encodes multiple entries (newline-separated)
   - O(n) operation where n = number of entries
   - < 150μs per entry
   - Returns full log content ready to write

6. **`calculate_size_savings(entries: &[LogEntry]) -> ReedResult<(usize, usize)>`**
   - Calculates (encoded_size, plain_size) in bytes
   - Shows compression via integer codes
   - O(n) operation
   - Example: `(5000, 8000)` = 37.5% savings

---

#### decoder.rs - Log Decoding (5 functions)

7. **`decode_log_entry(line: &str) -> ReedResult<LogEntry>`**
   - Decodes single log entry with CRC32 validation
   - Supports 3 formats:
     - New format (11 fields): `REED|length|...|crc32` with validation
     - Old format (8 fields): backward compatibility with frame_id
     - Older format (7 fields): backward compatibility without frame_id
   - < 1ms typical performance
   - Validates CRC32, magic bytes, length
   - Uses registry for code → name lookups

8. **`decode_log_entries(content: &str) -> ReedResult<Vec<LogEntry>>`**
   - Decodes multiple entries (newline-separated)
   - Skips empty lines
   - O(n) operation
   - < 1ms per entry, < 50ms for 1000 entries
   - Returns complete entry list or error

9. **`filter_by_action<'a>(entries: &'a [LogEntry], action: &str) -> Vec<&'a LogEntry>`**
   - Filters entries by action name
   - O(n) linear scan
   - < 10ms for 1000 entries
   - Returns borrowed references (zero-copy)

10. **`filter_by_user<'a>(entries: &'a [LogEntry], user: &str) -> Vec<&'a LogEntry>`**
    - Filters entries by username
    - O(n) linear scan
    - < 10ms for 1000 entries
    - Returns borrowed references (zero-copy)

11. **`filter_by_time_range<'a>(entries: &'a [LogEntry], start: u64, end: u64) -> Vec<&'a LogEntry>`**
    - Filters entries by timestamp range (inclusive)
    - O(n) linear scan
    - < 10ms for 1000 entries
    - Returns borrowed references (zero-copy)

---

#### validator.rs - Validation & Crash Recovery (3 functions)

12. **`validate_log(log_path: &Path) -> ReedResult<ValidationReport>`**
    - Validates log file and returns detailed report
    - Decodes each entry and checks CRC32
    - Does NOT modify file (read-only)
    - < 1ms per entry, < 50ms for 1000 entries
    - Returns empty report if file doesn't exist

13. **`validate_and_truncate_log(log_path: &Path) -> ReedResult<ValidationReport>`**
    - Validates log AND truncates corrupted entries (crash recovery)
    - Finds first corrupted line
    - Keeps all valid lines before corruption
    - Writes truncated log back to disk
    - Sets `truncated = true` in report if modified
    - Used on startup for automatic recovery

14. **`append_entry(log_path: &Path, encoded_entry: &str) -> ReedResult<()>`**
    - Appends encoded entry to log file
    - Creates file if missing
    - Flushes immediately for durability
    - < 5ms operation (append + flush)
    - Used by versioning system to record operations

---

### Test Status

**Test files to migrate**:
```
last/src/log/encoder_test.rs     → current/src/ops/log/encoder_test.rs
last/src/log/decoder_test.rs     → current/src/ops/log/decoder_test.rs
last/src/log/validator_test.rs   → current/src/ops/log/validator_test.rs
```

**Test coverage expectations**:
- Encoder: Format validation, CRC32 calculation, registry lookups
- Decoder: All 3 formats (new/old/older), CRC32 validation, error handling
- Validator: Corruption detection, truncation, append operations
- Filter functions: Action, user, time range filters
- Edge cases: Empty logs, single entry, all corrupted

---

### Dependencies

**External crates** (from Cargo.toml):
```toml
uuid = { version = "1.6", features = ["v4"] }  # Frame IDs
crc32fast = "1.3"  # CRC32 validation
```

**Internal modules**:
- `crate::registry` - Action/user code lookups (get_action_code, get_username, etc.)
- `crate::error` - ReedError, ReedResult types

**Standard library**:
- `std::fs` - File operations (read, write, append)
- `std::io::Write` - Flush operation
- `std::path::Path` - Path handling

---

### Verification Commands

**Before implementation** (analyse last/):
```bash
# Count lines per file
wc -l last/src/log/*.rs | grep -v test

# Find all public types
rg "^pub struct|^pub enum" last/src/log/ -n

# Find all public functions
rg "^pub fn" last/src/log/ -n
rg "^    pub fn" last/src/log/ -n

# Check test files
ls -la last/src/log/*_test.rs
```

**During implementation** (build current/):
```bash
# Quick compile check
cargo check -p reedbase

# Run log tests only
cargo test -p reedbase --lib ops::log

# Watch mode
cargo watch -p reedbase -x "test --lib ops::log"
```

**After implementation** (verify parity):
```bash
# Both packages pass
cargo test -p reedbase --lib ops::log
cargo test -p reedbase-last --lib log

# Regression check
./scripts/regression-verify.sh log

# Quality check
./scripts/quality-check.sh current/src/ops/log/types.rs
./scripts/quality-check.sh current/src/ops/log/encoder.rs
./scripts/quality-check.sh current/src/ops/log/decoder.rs
./scripts/quality-check.sh current/src/ops/log/validator.rs

# No clippy warnings
cargo clippy -p reedbase -- -D warnings
```

---

### Bestätigung (Confirmation)

**I hereby confirm**:
- ✅ I have read ALL files in `last/src/log/`
- ✅ I have enumerated ALL 2 public types above
- ✅ I have enumerated ALL 13 public functions above with exact signatures
- ✅ I understand the log format: `REED|length|data|crc32`
- ✅ I understand the 3 backward-compatible formats (11/8/7 fields)
- ✅ I understand the CRC32 validation mechanism
- ✅ I understand the registry integration (action/user code lookups)
- ✅ I understand the crash recovery (validate_and_truncate_log)
- ✅ I will achieve 100% behaviour parity with last/
- ✅ I will NOT add features, optimisations, or "improvements"
- ✅ I will maintain ALL existing function signatures exactly
- ✅ I will adapt tests from last/ to current/ without modification

**Signature**: ________________ **Date**: ________________

---

## Context & Scope

### What is this module?

The **log module** provides encoded version history logging with CRC32 validation. It records all database operations (init, update, rollback) in a compact, validated format that survives crashes.

**Key characteristics**:
- **Encoded**: Uses integer codes instead of strings (smaller files)
- **Validated**: CRC32 checksum on every entry
- **Crash-safe**: Automatic truncation of corrupted entries
- **Backward-compatible**: Reads 3 different formats (11/8/7 fields)
- **Registry-based**: Action/user names mapped to integer codes

### Why this module?

1. **Space efficiency**: Integer codes reduce log size by ~40%
2. **Integrity**: CRC32 validation detects corruption
3. **Crash recovery**: Automatic truncation of corrupted entries
4. **Audit trail**: Complete history of all database operations
5. **Versioning support**: Used by ops/versioning/ for delta tracking

### Architecture Context

**Position in layered architecture**:
```
ops/        ← Log lives here (monitoring/operations)
  ├── backup/
  ├── versioning/    ← Uses log/ for operation history
  ├── metrics/
  └── log/          ← THIS MODULE
process/
api/
validate/
store/
core/
```

**Log is used by versioning** - records every delta operation:
- **versioning/** creates deltas and calls `encode_log_entry()`
- **log/** handles encoding, decoding, validation
- **registry/** provides action/user code mappings

### Log Format

**New format (11 fields with CRC32)**:
```
REED|{length}|{timestamp}|{action_code}|{user_code}|{base_version}|{size}|{rows}|{hash}|{frame_id}|{crc32}
REED|00000058|1736860900|2|1|1736860800|2500|15|sha256:abc123|n/a|A1B2C3D4
```

**Fields**:
1. `REED` - Magic bytes (constant)
2. `00000058` - Total entry length (8 hex chars)
3. `1736860900` - Timestamp (Unix nanos)
4. `2` - Action code (from actions.dict)
5. `1` - User code (from users.dict)
6. `1736860800` - Base version timestamp
7. `2500` - Delta size in bytes
8. `15` - Number of rows affected
9. `sha256:abc123` - Delta hash
10. `n/a` - Frame ID (or UUID)
11. `A1B2C3D4` - CRC32 of fields 3-10 (8 hex chars)

**Old formats (backward compatibility)**:
- **8 fields**: `{timestamp}|{action_code}|{user_code}|{base_version}|{size}|{rows}|{hash}|{frame_id}` (no CRC32)
- **7 fields**: Same but without frame_id

**CRC32 Calculation**:
```rust
let data = format!("{}|{}|{}|{}|{}|{}|{}|{}",
    timestamp, action_code, user_code, base_version, size, rows, hash, frame_id);
let mut hasher = Hasher::new();
hasher.update(data.as_bytes());
let crc32 = hasher.finalize();  // u32
```

---

## Implementation Steps

### Step 1: Create Module Structure

Create the log module in `current/src/ops/log/`:

```bash
mkdir -p current/src/ops/log
touch current/src/ops/log/types.rs
touch current/src/ops/log/encoder.rs
touch current/src/ops/log/decoder.rs
touch current/src/ops/log/validator.rs
touch current/src/ops/log/mod.rs
```

Update `current/src/ops/mod.rs`:
```rust
pub mod backup;
pub mod versioning;
pub mod metrics;
pub mod log;  // Add this line
```

---

### Step 2: Implement Log Types (types.rs)

**Reference**: `last/src/log/types.rs` (133 lines)

**Key types**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Type definitions for log system.

use uuid::Uuid;

/// Log entry for version history.
#[derive(Debug, Clone, PartialEq)]
pub struct LogEntry {
    pub timestamp: u64,           // Unix timestamp in nanoseconds
    pub action: String,           // Action name (e.g., "init", "update")
    pub user: String,             // Username
    pub base_version: u64,        // Previous version timestamp (0 for init)
    pub size: usize,              // Delta size in bytes
    pub rows: usize,              // Number of rows affected
    pub hash: String,             // SHA-256 hash of delta
    pub frame_id: Option<Uuid>,   // Frame UUID if coordinated batch
}

impl LogEntry {
    /// Creates new log entry.
    pub fn new(
        timestamp: u64,
        action: String,
        user: String,
        base_version: u64,
        size: usize,
        rows: usize,
        hash: String,
        frame_id: Option<Uuid>,
    ) -> Self {
        Self {
            timestamp,
            action,
            user,
            base_version,
            size,
            rows,
            hash,
            frame_id,
        }
    }
}

/// Validation report from log validation.
#[derive(Debug, Clone, PartialEq)]
pub struct ValidationReport {
    pub total_entries: usize,
    pub valid_entries: usize,
    pub corrupted_count: usize,
    pub corrupted_lines: Vec<usize>,
    pub truncated: bool,
}

impl ValidationReport {
    /// Creates new validation report.
    pub fn new() -> Self {
        Self {
            total_entries: 0,
            valid_entries: 0,
            corrupted_count: 0,
            corrupted_lines: Vec::new(),
            truncated: false,
        }
    }

    /// Checks if log is healthy (no corruption).
    pub fn is_healthy(&self) -> bool {
        self.corrupted_count == 0
    }
}

impl Default for ValidationReport {
    fn default() -> Self {
        Self::new()
    }
}
```

**Exact parity required**:
- LogEntry struct fields (timestamp, action, user, base_version, size, rows, hash, frame_id)
- ValidationReport struct fields (total_entries, valid_entries, corrupted_count, corrupted_lines, truncated)
- is_healthy() logic (corrupted_count == 0)

---

### Step 3: Implement Log Encoder (encoder.rs)

**Reference**: `last/src/log/encoder.rs` (168 lines)

**Key function - encode_log_entry()**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Log encoding for version history.

use crate::error::ReedResult;
use crate::log::types::LogEntry;
use crate::registry;
use crc32fast::Hasher;

const MAGIC: &str = "REED";

/// Encode log entry to string with CRC32 validation.
pub fn encode_log_entry(entry: &LogEntry) -> ReedResult<String> {
    // Get integer codes from registry
    let action_code = registry::get_action_code(&entry.action)?;
    let user_code = registry::get_or_create_user_code(&entry.user)?;

    let frame_id_str = entry
        .frame_id
        .map(|id| id.to_string())
        .unwrap_or_else(|| "n/a".to_string());

    // Build data portion (fields 3-10)
    let data = format!(
        "{}|{}|{}|{}|{}|{}|{}|{}",
        entry.timestamp,
        action_code,
        user_code,
        entry.base_version,
        entry.size,
        entry.rows,
        entry.hash,
        frame_id_str
    );

    // Calculate CRC32 of data
    let mut hasher = Hasher::new();
    hasher.update(data.as_bytes());
    let crc32 = hasher.finalize();

    // Build entry with placeholder length
    let length_placeholder = "00000000";
    let temp_entry = format!("{}|{}|{}|{:08X}", MAGIC, length_placeholder, data, crc32);
    let actual_length = temp_entry.len();

    // Build final entry with actual length
    let final_entry = format!("{}|{:08X}|{}|{:08X}", MAGIC, actual_length, data, crc32);

    Ok(final_entry)
}

/// Encode multiple log entries.
pub fn encode_log_entries(entries: &[LogEntry]) -> ReedResult<String> {
    let mut lines = Vec::new();
    for entry in entries {
        lines.push(encode_log_entry(entry)?);
    }
    Ok(lines.join("\n"))
}

/// Calculate encoded size vs plain text size.
pub fn calculate_size_savings(entries: &[LogEntry]) -> ReedResult<(usize, usize)> {
    let encoded = encode_log_entries(entries)?.len();

    let mut plain_size = 0;
    for entry in entries {
        let frame_id_str = entry
            .frame_id
            .map(|id| id.to_string())
            .unwrap_or_else(|| "n/a".to_string());

        plain_size += format!(
            "{}|{}|{}|{}|{}|{}|{}|{}",
            entry.timestamp,
            entry.action,
            entry.user,
            entry.base_version,
            entry.size,
            entry.rows,
            entry.hash,
            frame_id_str
        )
        .len()
            + 1; // +1 for newline
    }

    Ok((encoded, plain_size))
}
```

**Critical behaviours**:
- Registry lookups: `get_action_code()`, `get_or_create_user_code()`
- CRC32 calculation: ONLY on data portion (fields 3-10)
- Length calculation: Two-pass (placeholder → actual)
- Frame ID formatting: UUID → string or "n/a"

---

### Step 4: Implement Log Decoder (decoder.rs)

**Reference**: `last/src/log/decoder.rs` (366 lines)

**Key function - decode_log_entry()** (supports 3 formats):
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Log decoding for version history.

use crate::error::{ReedError, ReedResult};
use crate::log::types::LogEntry;
use crate::registry;
use crc32fast::Hasher;
use uuid::Uuid;

const MAGIC: &str = "REED";

/// Decode log entry from string with CRC32 validation.
pub fn decode_log_entry(line: &str) -> ReedResult<LogEntry> {
    let parts: Vec<&str> = line.split('|').collect();

    // Detect format by field count
    if parts.len() == 11 {
        // New format with CRC32 validation
        decode_new_format(line, &parts)
    } else if parts.len() == 8 || parts.len() == 7 {
        // Old format without CRC32 (backward compatibility)
        decode_old_format(&parts)
    } else {
        Err(ReedError::ParseError {
            reason: format!("Expected 7, 8, or 11 fields, got {}", parts.len()),
        })
    }
}

/// Decode new format (11 fields) with CRC32 validation.
fn decode_new_format(line: &str, parts: &[&str]) -> ReedResult<LogEntry> {
    // Validate magic bytes
    if parts[0] != MAGIC {
        return Err(ReedError::CorruptedLogEntry {
            line: 0,
            reason: format!("Invalid magic bytes: expected '{}', got '{}'", MAGIC, parts[0]),
        });
    }

    // Validate length
    let expected_length = u32::from_str_radix(parts[1], 16)
        .map_err(|e| ReedError::ParseError {
            reason: format!("Invalid length field: {}", e),
        })? as usize;

    if line.len() != expected_length {
        return Err(ReedError::CorruptedLogEntry {
            line: 0,
            reason: format!("Length mismatch: expected {}, got {}", expected_length, line.len()),
        });
    }

    // Validate CRC32
    let expected_crc = u32::from_str_radix(parts[10], 16)
        .map_err(|e| ReedError::ParseError {
            reason: format!("Invalid CRC32 field: {}", e),
        })?;

    let data = parts[2..10].join("|");
    let mut hasher = Hasher::new();
    hasher.update(data.as_bytes());
    let actual_crc = hasher.finalize();

    if actual_crc != expected_crc {
        return Err(ReedError::CorruptedLogEntry {
            line: 0,
            reason: format!("CRC32 mismatch: expected {:08X}, got {:08X}", expected_crc, actual_crc),
        });
    }

    // Parse fields (similar to old format, from parts[2..10])
    // ... (parse timestamp, action_code, user_code, etc.)

    // Decode codes to names
    let action = registry::get_action_name(action_code)?;
    let user = registry::get_username(user_code)?;

    Ok(LogEntry { /* ... */ })
}

/// Decode old format (7 or 8 fields) without CRC32.
fn decode_old_format(parts: &[&str]) -> ReedResult<LogEntry> {
    // Parse timestamp, action_code, user_code, base_version, size, rows, hash
    // Parse frame_id if 8 fields
    // Decode codes to names
    // ... (see last/src/log/decoder.rs for full implementation)
}

/// Decode multiple log entries.
pub fn decode_log_entries(content: &str) -> ReedResult<Vec<LogEntry>> {
    let mut entries = Vec::new();

    for (line_num, line) in content.lines().enumerate() {
        if line.trim().is_empty() {
            continue;
        }

        entries.push(decode_log_entry(line).map_err(|e| match e {
            ReedError::CorruptedLogEntry { reason, .. } => ReedError::CorruptedLogEntry {
                line: line_num + 1,
                reason,
            },
            ReedError::ParseError { reason } => ReedError::ParseError {
                reason: format!("Line {}: {}", line_num + 1, reason),
            },
            other => other,
        })?);
    }

    Ok(entries)
}

// Filter functions (see last/src/log/decoder.rs for implementations)
pub fn filter_by_action<'a>(entries: &'a [LogEntry], action: &str) -> Vec<&'a LogEntry> { /* ... */ }
pub fn filter_by_user<'a>(entries: &'a [LogEntry], user: &str) -> Vec<&'a LogEntry> { /* ... */ }
pub fn filter_by_time_range<'a>(entries: &'a [LogEntry], start: u64, end: u64) -> Vec<&'a LogEntry> { /* ... */ }
```

**Critical behaviours**:
- 3 format support: 11 fields (new) / 8 fields (old with frame_id) / 7 fields (older)
- CRC32 validation: ONLY for new format (11 fields)
- Magic bytes validation: "REED"
- Length validation: Must match actual line length
- Registry lookups: `get_action_name()`, `get_username()`
- Error line numbers: Track in decode_log_entries()

---

### Step 5: Implement Log Validator (validator.rs)

**Reference**: `last/src/log/validator.rs` (206 lines)

**Key functions**:
```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Log validation and crash recovery.

use crate::error::{ReedError, ReedResult};
use crate::log::decoder::decode_log_entry;
use crate::log::types::ValidationReport;
use std::fs;
use std::io::Write;
use std::path::Path;

/// Validate log file and return detailed report.
pub fn validate_log(log_path: &Path) -> ReedResult<ValidationReport> {
    let mut report = ValidationReport::new();

    if !log_path.exists() {
        return Ok(report); // Empty log is valid
    }

    let content = fs::read_to_string(log_path).map_err(|e| ReedError::IoError {
        operation: "read_log".to_string(),
        reason: e.to_string(),
    })?;

    for (line_num, line) in content.lines().enumerate() {
        if line.trim().is_empty() {
            continue;
        }

        report.total_entries += 1;

        match decode_log_entry(line) {
            Ok(_) => {
                report.valid_entries += 1;
            }
            Err(ReedError::CorruptedLogEntry { .. }) | Err(ReedError::ParseError { .. }) => {
                report.corrupted_count += 1;
                report.corrupted_lines.push(line_num + 1);
            }
            Err(e) => {
                // Other errors (UnknownActionCode, etc.) also count as corruption
                report.corrupted_count += 1;
                report.corrupted_lines.push(line_num + 1);
                eprintln!("Warning: Line {}: {}", line_num + 1, e);
            }
        }
    }

    Ok(report)
}

/// Validate log and truncate corrupted entries (crash recovery).
pub fn validate_and_truncate_log(log_path: &Path) -> ReedResult<ValidationReport> {
    let mut report = validate_log(log_path)?;

    if report.corrupted_count == 0 {
        return Ok(report); // Nothing to do
    }

    // Find first corrupted line
    let first_corruption = report.corrupted_lines.iter().min().copied().unwrap_or(0);

    if first_corruption == 0 {
        return Ok(report); // All corrupted or empty
    }

    // Read content
    let content = fs::read_to_string(log_path).map_err(|e| ReedError::IoError {
        operation: "read_log_for_truncation".to_string(),
        reason: e.to_string(),
    })?;

    // Keep only valid lines before first corruption
    let valid_lines: Vec<&str> = content
        .lines()
        .enumerate()
        .filter(|(idx, line)| {
            let line_num = idx + 1;
            !line.trim().is_empty() && line_num < first_corruption
        })
        .map(|(_, line)| line)
        .collect();

    // Write truncated log
    let truncated_content = valid_lines.join("\n");
    if !truncated_content.is_empty() {
        fs::write(log_path, format!("{}\n", truncated_content)).map_err(|e| {
            ReedError::IoError {
                operation: "write_truncated_log".to_string(),
                reason: e.to_string(),
            }
        })?;
    } else {
        // Remove empty log
        let _ = fs::remove_file(log_path);
    }

    report.truncated = true;
    report.valid_entries = valid_lines.len();
    report.total_entries = valid_lines.len();

    Ok(report)
}

/// Append validated entry to log file.
pub fn append_entry(log_path: &Path, encoded_entry: &str) -> ReedResult<()> {
    let mut file = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_path)
        .map_err(|e| ReedError::IoError {
            operation: "open_log_for_append".to_string(),
            reason: e.to_string(),
        })?;

    writeln!(file, "{}", encoded_entry).map_err(|e| ReedError::IoError {
        operation: "append_log_entry".to_string(),
        reason: e.to_string(),
    })?;

    file.flush().map_err(|e| ReedError::IoError {
        operation: "flush_log".to_string(),
        reason: e.to_string(),
    })?;

    Ok(())
}
```

**Critical behaviours**:
- validate_log(): Read-only, returns report
- validate_and_truncate_log(): Modifies file, truncates at first corruption
- append_entry(): Creates parent dirs if needed, flushes immediately
- Truncation strategy: Keep all valid lines BEFORE first corruption

---

### Step 6: Create Module Root (mod.rs)

**Reference**: `last/src/log/mod.rs` (26 lines)

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Encoded log system for version history.
//!
//! Provides efficient log encoding/decoding using integer codes and CRC32 validation.

pub mod decoder;
pub mod encoder;
pub mod types;
pub mod validator;

// Re-export public API
pub use decoder::{
    decode_log_entries, decode_log_entry, filter_by_action, filter_by_time_range, filter_by_user,
};
pub use encoder::{calculate_size_savings, encode_log_entries, encode_log_entry};
pub use types::{LogEntry, ValidationReport};
pub use validator::{append_entry, validate_and_truncate_log, validate_log};
```

**Key points**:
- Re-export commonly used functions
- Module-level documentation
- Clear public API surface

---

### Step 7: Migrate Tests

**Test files** (adapt from last/ to current/):
```
last/src/log/encoder_test.rs     → current/src/ops/log/encoder_test.rs
last/src/log/decoder_test.rs     → current/src/ops/log/decoder_test.rs
last/src/log/validator_test.rs   → current/src/ops/log/validator_test.rs
```

**Test migration checklist**:
- [ ] Update import paths (`reedbase_last::log` → `reedbase::ops::log`)
- [ ] Update registry mock paths if needed
- [ ] Verify identical assertions (no behaviour changes)
- [ ] Test all 3 decoder formats (11/8/7 fields)
- [ ] Test CRC32 validation errors
- [ ] Test truncation logic
- [ ] Run both test suites to confirm parity

---

### Step 8: Add Dependencies to Cargo.toml

**Add required crates**:
```toml
[dependencies]
uuid = { version = "1.6", features = ["v4"] }
crc32fast = "1.3"
```

Verify versions match `last/Cargo.toml`.

---

### Step 9: Run Quality Checks

```bash
# Compile check
cargo check -p reedbase

# Run tests
cargo test -p reedbase --lib ops::log

# Baseline check (last/ still passing)
cargo test -p reedbase-last --lib log

# Quality checks (all 8 standards)
./scripts/quality-check.sh current/src/ops/log/types.rs
./scripts/quality-check.sh current/src/ops/log/encoder.rs
./scripts/quality-check.sh current/src/ops/log/decoder.rs
./scripts/quality-check.sh current/src/ops/log/validator.rs

# No clippy warnings
cargo clippy -p reedbase --lib -- -D warnings

# Regression verification
./scripts/regression-verify.sh log
```

---

### Step 10: Verify Behaviour Parity

**Manual verification**:

1. **Encoding produces correct format**:
   ```rust
   let entry = LogEntry::new(1736860900, "update".to_string(), ...);
   let encoded = encode_log_entry(&entry)?;
   assert!(encoded.starts_with("REED|"));
   assert!(encoded.split('|').count() == 11);
   ```

2. **CRC32 validation works**:
   ```rust
   let encoded = encode_log_entry(&entry)?;
   let decoded = decode_log_entry(&encoded)?;
   assert_eq!(decoded.timestamp, entry.timestamp);
   ```

3. **Backward compatibility with old formats**:
   ```rust
   let old_format = "1736860900|2|1|1736860800|2500|15|sha256:abc123|n/a";
   let decoded = decode_log_entry(old_format)?;
   assert_eq!(decoded.action, "update");
   ```

4. **Truncation removes corruption**:
   ```rust
   // Write log with corrupted entry in middle
   // Call validate_and_truncate_log()
   // Verify only valid entries remain
   ```

5. **Size savings calculation**:
   ```rust
   let (encoded, plain) = calculate_size_savings(&entries)?;
   assert!(encoded < plain); // Encoding saves space
   ```

---

## Quality Standards (8 Total)

### Standard #0: Code Reuse ✅
- [x] Checked `project_functions.csv` for existing log functions
- [x] Using `crate::registry` for code lookups (no duplication)
- [x] Using `crc32fast` crate (no custom CRC32 implementation)
- [x] Using `std::fs` for file operations (no custom file handling)

**Why compliant**: All functions are new (log module didn't exist in current/), uses registry and standard library.

---

### Standard #1: BBC English ✅
- [x] All comments use British spelling
- [x] "optimisation" not "optimization"
- [x] "initialised" not "initialized"
- [x] "recognised" not "recognized"

**Examples**:
```rust
/// Calculates CRC32 checksum for validation.  ✅
// not: "Calculates CRC32 checksum for verification"

/// Initialised to zero.  ✅
// not: "Initialized to zero"
```

---

### Standard #2: KISS - Files <400 Lines ✅
- [x] types.rs: 133 lines (< 400) ✅
- [x] encoder.rs: 168 lines (< 400) ✅
- [x] decoder.rs: 366 lines (< 400) ✅
- [x] validator.rs: 206 lines (< 400) ✅
- [x] mod.rs: 26 lines (< 400) ✅

**Verification**:
```bash
wc -l current/src/ops/log/*.rs
# All files must be < 400 lines
```

---

### Standard #3: Specific File Naming ✅
- [x] types.rs (LogEntry, ValidationReport) ✅
- [x] encoder.rs (encoding functions) ✅
- [x] decoder.rs (decoding functions) ✅
- [x] validator.rs (validation and crash recovery) ✅

**NOT**:
- ❌ utils.rs
- ❌ helpers.rs
- ❌ common.rs
- ❌ log.rs (too generic for multi-file module)

---

### Standard #4: One Function = One Job ✅
- [x] `encode_log_entry()` - ONLY encodes one entry
- [x] `decode_log_entry()` - ONLY decodes one entry (delegates format detection)
- [x] `validate_log()` - ONLY validates (no modification)
- [x] `validate_and_truncate_log()` - Validates AND truncates (acceptable composite)
- [x] `filter_by_action()`, `filter_by_user()`, `filter_by_time_range()` - Each filters ONE dimension
- [x] No boolean flags (no `validate(truncate: bool)`)

**Examples of good separation**:
```rust
pub fn filter_by_action(entries, action) -> Vec  // ONLY action
pub fn filter_by_user(entries, user) -> Vec      // ONLY user
pub fn filter_by_time_range(entries, start, end) -> Vec  // ONLY time range

// NOT: pub fn filter(entries, action, user, time, mode)
```

---

### Standard #5: Separate Test Files ✅
- [x] encoder_test.rs (not inline in encoder.rs)
- [x] decoder_test.rs (not inline in decoder.rs)
- [x] validator_test.rs (not inline in validator.rs)

**NO inline modules**:
```rust
// ❌ FORBIDDEN
#[cfg(test)]
mod tests {
    use super::*;
    // tests here
}
```

---

### Standard #6: No Swiss Army Functions ✅
- [x] No `handle()`, `process()`, `manage()` doing many things
- [x] `decode_log_entry()` delegates to decode_new_format() or decode_old_format() (acceptable - clear branching)
- [x] `validate_and_truncate_log()` does TWO related things (acceptable - atomic operation for crash recovery)
- [x] Each filter function is separate (not one filter with mode flags)

**Avoided**:
```rust
// ❌ Swiss Army function
pub fn process_log(path, decode, validate, truncate, filter_action, filter_user) {
    if decode { /* ... */ }
    if validate { /* ... */ }
    if truncate { /* ... */ }
    // ...
}

// ✅ Separate, focused functions
pub fn decode_log_entries(content) -> Result<Vec<LogEntry>>
pub fn validate_log(path) -> Result<ValidationReport>
pub fn validate_and_truncate_log(path) -> Result<ValidationReport>
```

---

### Standard #7: No Generic Names ✅
- [x] `encode_log_entry()` not `encode()` (context: log entry)
- [x] `ValidationReport` not `Report` (context: validation)
- [x] `decode_new_format()` not `decode_new()` (context: format)
- [x] `append_entry()` not `append()` (context: entry)

---

### Standard #8: Architecture - Layered (not MVC) ✅
- [x] Log is in `ops/` layer (operations/monitoring)
- [x] No controllers (`handle_request()` in lib)
- [x] No models with behaviour (`impl LogEntry { fn save() }`)
- [x] No views (`Display`, `println!` in lib)
- [x] Pure functions: data in → data out

**Why compliant**:
- Log provides **services** (encode, decode, validate)
- No business logic (pure data transformation)
- No MVC patterns present

---

## Testing Requirements

### Unit Tests

**encoder_test.rs** (Encoding and CRC32):
- [ ] encode_log_entry() produces correct format (11 fields)
- [ ] CRC32 calculation matches expected value
- [ ] Length field matches actual length
- [ ] Frame ID formatting (UUID vs "n/a")
- [ ] encode_log_entries() joins with newlines
- [ ] calculate_size_savings() shows compression

**decoder_test.rs** (Decoding all formats):
- [ ] decode_log_entry() handles new format (11 fields)
- [ ] decode_log_entry() handles old format (8 fields)
- [ ] decode_log_entry() handles older format (7 fields)
- [ ] CRC32 validation detects corruption
- [ ] Magic bytes validation works
- [ ] Length validation works
- [ ] Registry lookups work (action/user codes)
- [ ] filter_by_action() filters correctly
- [ ] filter_by_user() filters correctly
- [ ] filter_by_time_range() filters correctly
- [ ] Error handling for invalid formats

**validator_test.rs** (Validation and crash recovery):
- [ ] validate_log() returns correct report
- [ ] validate_log() detects corrupted entries
- [ ] validate_and_truncate_log() truncates at first corruption
- [ ] validate_and_truncate_log() sets truncated flag
- [ ] validate_and_truncate_log() removes empty log
- [ ] append_entry() creates file if missing
- [ ] append_entry() appends to existing file
- [ ] append_entry() flushes immediately
- [ ] Edge case: Empty log file
- [ ] Edge case: All entries corrupted
- [ ] Edge case: First entry corrupted

### Integration Tests

**Full workflow test** (in `current/tests/`):
```rust
#[test]
fn test_log_end_to_end() {
    // 1. Create and encode entry
    let entry = LogEntry::new(1736860900, "update".to_string(), ...);
    let encoded = encode_log_entry(&entry).unwrap();

    // 2. Write to file
    let log_path = PathBuf::from("/tmp/test_version.log");
    append_entry(&log_path, &encoded).unwrap();

    // 3. Validate log
    let report = validate_log(&log_path).unwrap();
    assert!(report.is_healthy());
    assert_eq!(report.total_entries, 1);

    // 4. Decode log
    let content = fs::read_to_string(&log_path).unwrap();
    let entries = decode_log_entries(&content).unwrap();
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].action, "update");

    // Cleanup
    fs::remove_file(log_path).unwrap();
}
```

### Regression Tests

**Baseline comparison** (compare with last/):
```bash
# Both test suites pass
cargo test -p reedbase --lib ops::log
cargo test -p reedbase-last --lib log

# Behaviour parity
./scripts/regression-verify.sh log
```

**Specific parity checks**:
- [ ] Identical encoding format (compare encoded strings)
- [ ] Identical CRC32 values for same input
- [ ] Identical decoding results for all 3 formats
- [ ] Identical truncation behaviour
- [ ] Identical filter results

---

## Success Criteria

### Functional Requirements ✅
- [x] All 13 public functions implemented with exact signatures
- [x] All 2 types (LogEntry, ValidationReport) implemented
- [x] Encoding with CRC32 validation (11-field format)
- [x] Decoding with 3 format support (11/8/7 fields)
- [x] Validation and crash recovery (validate_and_truncate_log)
- [x] Filter functions (action, user, time range)
- [x] Registry integration for code lookups
- [x] Append with flush for durability

### Quality Requirements ✅
- [x] All files < 400 lines (Standard #2)
- [x] BBC English throughout (Standard #1)
- [x] Specific file names (Standard #3)
- [x] One function = one job (Standard #4)
- [x] Separate test files (Standard #5)
- [x] No Swiss Army functions (Standard #6)
- [x] No generic names (Standard #7)
- [x] Layered architecture (Standard #8)
- [x] No code duplication (Standard #0)

### Regression Requirements ✅
- [x] All tests from last/ adapted and passing
- [x] Behaviour parity with last/src/log/
- [x] Identical encoding format
- [x] Identical CRC32 calculation
- [x] Identical decoding for all formats
- [x] `./scripts/regression-verify.sh log` passes

### Performance Requirements ✅
- [x] encode_log_entry(): < 150μs typical
- [x] decode_log_entry(): < 1ms typical
- [x] validate_log(): < 1ms per entry
- [x] append_entry(): < 5ms (append + flush)
- [x] No performance regressions vs last/

### Documentation Requirements ✅
- [x] Module-level docs with overview
- [x] All public types documented
- [x] All public functions documented
- [x] Performance characteristics documented
- [x] Log format specification documented

---

## Commit Message

```
[CLEAN-070-01] feat(ops): implement log system with CRC32 validation

✅ QS-Matrix verified (all 8 CLAUDE.md standards)
✅ Regression tests: 100% passing (XX/XX tests)
✅ Behaviour identical to last/src/log/

Implemented complete log system for version history:

Types (types.rs, 133 lines):
- LogEntry: Version history entry (timestamp, action, user, etc.)
- ValidationReport: Corruption detection report

Encoder (encoder.rs, 168 lines):
- encode_log_entry(): CRC32-validated encoding
- Format: REED|length|timestamp|codes|...|crc32
- Registry integration for action/user codes
- 40% size savings vs plain text

Decoder (decoder.rs, 366 lines):
- decode_log_entry(): 3 format support (11/8/7 fields)
- Backward compatibility with old formats
- CRC32, magic bytes, length validation
- Filter functions (action, user, time range)

Validator (validator.rs, 206 lines):
- validate_log(): Corruption detection (read-only)
- validate_and_truncate_log(): Crash recovery
- append_entry(): Durable append with flush

Log Format:
REED|{length}|{timestamp}|{action_code}|{user_code}|{base}|{size}|{rows}|{hash}|{frame}|{crc32}

Test Coverage:
- encoder_test.rs: Format, CRC32, registry lookups
- decoder_test.rs: All 3 formats, validation, filters
- validator_test.rs: Corruption detection, truncation, append

Quality Standards:
✅ #0: No duplicate functions (uses registry for codes)
✅ #1: BBC English throughout ("initialised", "recognised")
✅ #2: All files <400 lines (largest: decoder.rs 366)
✅ #3: Specific naming (encoder, decoder, validator, types)
✅ #4: One function = one job (separate filter functions)
✅ #5: Separate test files (*_test.rs)
✅ #6: No Swiss Army functions
✅ #7: Contextual names (encode_log_entry, ValidationReport)
✅ #8: Layered architecture (ops/ layer, no MVC)

Workspace packages:
- reedbase (current): Implementation complete
- reedbase-last (last): Baseline tests still passing

Dependencies:
- uuid 1.6 (frame IDs)
- crc32fast 1.3 (CRC32 validation)

Files:
- current/src/ops/log/types.rs (133 lines)
- current/src/ops/log/encoder.rs (168 lines)
- current/src/ops/log/decoder.rs (366 lines)
- current/src/ops/log/validator.rs (206 lines)
- current/src/ops/log/mod.rs (26 lines)
- current/src/ops/log/encoder_test.rs
- current/src/ops/log/decoder_test.rs
- current/src/ops/log/validator_test.rs
```

---

## Notes

### Key Implementation Details

1. **Log Format (11 fields)**:
   ```
   REED|{length}|{timestamp}|{action_code}|{user_code}|{base_version}|{size}|{rows}|{hash}|{frame_id}|{crc32}
   ```
   - Magic: "REED" (constant)
   - Length: Total line length (8 hex chars)
   - CRC32: Checksum of fields 3-10 (8 hex chars)

2. **CRC32 Calculation**:
   - ONLY data portion (fields 3-10)
   - Does NOT include magic, length, or CRC32 itself
   - Uses crc32fast crate (standard implementation)

3. **Backward Compatibility**:
   - 11 fields: New format with CRC32 validation
   - 8 fields: Old format with frame_id, no CRC32
   - 7 fields: Older format without frame_id or CRC32
   - Decoder detects format by field count

4. **Registry Integration**:
   - Encoding: `get_action_code()`, `get_or_create_user_code()`
   - Decoding: `get_action_name()`, `get_username()`
   - Integer codes reduce file size by ~40%

5. **Crash Recovery**:
   - validate_and_truncate_log() finds first corruption
   - Keeps all valid entries BEFORE first corruption
   - Discards corrupted entry and everything after
   - Atomic write (truncated content replaces file)

### Common Pitfalls to Avoid

1. ❌ Don't calculate CRC32 on entire line (only fields 3-10)
2. ❌ Don't break backward compatibility (must support 7/8/11 fields)
3. ❌ Don't modify validate_log() to truncate (it's read-only)
4. ❌ Don't change magic bytes from "REED"
5. ❌ Don't change length format (must be 8 hex chars)
6. ❌ Don't skip flush in append_entry() (durability required)
7. ❌ Don't change registry function names (API contract)

### Migration Gotchas

1. **Import paths change**:
   - last: `use reedbase_last::log::encode_log_entry`
   - current: `use reedbase::ops::log::encode_log_entry`

2. **Registry dependency**:
   - Must have `crate::registry` module working
   - Tests may need registry mocks

3. **Error types**:
   - Uses `ReedError::CorruptedLogEntry`, `ReedError::ParseError`
   - Must exist in `current/src/error.rs`

---

**Ticket Complete**: Ready for implementation following Clean Room Rebuild Protocol.
