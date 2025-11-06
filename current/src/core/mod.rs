// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Core utilities for ReedBase.
//!
//! This module provides foundational functionality used across all other modules:
//! - Path construction and management
//! - Input validation
//! - Common type definitions
//!
//! All modules should use these utilities to avoid duplication and ensure consistency.

pub mod paths;
pub mod validation;

// Test modules (separate files as per CLAUDE.md Standard #5)
#[cfg(test)]
#[path = "paths_test.rs"]
mod paths_test;

#[cfg(test)]
#[path = "validation_test.rs"]
mod validation_test;

// Re-exports for convenience
pub use paths::{backup_dir, db_dir, table_path, wal_dir};
pub use validation::{validate_key, validate_table_name};
