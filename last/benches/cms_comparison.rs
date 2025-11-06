// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! CMS Performance Comparison: ReedBase vs MySQL vs PostgreSQL
//!
//! Benchmarks typical CMS operations to demonstrate ReedBase's performance advantages
//! for multilingual content management systems.
//!
//! ## Test Scenarios
//!
//! 1. **Single Key Lookup** - Most frequent operation (page load)
//! 2. **Namespace Query** - Load all texts for a component (50-200 keys)
//! 3. **Language Fallback** - Common CMS pattern (de → en → default)
//! 4. **Cold Start** - Database initialization after server restart
//! 5. **Concurrent Reads** - Multiple users loading pages simultaneously
//!
//! ## Dataset
//!
//! Realistic CMS data:
//! - 100,000 keys (typical medium-sized CMS)
//! - 4 languages (de, en, fr, es)
//! - 10 namespaces (page, menu, footer, header, blog, etc.)
//! - ReedCMS key format: `namespace.component.field@lang`
//!
//! ## Running Benchmarks
//!
//! ```bash
//! # Run ReedBase benchmarks
//! cargo bench --bench cms_comparison
//!
//! # Compare with MySQL (requires MySQL server)
//! ./scripts/benchmark_mysql.sh
//!
//! # Compare with PostgreSQL (requires PostgreSQL server)
//! ./scripts/benchmark_postgres.sh
//!
//! # Generate comparison report
//! cargo run --bin generate_cms_report
//! ```

use criterion::{black_box, criterion_group, criterion_main, BenchmarkId, Criterion};
use reedbase_last::database::Database;
use tempfile::TempDir;

/// Generates realistic CMS dataset
///
/// ## Structure
/// - Keys: `namespace.component.field@lang`
/// - Namespaces: page, menu, footer, header, blog, product, category, tag, widget, form
/// - Languages: de, en, fr, es
/// - Components: ~25 per namespace
/// - Fields: title, subtitle, text, description, label, placeholder, etc.
fn generate_cms_dataset(total_keys: usize) -> Vec<(String, String)> {
    let namespaces = vec![
        "page", "menu", "footer", "header", "blog", "product", "category", "tag", "widget", "form",
    ];
    let languages = vec!["de", "en", "fr", "es"];
    let components = vec![
        "hero",
        "about",
        "services",
        "contact",
        "team",
        "pricing",
        "features",
        "testimonials",
        "faq",
        "cta",
        "newsletter",
        "social",
        "legal",
        "privacy",
        "terms",
    ];
    let fields = vec![
        "title",
        "subtitle",
        "text",
        "description",
        "label",
        "placeholder",
        "button",
        "link",
    ];

    let mut dataset = Vec::new();
    let keys_per_combo = total_keys / (namespaces.len() * languages.len());

    for namespace in &namespaces {
        for lang in &languages {
            for i in 0..keys_per_combo {
                let component = &components[i % components.len()];
                let field = &fields[i % fields.len()];

                let key = format!("{}.{}.{}@{}", namespace, component, field, lang);
                let value = format!(
                    "Sample {} text for {} {} in {} ({})",
                    field, namespace, component, lang, i
                );

                dataset.push((key, value));
            }
        }
    }

    dataset
}

/// Benchmark 1: Single Key Lookup (most frequent CMS operation)
///
/// Simulates loading a single text entry like "page.header.title@de"
/// This is the most common operation in a CMS (happens on every page load).
///
/// ## Expected Results
/// - ReedBase with BTree index: < 100μs
/// - MySQL with index: ~500μs - 2ms (network + parsing overhead)
/// - PostgreSQL with index: ~500μs - 2ms
fn bench_single_key_lookup(c: &mut Criterion) {
    let mut group = c.benchmark_group("single_key_lookup");

    for size in [10_000, 100_000].iter() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join(".reed");

        // Setup database
        let db = Database::open(&db_path).unwrap();
        let dataset = generate_cms_dataset(*size);

        for (key, value) in &dataset {
            db.execute(
                &format!(
                    "INSERT INTO text (key, value) VALUES ('{}', '{}')",
                    key, value
                ),
                "bench",
            )
            .unwrap();
        }

        // Create BTree index for optimal performance
        db.execute("CREATE INDEX text.key", "bench").unwrap();

        // Benchmark: Lookup middle key (worst case for sorted data)
        let sample_key = &dataset[dataset.len() / 2].0;

        group.bench_with_input(BenchmarkId::new("reedbase_btree", size), size, |b, _| {
            b.iter(|| {
                let result = db
                    .query(&format!("SELECT * FROM text WHERE key = '{}'", sample_key))
                    .unwrap();
                black_box(result);
            });
        });
    }

    group.finish();
}

