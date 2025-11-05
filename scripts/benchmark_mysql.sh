#!/bin/bash
# Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
# SPDX-License-Identifier: Apache-2.0

# MySQL CMS Performance Benchmark
#
# Compares ReedBase against MySQL for typical CMS operations.
#
# Requirements:
# - MySQL 8.0+ installed
# - mysql client available
#
# Usage:
#   ./scripts/benchmark_mysql.sh

set -e

echo "==================================================================="
echo "MySQL CMS Performance Benchmark"
echo "==================================================================="
echo ""

# Configuration
DB_NAME="reedbase_benchmark"
DB_USER="root"
DB_PASS=""
DATASET_SIZE=100000

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Creating MySQL database${NC}"
mysql -u"$DB_USER" -p"$DB_PASS" <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE $DB_NAME;

-- CMS content table (traditional structure)
CREATE TABLE content (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    key_name VARCHAR(255) NOT NULL,
    lang VARCHAR(10) NOT NULL,
    value TEXT NOT NULL,
    namespace VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_key_lang (key_name, lang),
    INDEX idx_namespace_lang (namespace, lang),
    INDEX idx_key (key_name)
) ENGINE=InnoDB;

-- Alternative: Single key column (like ReedBase)
CREATE TABLE content_flat (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    key_full VARCHAR(255) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_key (key_full)
) ENGINE=InnoDB;
EOF

echo -e "${GREEN}✓ Database created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Generating CMS dataset ($DATASET_SIZE keys)${NC}"

# Generate SQL INSERT statements
python3 <<PYTHON
import random

namespaces = ['page', 'menu', 'footer', 'header', 'blog', 'product', 'category', 'tag', 'widget', 'form']
languages = ['de', 'en', 'fr', 'es']
components = ['hero', 'about', 'services', 'contact', 'team', 'pricing', 'features', 'testimonials', 'faq', 'cta']
fields = ['title', 'subtitle', 'text', 'description', 'label', 'placeholder', 'button', 'link']

dataset_size = $DATASET_SIZE
keys_per_combo = dataset_size // (len(namespaces) * len(languages))

print("-- Traditional structure")
print("INSERT INTO content (key_name, lang, value, namespace) VALUES")

values = []
for namespace in namespaces:
    for lang in languages:
        for i in range(keys_per_combo):
            component = components[i % len(components)]
            field = fields[i % len(fields)]
            key_name = f"{namespace}.{component}.{field}"
            value = f"Sample {field} text for {namespace} {component} in {lang} ({i})"
            values.append(f"('{key_name}', '{lang}', '{value}', '{namespace}')")

print(",\n".join(values[:100000]))  # MySQL has limits on bulk inserts
print(";")

print("\n-- Flat structure (ReedBase-style)")
print("INSERT INTO content_flat (key_full, value) VALUES")

values_flat = []
for namespace in namespaces:
    for lang in languages:
        for i in range(keys_per_combo):
            component = components[i % len(components)]
            field = fields[i % len(fields)]
            key_full = f"{namespace}.{component}.{field}@{lang}"
            value = f"Sample {field} text for {namespace} {component} in {lang} ({i})"
            values_flat.append(f"('{key_full}', '{value}')")

print(",\n".join(values_flat[:100000]))
print(";")
PYTHON > /tmp/mysql_dataset.sql

mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < /tmp/mysql_dataset.sql

echo -e "${GREEN}✓ Dataset loaded ($DATASET_SIZE keys)${NC}"
echo ""

echo -e "${YELLOW}Step 3: Running Benchmarks${NC}"
echo ""

# Benchmark 1: Single Key Lookup
echo "Benchmark 1: Single Key Lookup (traditional structure)"
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET profiling = 1;
SELECT * FROM content WHERE key_name = 'page.hero.title' AND lang = 'de' LIMIT 1;
SHOW PROFILES;
EOF

echo ""
echo "Benchmark 1: Single Key Lookup (flat structure - ReedBase style)"
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET profiling = 1;
SELECT * FROM content_flat WHERE key_full = 'page.hero.title@de' LIMIT 1;
SHOW PROFILES;
EOF

# Benchmark 2: Namespace Query
echo ""
echo "Benchmark 2: Namespace Query (load all menu texts in German)"
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET profiling = 1;
SELECT * FROM content WHERE namespace = 'menu' AND lang = 'de';
SHOW PROFILES;
EOF

echo ""
echo "Benchmark 2: Namespace Query (flat structure)"
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET profiling = 1;
SELECT * FROM content_flat WHERE key_full LIKE 'menu.%@de';
SHOW PROFILES;
EOF

# Benchmark 3: Range Query
echo ""
echo "Benchmark 3: Range Query"
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SET profiling = 1;
SELECT * FROM content_flat WHERE key_full > 'page.a' AND key_full < 'page.z';
SHOW PROFILES;
EOF

# Benchmark 4: Cold Start
echo ""
echo "Benchmark 4: Cold Start (connection time)"
time mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1;"

echo ""
echo -e "${GREEN}==================================================================="
echo "MySQL Benchmark Complete"
echo "===================================================================${NC}"
echo ""
echo "Compare results with:"
echo "  cargo bench --bench cms_comparison"
