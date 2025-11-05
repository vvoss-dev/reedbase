# ReedBase

> The CMS-native database with global and project-local modes. 10-100x faster than MySQL for multilingual content.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/rust-1.82+-orange.svg)](https://www.rust-lang.org/)
[![Status](https://img.shields.io/badge/status-beta-yellow.svg)](CHANGELOG.md)

---

## Beta Software

**ReedBase v0.2.0 is beta software.**

✅ **Production-ready for:** CMS content, configuration management, serverless APIs  
❌ **Not yet ready:** E-commerce transactions (ACID coming Q4 2025)

See [.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md](.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md) for roadmap.

---

## Why ReedBase?

**The Problem:**

MySQL is 10-100x too slow for multilingual CMS content lookups. Every page load queries the database 50-100 times for UI texts, menu items, translations, etc.

**The Solution:**

ReedBase is the first database with native `@lang` and `@env` suffixes, supporting both global (system-wide) and local (project-specific) deployment:

```rust
use reedbase::Database;

let db = Database::open(".reed")?;

// Set multilingual text
db.set("page.header.title@de", "Willkommen")?;
db.set("page.header.title@en", "Welcome")?;

// Get with automatic fallback
let title = db.get("page.header.title@de@prod")?;
// Fallback chain: @de@prod → @de@dev → @de → base key
// Time: 50-100 μs (vs MySQL: 500-2,000 μs)
```

No other embedded database offers this natively.

---

## Performance

| Operation | ReedBase | MySQL | PostgreSQL | SQLite | Speedup |
|-----------|----------|-------|------------|--------|---------|
| Single key lookup | 50-100 μs | 500-2,000 μs | 500-2,000 μs | 200-500 μs | 10-20x |
| Namespace query | 1-5 ms | 10-50 ms | 10-50 ms | 10-50 ms | 10x |
| Range query | 2-5 ms | 50-200 ms | 50-200 ms | 10-50 ms | 10-40x |
| Cold start | 50-100 ms | 500-2,000 ms | 500-2,000 ms | 50-100 ms | 10-20x |
| Concurrent reads | 100-200 μs | 1-5 ms | 1-5 ms | 500-1,000 μs | 5-50x |

See [.workbench/docs/PERFORMANCE.md](.workbench/docs/PERFORMANCE.md) for detailed benchmarks and methodology.

---

## Features

### CMS-Native Design

✅ **Native `@lang` suffixes**: `menu.title@de`, `menu.title@en`, `menu.title@fr`  
✅ **Native `@env` suffixes**: `config.api.url@prod`, `config.api.url@dev`  
✅ **Automatic fallback chains**: `@de@prod` → `@de@dev` → `@de` → base key  
✅ **Namespace queries**: `SELECT * WHERE key LIKE 'menu.%@de'`

### SQL-Like Syntax (ReedQL)

```rust
// Familiar CRUD operations
db.query("SELECT * WHERE key = 'page.title@en'")?;
db.query("SELECT * WHERE key LIKE 'menu.%@de'")?;
db.query("INSERT INTO text (key, value) VALUES ('page.title@de', 'Startseite')")?;
db.query("UPDATE text SET value = 'Home' WHERE key = 'page.title@en'")?;
db.query("DELETE FROM text WHERE key = 'old.key@de'")?;
```

### Smart Indices

✅ **Automatic backend selection**: Hash (O(1)) for exact matches, B+-Tree (O(log n)) for ranges  
✅ **Persistent B+-Tree indices**: Less than 100ms cold start via mmap  
✅ **Zero DBA overhead**: Indices optimise themselves based on query patterns

### Deployment Modes

✅ **Global mode**: System-wide database (`~/.reedbase/databases/`) accessible from anywhere  
✅ **Local mode**: Project-specific database (`./.reedbase`) embedded in project directory  
✅ **Name-based access**: Reference databases by name, not path  
✅ **Registry management**: Central registry (`~/.reedbase/registry.toml`) for all databases

### Performance

✅ **Zero network overhead**: Direct file access (no TCP/IP round-trips)  
✅ **Crash recovery**: CRC32-validated delta reconstruction  
✅ **Concurrent reads**: RwLock allows unlimited readers  
✅ **Serverless-ready**: Fits in AWS Lambda, Cloudflare Workers, Vercel Edge

---

## Quick Start

### Installation

Add to `Cargo.toml`:

```toml
[dependencies]
reedbase = "0.2.0-beta"
```

### Basic Usage

#### Local Mode (Project-Specific)

```rust
use reedbase::{Database, ReedResult};

fn main() -> ReedResult<()> {
    // Open local database in current project
    let db = Database::open(".reed")?;
    
    // Store multilingual content
    db.set("welcome.message@en", "Welcome to our site!")?;
    db.set("welcome.message@de", "Willkommen auf unserer Seite!")?;
    db.set("welcome.message@fr", "Bienvenue sur notre site!")?;
    
    // Retrieve with language
    let message_en = db.get("welcome.message@en")?;
    let message_de = db.get("welcome.message@de")?;
    
    // Query namespace (load all texts for a component)
    let all_welcome = db.query("SELECT * WHERE key LIKE 'welcome.%@en'")?;
    
    println!("English: {}", message_en);
    println!("German: {}", message_de);
    println!("Found {} welcome messages", all_welcome.len());
    
    Ok(())
}
```

#### Global Mode (System-Wide)

```rust
use reedbase::{Database, Registry};

fn main() {
    // List registered databases
    let registry = Registry::load().unwrap();
    
    for db in registry.databases() {
        println!("{}: {} ({})", 
            db.name, 
            db.location.display(),
            if db.mode == DatabaseMode::Global { "global" } else { "local" }
        );
    }
    
    // Access global database by name
    let db_path = registry.resolve("users_prod").unwrap();
    let db = Database::open(&db_path).unwrap();
    
    // Query from anywhere on the system
    let users = db.query("SELECT * FROM users WHERE active = true")?;
}
```

```bash
# CLI: Create and use global database
rdb db:init users_prod --global
rdb db:query users_prod "SELECT * FROM users"

# CLI: Create and use local database
cd /path/to/project
rdb db:init my_project_dev --local
rdb db:query my_project_dev "SELECT * FROM config"
```

### Environment-Aware Configuration

```rust
// Production vs development configuration
db.set("api.url@prod", "https://api.example.com")?;
db.set("api.url@dev", "http://localhost:3000")?;

// Get with environment fallback
let api_url = db.get("api.url@prod")?;
// If @prod not found, falls back to @dev, then base key
```

---

## Use Cases

### Production-Ready Today (v0.2.0-beta)

**WordPress/Drupal Plugins**
```rust
// Translation caching - 50-200x faster than wp_options
let translations = db.query("SELECT * WHERE key LIKE '%@de'")?;
// Time: 5-10ms one-time cost for 10,000+ keys
// Then: In-memory HashMap with less than 1μs lookups
```

**Serverless APIs (AWS Lambda, Cloudflare Workers)**
```rust
// Fast cold start (less than 100ms) - no RDS connection needed
lazy_static! {
    static ref DB: Database = Database::open("/tmp/.reed").unwrap();
}

pub async fn handler(event: Request) -> Response {
    let text = DB.get(&format!("content.{}@{}", event.page, event.lang))?;
    Ok(Response::new(text))
}
```

**Static Site Generators (Hugo, Jekyll, Eleventy)**
```rust
// Build-time data source - 10-100x faster than JSON parsing
let translations = db.query("SELECT * WHERE key LIKE 'ui.%@de'")?;
// Time: 5-10ms for 10,000+ keys (vs 100-500ms for JSON files)
```

**Headless CMS (Strapi, Directus, KeystoneJS)**
```rust
// Content delivery API - 10-100x faster than PostgreSQL
GET /api/content/page.header@de
// ReedBase: 50-100μs (vs PostgreSQL: 10-50ms)
```

### Coming Q4 2025 (with ACID Transactions)

❌ E-commerce inventory management (atomic stock updates)  
❌ Shopping cart checkout (transactional order processing)  
❌ Coupon redemption (compare-and-swap operations)  
❌ Flash sales (atomic counter decrements)

See [.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md](.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md) for transaction roadmap.

---

## Comparison with Alternatives

### vs SQL Databases (MySQL, PostgreSQL, SQLite)

| Feature | ReedBase | MySQL | PostgreSQL | SQLite |
|---------|----------|-------|------------|--------|
| CMS-native | ✅ @lang/@env | ❌ | ❌ | ❌ |
| SQL-like syntax | ✅ ReedQL | ✅ Full SQL | ✅ Full SQL | ✅ SQL subset |
| Architecture | Direct file access | Client-Server | Client-Server | Direct file access |
| Global registry | ✅ Name-based | ❌ Connection strings | ❌ Connection strings | ❌ Path-based |
| Local embedded | ✅ Per-project | ❌ | ❌ | ✅ Single file |
| Performance | 50-100 μs | 500-2000 μs | 500-2000 μs | 200-500 μs |
| JOINs | ❌ | ✅ | ✅ | ✅ |
| ACID | ❌ (Q4 2025) | ✅ | ✅ | ✅ |
| Serverless-ready | ✅ | ❌ | ❌ | ✅ |

### vs Embedded Key-Value Stores (LMDB, Sled, RocksDB)

| Feature | ReedBase | LMDB | Sled | RocksDB |
|---------|----------|------|------|---------|
| CMS-native | ✅ @lang/@env | ❌ | ❌ | ❌ |
| SQL-like syntax | ✅ ReedQL | ❌ C API | ❌ | ❌ |
| Performance | 50-100 μs | 50-100 μs | 50-200 μs | 100-500 μs |
| Rust-native | ✅ | ❌ C FFI | ✅ | ❌ C++ FFI |
| ACID | ❌ (Q4 2025) | ✅ MVCC | ✅ MVCC | ❌ |
| Smart indices | ✅ Auto | ❌ Manual | ❌ Manual | ❌ Manual |

See [.workbench/docs/COMPETITORS.md](.workbench/docs/COMPETITORS.md) for detailed comparison.

---

## Roadmap

✅ **v0.1.0** (2024 Q4): Basic key-value operations, CSV backend  
✅ **v0.2.0-beta** (2025 Q1): Smart indices, ReedQL parser, crash recovery  
❌ **v0.3.0** (2025 Q2): Write-Ahead Log (WAL) and full crash recovery  
❌ **v0.4.0** (2025 Q3): Atomic batch operations, compare-and-swap (CAS)  
❌ **v1.0.0** (2025 Q4): ACID transactions (BEGIN/COMMIT/ROLLBACK)

See [.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md](.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md) for detailed feature timeline.

---

## Documentation

**[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute  
**[CHANGELOG.md](CHANGELOG.md)** - Version history

### For Developers

**[.workbench/docs/PERFORMANCE.md](.workbench/docs/PERFORMANCE.md)** - Benchmarks vs MySQL/PostgreSQL/SQLite  
**[.workbench/docs/COMPETITORS.md](.workbench/docs/COMPETITORS.md)** - Comparison with LMDB, Sled, RocksDB, Redis  
**[.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md](.workbench/docs/ECOMMERCE_GAP_ANALYSIS.md)** - Transaction roadmap

---

## Contributing

ReedBase welcomes contributions. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Looking for Beta Testers

We are seeking early adopters to test ReedBase in real-world projects:

✅ WordPress/Drupal plugin developers (translation caching)  
✅ Serverless/edge computing users (Lambda, Cloudflare Workers)  
✅ Headless CMS developers (content delivery APIs)  
✅ Static site generator users (Hugo, Jekyll, Eleventy)

**How to help:**
1. Open an issue with the "Beta Tester" label
2. Describe your use case
3. Report bugs, performance issues, API feedback

Early testers will be credited in the v1.0.0 release.

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

---

## Author

**Vivian Voss**  
Email: ask@vvoss.dev  
GitHub: [@vvoss-dev](https://github.com/vvoss-dev)

---

## Acknowledgements

ReedBase was originally developed as part of [ReedCMS](https://github.com/vvoss-dev/reedcms), a high-performance CMS framework. It has been extracted as a standalone database to benefit the wider Rust and web development community.
