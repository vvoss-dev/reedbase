# Contributing to ReedBase

Thank you for your interest in contributing to ReedBase! This document provides guidelines and standards for contributions.

---

## Code of Conduct

ReedBase follows a professional and respectful code of conduct:

- Be respectful and constructive in discussions
- Focus on technical merit and facts
- Welcome newcomers and provide helpful feedback
- Acknowledge different perspectives and use cases

---

## Getting Started

### Prerequisites

- Rust 1.82 or later
- Git
- Familiarity with embedded databases (optional but helpful)

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/vvoss-dev/reedbase.git
cd reedbase

# Build the project
cargo build

# Run tests
cargo test

# Run benchmarks
cargo bench
```

---

## Development Standards

ReedBase follows strict code standards to maintain quality and consistency.

### Language

**All code documentation and comments MUST be written in BBC English.**

```rust
// ✅ CORRECT: BBC English
/// Retrieves the value for the given key with language fallback.
///
/// ## Behaviour
/// If the key with language suffix is not found, falls back to base key.

// ❌ WRONG: American English
/// Retrieves the value for the given key with language fallback.
///
/// ## Behavior
/// If the key with language suffix is not found, falls back to base key.
```

### Code Principles

**KISS Principle (Keep It Simple, Stupid)**

- One file = one clear responsibility
- One function = one distinctive job
- Avoid "Swiss Army knife" functions
- Prefer explicit over clever code

**Examples:**

```rust
// ✅ GOOD: One function, one job
pub fn validate_key(key: &str) -> ReedResult<()> {
    if key.is_empty() {
        return Err(ReedError::EmptyKey);
    }
    if key.len() > 255 {
        return Err(ReedError::KeyTooLong { max: 255 });
    }
    Ok(())
}

// ❌ BAD: Swiss Army knife function
pub fn validate_and_process_key(key: &str, normalize: bool, cache: bool) -> ReedResult<String> {
    // Validation + normalization + caching = too many responsibilities
}
```

### File Organisation

```
src/reedbase/
├── module_name/
│   ├── specific_feature.rs      # One feature per file
│   ├── specific_feature_test.rs # Separate test file
│   └── another_feature.rs
```

**Avoid generic names:**
- ❌ `handler.rs`, `middleware.rs`, `utils.rs`
- ✅ `get.rs`, `set.rs`, `delete.rs`

### Testing

**Test files MUST be separate** (not inline `#[cfg(test)]` modules):

```rust
// src/database/get.rs
pub fn get(db: &Database, key: &str) -> ReedResult<String> {
    // Implementation
}

// src/database/get_test.rs
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_get_existing_key() {
        // Test implementation
    }
}
```

### Error Handling

**Always use `ReedResult<T>` and specific `ReedError` variants:**

```rust
// ✅ GOOD: Specific error with context
pub fn get(key: &str) -> ReedResult<String> {
    let value = cache.get(key)
        .ok_or_else(|| ReedError::KeyNotFound {
            key: key.to_string(),
            source: "cache",
        })?;
    Ok(value)
}

// ❌ BAD: Generic error
pub fn get(key: &str) -> Result<String, String> {
    let value = cache.get(key)
        .ok_or("Key not found")?;
    Ok(value)
}
```

### Documentation

**Every public function MUST have documentation:**

```rust
/// Brief one-line description.
///
/// ## Input
/// - `key`: Description of parameter
/// - `value`: Description of parameter
///
/// ## Output
/// - Description of return value
///
/// ## Performance
/// - O(1) operation
/// - < 100μs typical
///
/// ## Error Conditions
/// - `ReedError::EmptyKey`: If key is empty
/// - `ReedError::KeyTooLong`: If key exceeds 255 characters
///
/// ## Example Usage
/// ```rust
/// let result = db.set("page.title@en", "Welcome")?;
/// ```
pub fn set(key: &str, value: &str) -> ReedResult<()> {
    // Implementation
}
```

### License Headers

**Every source file MUST start with license header:**

```rust
// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

