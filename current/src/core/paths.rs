// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Path construction utilities for ReedBase.
//!
//! Centralised path management to ensure consistency across the codebase.

use std::path::{Path, PathBuf};

/// Returns the database directory path.
///
/// ## Arguments
/// - `base_path`: Base directory for the database
///
/// ## Returns
/// - Path to the database directory (.reedbase/)
///
/// ## Example
/// ```rust
/// use reedbase::core::paths::db_dir;
/// use std::path::Path;
///
/// let path = db_dir(Path::new("/project"));
/// assert_eq!(path, Path::new("/project/.reedbase"));
/// ```
pub fn db_dir(base_path: &Path) -> PathBuf {
    base_path.join(".reedbase")
}

/// Returns the path to a specific table file.
///
/// ## Arguments
/// - `base_path`: Base directory for the database
/// - `table_name`: Name of the table
///
/// ## Returns
/// - Path to the table CSV file
///
/// ## Example
/// ```rust
/// use reedbase::core::paths::table_path;
/// use std::path::Path;
///
/// let path = table_path(Path::new("/project"), "users");
/// assert_eq!(path, Path::new("/project/.reedbase/users.csv"));
/// ```
pub fn table_path(base_path: &Path, table_name: &str) -> PathBuf {
    db_dir(base_path).join(format!("{}.csv", table_name))
}

/// Returns the backup directory path.
///
/// ## Arguments
/// - `base_path`: Base directory for the database
///
/// ## Returns
/// - Path to the backups directory
///
/// ## Example
/// ```rust
/// use reedbase::core::paths::backup_dir;
/// use std::path::Path;
///
/// let path = backup_dir(Path::new("/project"));
/// assert_eq!(path, Path::new("/project/.reedbase/backups"));
/// ```
pub fn backup_dir(base_path: &Path) -> PathBuf {
    db_dir(base_path).join("backups")
}

/// Returns the Write-Ahead Log directory path.
///
/// ## Arguments
/// - `base_path`: Base directory for the database
///
/// ## Returns
/// - Path to the WAL directory
///
/// ## Example
/// ```rust
/// use reedbase::core::paths::wal_dir;
/// use std::path::Path;
///
/// let path = wal_dir(Path::new("/project"));
/// assert_eq!(path, Path::new("/project/.reedbase/wal"));
/// ```
pub fn wal_dir(base_path: &Path) -> PathBuf {
    db_dir(base_path).join("wal")
}
