# Changelog

All notable changes to ReedBase will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned for v0.3.0 (Q2 2025)
- Write-Ahead Log (WAL) implementation for crash recovery
- Automatic WAL compaction
- Durability guarantees for writes

### Planned for v0.4.0 (Q3 2025)
- Atomic batch operations (multi-key atomicity)
- Compare-and-swap (CAS) operations
- Atomic increment/decrement operations
- Optimistic locking with version tracking

### Planned for v1.0.0 (Q4 2025)
- ACID transactions (BEGIN/COMMIT/ROLLBACK)
- Isolation levels (Read Committed, Serializable)
- Production-ready for e-commerce use cases

See [ECOMMERCE_GAP_ANALYSIS.md](ECOMMERCE_GAP_ANALYSIS.md) for detailed roadmap.

---

## [0.2.0-beta] - 2025-01-XX

### Added

#### Smart Indices (REED-19-09)
- **Hash Indices**: O(1) lookup for exact key matches
- **B+-Tree Indices**: O(log n) persistent indices for range queries
- **Automatic backend selection**: System chooses Hash vs BTree based on query pattern
- **Index persistence**: B+-Tree indices stored on disk, loaded via mmap (< 100ms cold start)
- **Index metadata tracking**: JSON-based metadata in `.reed/indices/metadata.json`
- Performance: 100-1000x faster queries with smart index selection

#### ReedQL Parser (REED-19-10)
- **Custom ReedQL parser**: SQL-like syntax for key-value operations
- **Subquery support**: Nested queries with optimal execution
- **Query optimization**: ReedBase-specific optimizations for CMS patterns
- **ReedQL operations**:
  - `SELECT * WHERE key = 'exact.match'`
  - `SELECT * WHERE key LIKE 'prefix.%'`
  - `SELECT * WHERE key >= 'a' AND key < 'z'`
  - `INSERT INTO table (key, value) VALUES (...)`
  - `UPDATE table SET value = 'x' WHERE key = 'y'`
  - `DELETE FROM table WHERE key = 'x'`

#### Crash Recovery (REED-19-03, REED-19-04)
- **CRC32 validation**: Detect corrupted CSV files
- **Delta reconstruction**: Rebuild from last known-good state
- **Automatic recovery**: Database self-heals on startup if corruption detected
- **Backup integration**: Restores from backup if delta reconstruction fails

#### RBKS v2 Key Validation (REED-19-08)
- **Angle-bracket modifiers**: Support for `<modifier>` in key names
- **Strict validation**: Enforces ReedBase Key Standard (RBKS) v2
- **Error messages**: Clear validation errors with suggestions

#### Performance Testing
- **Benchmark suite**: Compare ReedBase vs MySQL/PostgreSQL/SQLite
- **CMS-specific scenarios**: Single lookup, namespace query, range query, cold start, concurrent reads
- **Benchmark scripts**: MySQL and PostgreSQL comparison scripts
- **Report generator**: Automated performance report generation

### Changed
- **Index architecture**: Moved from pure HashMap to hybrid Hash/BTree backend
- **Query engine**: Replaced generic parser with custom ReedQL implementation
- **Error handling**: More specific error variants with detailed context

### Performance
- **Single key lookup**: 50-100 μs (10-20x faster than MySQL)
- **Namespace query**: 1-5 ms (10x faster than MySQL)
- **Range query**: 2-5 ms (10-40x faster than MySQL)
- **Cold start**: 50-100 ms (10-20x faster than MySQL)
- **Concurrent reads**: 100-200 μs per request (5-50x faster than MySQL)

### Documentation
- Added `PERFORMANCE.md` with detailed benchmarks vs SQL databases
- Added `COMPETITORS.md` with comparison to LMDB, Sled, RocksDB, SQLite, Redis
- Added `ECOMMERCE_GAP_ANALYSIS.md` with transaction roadmap
- Updated API documentation with ReedQL examples

---

## [0.1.0] - 2024-12-XX

### Added