// Rest of the file...
```

---

## Contribution Workflow

### 1. Find or Create an Issue

- Check existing issues first
- For bugs: Provide minimal reproduction case
- For features: Discuss approach before implementing
- Label appropriately: `bug`, `enhancement`, `documentation`, etc.

### 2. Fork and Branch

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/reedbase.git
cd reedbase

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

### 3. Make Changes

- Follow code standards above
- Write tests for new functionality
- Update documentation if needed
- Keep commits focused and atomic

### 4. Test Your Changes

```bash
# Run all tests
cargo test

# Run specific test
cargo test test_name

# Run benchmarks (if performance-critical)
cargo bench

# Check formatting
cargo fmt --check

# Check for warnings
cargo clippy
```

### 5. Commit Guidelines

**Commit message format:**

```
[COMPONENT] type: short description

Optional longer description with details.
Can span multiple lines.

- Bullet points for changes
- More details if needed

Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `perf`: Performance improvements
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

**Examples:**

```
[DATABASE] feat: add compare-and-swap (CAS) operation

Implements atomic compare-and-swap for concurrent updates.
Uses version-based optimistic locking.

- Add `compare_and_swap()` method
- Add version tracking per key
- Add tests for concurrent CAS

Fixes #45
```

```
[QUERY] fix: correct LIKE query with multiple wildcards

Fixed parser to handle patterns like 'menu.%.%@de'.
Previously only single wildcard was supported.

Fixes #78
```

### 6. Submit Pull Request

- Push to your fork
- Create PR on GitHub
- Fill out PR template
- Link related issues
- Wait for review

**PR title format:**
```
[COMPONENT] Brief description (fixes #issue)
```

---

## Review Process

### What We Look For

- ✅ Code follows style guidelines
- ✅ Tests pass (CI/CD)
- ✅ Documentation updated
- ✅ No performance regressions
- ✅ Error handling is robust

### Response Time

- Initial review: Within 3-5 days
- Follow-up reviews: Within 1-2 days
- Merging: After all feedback addressed

---

## Areas for Contribution

### High Priority

- 🔴 **Transaction Support** (REED-20 series)
  - Write-Ahead Log (WAL) implementation
  - Atomic batch operations
  - Compare-and-swap (CAS)
  - ACID transactions

- 🟡 **Performance Optimizations**
  - Index optimization
  - Query planner improvements
  - Memory usage reduction

- 🟢 **Documentation**
  - Use case examples
  - Tutorial articles
  - API documentation

### Medium Priority

- **Testing**
  - Increase test coverage
  - Stress testing
  - Concurrent access testing

- **Tooling**
  - CLI improvements
  - Debugging tools
  - Monitoring/metrics

### Good First Issues

Issues labeled `good first issue` are suitable for newcomers:
- Documentation improvements
- Test additions
- Error message clarity
- Example code

---

## Beta Testers

### How to Become a Beta Tester

1. Open an issue with label "Beta Tester"
2. Describe your use case:
   - What are you building?
   - What features do you need?
   - What's your expected load?
3. Report bugs, performance issues, API feedback

### What We Expect

- Regular feedback (weekly or bi-weekly)
- Bug reports with reproduction steps
- Performance testing results
- API usability feedback

### What You Get

- Early access to new features
- Direct input on API design
- Credit in v1.0.0 release notes
- Potential speaking/writing opportunities

---

## Performance Benchmarks

### Running Benchmarks

```bash
# Run all benchmarks
cargo bench

# Run specific benchmark
cargo bench --bench cms_comparison

# Generate comparison report
cargo run --bin generate_cms_report
```

### Adding Benchmarks

Place benchmarks in `benches/`:

```rust
// benches/my_benchmark.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use reedbase::Database;

fn bench_my_feature(c: &mut Criterion) {
    let db = Database::open(".reed").unwrap();
    
    c.bench_function("my_feature", |b| {
        b.iter(|| {
            // Benchmark code
            black_box(db.get("key"));
        });
    });
}

criterion_group!(benches, bench_my_feature);
criterion_main!(benches);
```

---

## Questions?

- 💬 Open a discussion on GitHub
- 📧 Email: ask@vvoss.dev
- 🐦 Twitter: (if applicable)

---

## License

By contributing to ReedBase, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing to ReedBase! 🎉
