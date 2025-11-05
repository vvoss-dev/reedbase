# .workbench - Development Workspace

This directory contains all development-related files that are not needed by end users of ReedBase.

## Structure

```
.workbench/
├── README.md                   # This file
│
├── docs/                       # Development documentation
│   ├── PERFORMANCE.md          # Benchmarks & methodology
│   ├── COMPETITORS.md          # Database comparisons
│   ├── ECOMMERCE_GAP_ANALYSIS.md  # Transaction roadmap
│   ├── IMPLEMENTATION-STATUS.md   # Feature completion tracking
│   └── STATUS.md               # Development status
│
├── tests/                      # Integration tests
│   ├── cli_test.rs
│   ├── concurrency_test.rs
│   ├── correctness_test.rs
│   ├── database_api_test.rs
│   ├── error_handling_test.rs
│   ├── performance_test.rs
│   └── test_utils.rs
│
└── test_data/                  # Test fixtures
    ├── small/
    ├── medium/
    ├── large/
    └── versioned/
```

## Running Tests

```bash
# Run all integration tests
cargo test

# Run specific test
cargo test --test database_api_test

# Run with output
cargo test -- --nocapture
```

## Test Data

Test fixtures in `test_data/` are used for:
- Performance benchmarking
- Integration testing
- Stress testing
- Version control testing

Generated via `cargo run --bin generate_fixtures`.

## Development Documentation

Development docs in `docs/`:
- **PERFORMANCE.md**: Benchmarks vs MySQL/PostgreSQL/SQLite (methodology, reproducible tests)
- **COMPETITORS.md**: Detailed comparison with LMDB, Sled, RocksDB, Redis, TiKV
- **ECOMMERCE_GAP_ANALYSIS.md**: Transaction features roadmap (REED-20 series)
- **IMPLEMENTATION-STATUS.md**: Feature completion tracking
- **STATUS.md**: Current development status and notes

## Why .workbench?

Following the pattern of `.github/`, `.cargo/`, etc., `.workbench/` keeps development files organized and separate from user-facing code. This makes it clear what's intended for contributors vs. end users.

**User-facing stays in root:**
- `README.md` - Main documentation with Quick Start
- `CHANGELOG.md` - Version history (what's new?)
- `CONTRIBUTING.md` - How to contribute

**Developer workspace goes here:**
- Performance benchmarks & comparisons
- Technical roadmaps & gap analysis
- Integration tests
- Test fixtures
- Internal development docs

---

For general contribution guidelines, see [../CONTRIBUTING.md](../CONTRIBUTING.md).
