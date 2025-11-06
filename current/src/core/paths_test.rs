// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for path utilities.

#[cfg(test)]
mod tests {
    use super::super::paths::*;
    use std::path::Path;

    #[test]
    fn test_db_dir() {
        let base = Path::new("/project");
        let result = db_dir(base);
        assert_eq!(result, Path::new("/project/.reedbase"));
    }

    #[test]
    fn test_db_dir_with_trailing_slash() {
        let base = Path::new("/project/");
        let result = db_dir(base);
        assert_eq!(result, Path::new("/project/.reedbase"));
    }

    #[test]
    fn test_table_path() {
        let base = Path::new("/project");
        let result = table_path(base, "users");
        assert_eq!(result, Path::new("/project/.reedbase/users.csv"));
    }

    #[test]
    fn test_table_path_with_hyphens() {
        let base = Path::new("/project");
        let result = table_path(base, "user-data");
        assert_eq!(result, Path::new("/project/.reedbase/user-data.csv"));
    }

    #[test]
    fn test_backup_dir() {
        let base = Path::new("/project");
        let result = backup_dir(base);
        assert_eq!(result, Path::new("/project/.reedbase/backups"));
    }

    #[test]
    fn test_wal_dir() {
        let base = Path::new("/project");
        let result = wal_dir(base);
        assert_eq!(result, Path::new("/project/.reedbase/wal"));
    }

    #[test]
    fn test_paths_are_consistent() {
        let base = Path::new("/test");

        // All paths should start with db_dir
        let db = db_dir(base);
        assert!(table_path(base, "t").starts_with(&db));
        assert!(backup_dir(base).starts_with(&db));
        assert!(wal_dir(base).starts_with(&db));
    }
}