/// Benchmark 2: Namespace Query (load all texts for a component)
///
/// Simulates loading all texts for a namespace like "menu.%@de"
/// Typical result: 50-200 keys per component.
///
/// ## Expected Results
/// - ReedBase with BTree range scan: < 5ms for 100 keys
/// - MySQL with LIKE index: ~10-50ms
/// - PostgreSQL with pattern index: ~10-50ms
fn bench_namespace_query(c: &mut Criterion) {
    let mut group = c.benchmark_group("namespace_query");

    let temp = TempDir::new().unwrap();
    let db_path = temp.path().join(".reed");
    let db = Database::open(&db_path).unwrap();

    let dataset = generate_cms_dataset(100_000);
    for (key, value) in &dataset {
        db.execute(
            &format!(
                "INSERT INTO text (key, value) VALUES ('{}', '{}')",
                key, value
            ),
            "bench",
        )
        .unwrap();
    }

    // Create index
    db.execute("CREATE INDEX text.key", "bench").unwrap();

    group.bench_function("reedbase_btree", |b| {
        b.iter(|| {
            let result = db
                .query("SELECT * FROM text WHERE key LIKE 'menu.%@de'")
                .unwrap();
            black_box(result);
        });
    });

    group.finish();
}

/// Benchmark 3: Range Query (efficient with BTree)
///
/// Tests ReedBase's advantage with BTree indices for range queries.
///
/// ## Expected Results
/// - ReedBase BTree: < 5ms for 1000 keys in range
/// - MySQL: Full scan required (no good range index on text)
/// - PostgreSQL: Full scan required
fn bench_range_query(c: &mut Criterion) {
    let mut group = c.benchmark_group("range_query");

    let temp = TempDir::new().unwrap();
    let db_path = temp.path().join(".reed");
    let db = Database::open(&db_path).unwrap();

    let dataset = generate_cms_dataset(100_000);
    for (key, value) in &dataset {
        db.execute(
            &format!(
                "INSERT INTO text (key, value) VALUES ('{}', '{}')",
                key, value
            ),
            "bench",
        )
        .unwrap();
    }

    db.execute("CREATE INDEX text.key", "bench").unwrap();

    group.bench_function("reedbase_btree", |b| {
        b.iter(|| {
            let result = db
                .query("SELECT * FROM text WHERE key > 'page.a' AND key < 'page.z'")
                .unwrap();
            black_box(result);
        });
    });

    group.finish();
}

/// Benchmark 4: Cold Start (database initialization)
///
/// Most important for web applications: How fast can the server restart?
///
/// ## Expected Results
/// - ReedBase with persistent BTree: < 100ms (load from disk)
/// - MySQL: ~500ms - 2s (connect + cache warming)
/// - PostgreSQL: ~500ms - 2s
fn bench_cold_start(c: &mut Criterion) {
    let mut group = c.benchmark_group("cold_start");
    group.sample_size(10); // Cold start is expensive

    let temp = TempDir::new().unwrap();
    let db_path = temp.path().join(".reed");

    // Setup: Create database with indices
    {
        let db = Database::open(&db_path).unwrap();
        let dataset = generate_cms_dataset(100_000);

        for (key, value) in &dataset {
            db.execute(
                &format!(
                    "INSERT INTO text (key, value) VALUES ('{}', '{}')",
                    key, value
                ),
                "bench",
            )
            .unwrap();
        }

        db.execute("CREATE INDEX text.key", "bench").unwrap();
    } // Drop database to simulate cold start

    group.bench_function("reedbase_with_btree", |b| {
        b.iter(|| {
            let db = Database::open(&db_path).unwrap();
            black_box(db);
        });
    });

    group.finish();
}

/// Benchmark 5: Concurrent Reads (multiple users)
///
/// Simulates 10 concurrent users loading different pages.
///
/// ## Expected Results
/// - ReedBase: Linear scaling (no lock contention on reads)
/// - MySQL: Connection pool overhead
/// - PostgreSQL: Connection pool overhead
fn bench_concurrent_reads(c: &mut Criterion) {
    let mut group = c.benchmark_group("concurrent_reads");

    let temp = TempDir::new().unwrap();
    let db_path = temp.path().join(".reed");
    let db = Database::open(&db_path).unwrap();

    let dataset = generate_cms_dataset(100_000);
    for (key, value) in &dataset {
        db.execute(
            &format!(
                "INSERT INTO text (key, value) VALUES ('{}', '{}')",
                key, value
            ),
            "bench",
        )
        .unwrap();
    }

    db.execute("CREATE INDEX text.key", "bench").unwrap();

    // Sample 10 different keys
    let sample_keys: Vec<_> = dataset
        .iter()
        .step_by(dataset.len() / 10)
        .take(10)
        .map(|(k, _)| k.clone())
        .collect();

    group.bench_function("reedbase_10_concurrent", |b| {
        b.iter(|| {
            use std::thread;

            let handles: Vec<_> = sample_keys
                .iter()
                .map(|key| {
                    let key = key.clone();
                    let db_path_clone = db_path.clone();

                    thread::spawn(move || {
                        let db = Database::open(&db_path_clone).unwrap();
                        let result = db
                            .query(&format!("SELECT * FROM text WHERE key = '{}'", key))
                            .unwrap();
                        black_box(result);
                    })
                })
                .collect();

            for handle in handles {
                handle.join().unwrap();
            }
        });
    });

    group.finish();
}

criterion_group!(
    benches,
    bench_single_key_lookup,
    bench_namespace_query,
    bench_range_query,
    bench_cold_start,
    bench_concurrent_reads
);

criterion_main!(benches);