#### Core Database Operations
- **CSV-based storage**: Pipe-delimited CSV files in `.reed/` directory
- **Basic CRUD operations**: `get()`, `set()`, `delete()`
- **Language suffixes**: Native `@lang` support (`key@de`, `key@en`)
- **Environment suffixes**: Native `@env` support (`key@prod`, `key@dev`)
- **Fallback chains**: Automatic fallback from `@lang@env` → `@lang` → base key

#### Database Tables
- `text.csv`: Content texts with language variants
- `route.csv`: URL routing definitions
- `meta.csv`: SEO metadata (title, description, keywords)
- `server.csv`: Server configuration
- `project.csv`: Project settings

#### Performance Features
- **In-memory cache**: HashMap-based cache with RwLock for concurrent reads
- **Zero-copy reads**: Direct memory access for cached values
- **Batch operations**: Efficient multi-key operations

#### CLI (reedcli)
- `reed get <key>`: Retrieve value for key
- `reed set <key> <value>`: Store key-value pair
- `reed list`: List all keys in database
- `reed server:start`: Start HTTP server

#### HTTP Server (reedserver)
- REST API for database operations
- GET `/get?key=<key>`: Retrieve value
- POST `/set`: Store key-value pair
- Health check endpoint
- CORS support

### Initial Performance
- Single key lookup: 50-100 μs (in-memory cache)
- CSV read: 5-10 ms (10,000 keys)
- CSV write: 10-20 ms (atomic write via temp file)

### Documentation
- Basic README with installation instructions
- API documentation for core operations
- CLI usage examples

---

## Version Numbering

ReedBase follows [Semantic Versioning](https://semver.org/):

- **Major version** (x.0.0): Breaking API changes
- **Minor version** (0.x.0): New features, backward-compatible
- **Patch version** (0.0.x): Bug fixes, backward-compatible

### Beta Versions
- **v0.x.x-beta**: Beta releases (feature-complete but not production-tested)
- **v0.x.x-rc1**: Release candidates (production testing phase)
- **v1.0.0**: First production-ready release (with ACID transactions)

---

## Upgrade Guide

### From v0.1.0 to v0.2.0-beta

**Database Format:**
- ✅ **Backward compatible**: v0.1.0 databases work with v0.2.0
- ✅ **No migration needed**: CSV format unchanged
- ✅ **New files**: `.reed/indices/` directory created for persistent indices

**API Changes:**
- ✅ **No breaking changes**: All v0.1.0 APIs work in v0.2.0
- ✅ **New APIs**: `query()` method for ReedQL queries
- ✅ **Enhanced APIs**: `get()` now supports index-accelerated lookups

**Performance:**
- ✅ **100-1000x faster queries** with smart indices
- ✅ **Automatic optimization**: Indices created based on query patterns
- ✅ **Cold start < 100ms**: Persistent B+-Tree indices via mmap

**Migration Steps:**
1. Update `Cargo.toml`: `reedbase = "0.2.0-beta"`
2. Rebuild project: `cargo build`
3. First run: Indices auto-created on startup (< 100ms)
4. No code changes needed

---

## Future Breaking Changes

### v1.0.0 (Q4 2025)

**Planned Breaking Changes:**
- Transaction API: `db.begin_transaction()` returns new type
- Error types: Additional `ReedError` variants for transactions
- Configuration: New `DatabaseConfig` options for WAL/transactions

**Migration Path:**
- Deprecation warnings in v0.9.0 (Q3 2025)
- Migration guide published with v1.0.0-rc1
- Automated migration tool provided

---

## Links

- **Repository**: https://github.com/vvoss-dev/reedbase
- **Documentation**: [README.md](README.md)
- **Performance**: [PERFORMANCE.md](PERFORMANCE.md)
- **Roadmap**: [ECOMMERCE_GAP_ANALYSIS.md](ECOMMERCE_GAP_ANALYSIS.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

[Unreleased]: https://github.com/vvoss-dev/reedbase/compare/v0.2.0-beta...HEAD
[0.2.0-beta]: https://github.com/vvoss-dev/reedbase/compare/v0.1.0...v0.2.0-beta
[0.1.0]: https://github.com/vvoss-dev/reedbase/releases/tag/v0.1.0
