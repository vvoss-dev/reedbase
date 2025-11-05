#!/bin/bash
# Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
# SPDX-License-Identifier: Apache-2.0

# PostgreSQL CMS Performance Benchmark
#
# Compares ReedBase against PostgreSQL for typical CMS operations.
#
# Requirements:
# - PostgreSQL 14+ installed
# - psql client available
#
# Usage:
#   ./scripts/benchmark_postgres.sh

set -e

echo "==================================================================="
echo "PostgreSQL CMS Performance Benchmark"
echo "==================================================================="
echo ""

# Configuration
DB_NAME="reedbase_benchmark"
DB_USER="postgres"
DATASET_SIZE=100000

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Creating PostgreSQL database${NC}"
psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"

psql -U "$DB_USER" -d "$DB_NAME" <<EOF
-- CMS content table (traditional structure)
CREATE TABLE content (
    id BIGSERIAL PRIMARY KEY,
    key_name VARCHAR(255) NOT NULL,
    lang VARCHAR(10) NOT NULL,
    value TEXT NOT NULL,
    namespace VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_key_lang ON content(key_name, lang);
CREATE INDEX idx_namespace_lang ON content(namespace, lang);
CREATE INDEX idx_key ON content(key_name);

-- Alternative: Single key column (like ReedBase)
CREATE TABLE content_flat (
    id BIGSERIAL PRIMARY KEY,
    key_full VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_key_full ON content_flat(key_full);
CREATE INDEX idx_key_pattern ON content_flat(key_full text_pattern_ops);
EOF

echo -e "${GREEN}✓ Database created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Generating CMS dataset ($DATASET_SIZE keys)${NC}"

# Generate SQL INSERT statements
python3 <<PYTHON
namespaces = ['page', 'menu', 'footer', 'header', 'blog', 'product', 'category', 'tag', 'widget', 'form']
languages = ['de', 'en', 'fr', 'es']
components = ['hero', 'about', 'services', 'contact', 'team', 'pricing', 'features', 'testimonials', 'faq', 'cta']
fields = ['title', 'subtitle', 'text', 'description', 'label', 'placeholder', 'button', 'link']

dataset_size = $DATASET_SIZE
keys_per_combo = dataset_size // (len(namespaces) * len(languages))

print("-- Traditional structure")
for namespace in namespaces:
    for lang in languages:
        values = []
        for i in range(keys_per_combo):
            component = components[i % len(components)]
            field = fields[i % len(fields)]
            key_name = f"{namespace}.{component}.{field}"
            value = f"Sample {field} text for {namespace} {component} in {lang} ({i})"
            values.append(f"('{key_name}', '{lang}', '{value}', '{namespace}')")

        print(f"INSERT INTO content (key_name, lang, value, namespace) VALUES {','.join(values)};")

print("\n-- Flat structure (ReedBase-style)")
for namespace in namespaces:
    for lang in languages:
        values = []
        for i in range(keys_per_combo):
            component = components[i % len(components)]
            field = fields[i % len(fields)]
            key_full = f"{namespace}.{component}.{field}@{lang}"
            value = f"Sample {field} text for {namespace} {component} in {lang} ({i})"
            values.append(f"('{key_full}', '{value}')")

        print(f"INSERT INTO content_flat (key_full, value) VALUES {','.join(values)};")
PYTHON > /tmp/postgres_dataset.sql

psql -U "$DB_USER" -d "$DB_NAME" < /tmp/postgres_dataset.sql

# Analyze tables for optimal query plans
psql -U "$DB_USER" -d "$DB_NAME" -c "ANALYZE content;"
psql -U "$DB_USER" -d "$DB_NAME" -c "ANALYZE content_flat;"

echo -e "${GREEN}✓ Dataset loaded ($DATASET_SIZE keys)${NC}"
echo ""

echo -e "${YELLOW}Step 3: Running Benchmarks${NC}"
echo ""

# Benchmark 1: Single Key Lookup
echo "Benchmark 1: Single Key Lookup (traditional structure)"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
\timing on
SELECT * FROM content WHERE key_name = 'page.hero.title' AND lang = 'de' LIMIT 1;
EXPLAIN ANALYZE SELECT * FROM content WHERE key_name = 'page.hero.title' AND lang = 'de' LIMIT 1;
EOF

echo ""
echo "Benchmark 1: Single Key Lookup (flat structure - ReedBase style)"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
\timing on
SELECT * FROM content_flat WHERE key_full = 'page.hero.title@de' LIMIT 1;
EXPLAIN ANALYZE SELECT * FROM content_flat WHERE key_full = 'page.hero.title@de' LIMIT 1;
EOF

# Benchmark 2: Namespace Query
echo ""
echo "Benchmark 2: Namespace Query (load all menu texts in German)"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
\timing on
SELECT * FROM content WHERE namespace = 'menu' AND lang = 'de';
EXPLAIN ANALYZE SELECT * FROM content WHERE namespace = 'menu' AND lang = 'de';
EOF

echo ""
echo "Benchmark 2: Namespace Query (flat structure)"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
\timing on
SELECT * FROM content_flat WHERE key_full LIKE 'menu.%@de';
EXPLAIN ANALYZE SELECT * FROM content_flat WHERE key_full LIKE 'menu.%@de';
EOF

# Benchmark 3: Range Query
echo ""
echo "Benchmark 3: Range Query"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
\timing on
SELECT * FROM content_flat WHERE key_full > 'page.a' AND key_full < 'page.z';
EXPLAIN ANALYZE SELECT * FROM content_flat WHERE key_full > 'page.a' AND key_full < 'page.z';
EOF

# Benchmark 4: Cold Start
echo ""
echo "Benchmark 4: Cold Start (connection time)"
time psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;"

# Benchmark 5: Database Size
echo ""
echo "Database Size Comparison:"
psql -U "$DB_USER" -d "$DB_NAME" <<EOF
SELECT
    pg_size_pretty(pg_total_relation_size('content')) as traditional_size,
    pg_size_pretty(pg_total_relation_size('content_flat')) as flat_size;
EOF

echo ""
echo -e "${GREEN}==================================================================="
echo "PostgreSQL Benchmark Complete"
echo "===================================================================${NC}"
echo ""
echo "Compare results with:"
echo "  cargo bench --bench cms_comparison"
