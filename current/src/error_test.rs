// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for error types.

use super::*;

#[test]
fn test_unknown_action_code_display() {
    let err = ReedError::UnknownActionCode { code: 42 };
    assert_eq!(err.to_string(), "Unknown action code: 42");
}

#[test]
fn test_unknown_user_code_display() {
    let err = ReedError::UnknownUserCode { code: 12345 };
    assert_eq!(err.to_string(), "Unknown user code: 12345");
}

#[test]
fn test_table_not_found_display() {
    let err = ReedError::TableNotFound {
        name: "users".to_string(),
    };
    assert_eq!(err.to_string(), "Table 'users' not found");
}

#[test]
fn test_table_already_exists_display() {
    let err = ReedError::TableAlreadyExists {
        name: "users".to_string(),
    };
    assert_eq!(err.to_string(), "Table 'users' already exists");
}

#[test]
fn test_io_error_display() {
    let err = ReedError::IoError {
        operation: "read".to_string(),
        reason: "file not found".to_string(),
    };
    assert_eq!(err.to_string(), "I/O error during 'read': file not found");
}

#[test]
fn test_csv_error_display() {
    let err = ReedError::CsvError {
        file: "data.csv".to_string(),
        operation: "parse".to_string(),
        reason: "invalid format".to_string(),
    };
    assert_eq!(
        err.to_string(),
        "CSV error in 'data.csv' during 'parse': invalid format"
    );
}

#[test]
fn test_validation_error_with_value() {
    let err = ReedError::ValidationError {
        column: "age".to_string(),
        reason: "must be positive".to_string(),
        value: Some("-5".to_string()),
    };
    assert_eq!(
        err.to_string(),
        "Validation error in column 'age': must be positive (value: '-5')"
    );
}

#[test]
fn test_validation_error_without_value() {
    let err = ReedError::ValidationError {
        column: "email".to_string(),
        reason: "invalid format".to_string(),
        value: None,
    };
    assert_eq!(
        err.to_string(),
        "Validation error in column 'email': invalid format"
    );
}

#[test]
fn test_lock_timeout_display() {
    let err = ReedError::LockTimeout {
        table: "users".to_string(),
        timeout_secs: 30,
    };
    assert_eq!(err.to_string(), "Lock timeout for table 'users' after 30s");
}

#[test]
fn test_invalid_order_display() {
    let err = ReedError::InvalidOrder { order: 2, min: 3 };
    assert_eq!(err.to_string(), "Invalid B+-Tree order: 2 (minimum: 3)");
}

#[test]
fn test_index_already_exists_display() {
    let err = ReedError::IndexAlreadyExists {
        table: "users".to_string(),
        column: "email".to_string(),
    };
    assert_eq!(err.to_string(), "Index already exists on users.email");
}

#[test]
fn test_query_optimization_failed_display() {
    let err = ReedError::QueryOptimizationFailed {
        query: "SELECT * FROM users".to_string(),
        reason: "no suitable index".to_string(),
    };
    assert_eq!(
        err.to_string(),
        "Query optimisation failed for 'SELECT * FROM users': no suitable index"
    );
}

#[test]
fn test_version_log_read_display() {
    let err = ReedError::VersionLogRead {
        path: std::path::PathBuf::from("/tmp/version.log"),
        reason: "permission denied".to_string(),
    };
    assert_eq!(
        err.to_string(),
        "Version log read failed for '/tmp/version.log': permission denied"
    );
}

#[test]
fn test_version_index_corrupted_display() {
    let err = ReedError::VersionIndexCorrupted {
        index_type: "timestamp".to_string(),
        path: std::path::PathBuf::from("/tmp/index.dat"),
    };
    assert_eq!(
        err.to_string(),
        "Version index 'timestamp' corrupted at '/tmp/index.dat'"
    );
}

#[test]
fn test_error_trait_implemented() {
    let err = ReedError::TableNotFound {
        name: "test".to_string(),
    };
    // Ensure ReedError implements std::error::Error
    let _: &dyn std::error::Error = &err;
}

#[test]
fn test_from_io_error() {
    let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "file not found");
    let reed_err: ReedError = io_err.into();

    match reed_err {
        ReedError::IoError { operation, reason } => {
            assert_eq!(operation, "unknown");
            assert!(reason.contains("file not found"));
        }
        _ => panic!("Expected IoError variant"),
    }
}

#[test]
fn test_reed_result_ok() {
    let result: ReedResult<i32> = Ok(42);
    assert_eq!(result.unwrap(), 42);
}

#[test]
fn test_reed_result_err() {
    let result: ReedResult<i32> = Err(ReedError::NoTablesFound);
    assert!(result.is_err());
}

#[test]
fn test_error_clone() {
    let err = ReedError::TableNotFound {
        name: "users".to_string(),
    };
    let cloned = err.clone();
    assert_eq!(err.to_string(), cloned.to_string());
}

#[test]
fn test_no_tables_found_display() {
    let err = ReedError::NoTablesFound;
    assert_eq!(err.to_string(), "No tables found");
}

#[test]
fn test_dictionary_corrupted_display() {
    let err = ReedError::DictionaryCorrupted {
        file: "actions.csv".to_string(),
        reason: "invalid format".to_string(),
        line: 42,
    };
    assert_eq!(
        err.to_string(),
        "Dictionary 'actions.csv' corrupted at line 42: invalid format"
    );
}

#[test]
fn test_serialization_error_display() {
    let err = ReedError::SerializationError {
        reason: "invalid UTF-8".to_string(),
    };
    assert_eq!(err.to_string(), "Serialisation error: invalid UTF-8");
}

#[test]
fn test_deserialization_error_display() {
    let err = ReedError::DeserializationError {
        reason: "unexpected EOF".to_string(),
    };
    assert_eq!(err.to_string(), "Deserialisation error: unexpected EOF");
}

#[test]
fn test_wal_recovery_failed_display() {
    let err = ReedError::WalRecoveryFailed {
        reason: "checksum mismatch".to_string(),
    };
    assert_eq!(err.to_string(), "WAL recovery failed: checksum mismatch");
}

#[test]
fn test_index_operation_unsupported_display() {
    let err = ReedError::IndexOperationUnsupported {
        operation: "range_scan".to_string(),
        backend: "hash".to_string(),
        reason: "hash indices only support equality".to_string(),
    };
    assert_eq!(
        err.to_string(),
        "Operation 'range_scan' not supported by 'hash' backend: hash indices only support equality"
    );
}
