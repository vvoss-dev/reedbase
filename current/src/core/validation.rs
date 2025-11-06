// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Validation utilities for ReedBase.
//!
//! Centralised input validation to ensure data integrity.

use crate::error::ReedError;

/// Validates a ReedBase key.
///
/// ## Rules
/// - Must not be empty
/// - Must contain only alphanumeric characters, dots, hyphens, underscores, and @
/// - @ symbol only allowed for language/environment suffixes (@de, @en, @dev, @prod)
///
/// ## Arguments
/// - `key`: The key to validate
///
/// ## Returns
/// - `Ok(())` if valid
/// - `Err(ReedError)` if invalid
///
/// ## Example
/// ```rust
/// use reedbase::core::validation::validate_key;
///
/// assert!(validate_key("page.title").is_ok());
/// assert!(validate_key("page.title@de").is_ok());
/// assert!(validate_key("").is_err());
/// ```
pub fn validate_key(key: &str) -> Result<(), ReedError> {
    if key.is_empty() {
        return Err(ReedError::InvalidCsv {
            reason: "Key cannot be empty".to_string(),
            line: 0,
        });
    }

    // Check for invalid characters
    for ch in key.chars() {
        if !ch.is_alphanumeric() && ch != '.' && ch != '-' && ch != '_' && ch != '@' {
            return Err(ReedError::InvalidCsv {
                reason: format!("Invalid character '{}' in key '{}'", ch, key),
                line: 0,
            });
        }
    }

    Ok(())
}

/// Validates a table name.
///
/// ## Rules
/// - Must not be empty
/// - Must contain only alphanumeric characters, hyphens, and underscores
/// - Must start with a letter
///
/// ## Arguments
/// - `table_name`: The table name to validate
///
/// ## Returns
/// - `Ok(())` if valid
/// - `Err(ReedError)` if invalid
///
/// ## Example
/// ```rust
/// use reedbase::core::validation::validate_table_name;
///
/// assert!(validate_table_name("users").is_ok());
/// assert!(validate_table_name("user_data").is_ok());
/// assert!(validate_table_name("123invalid").is_err());
/// ```
pub fn validate_table_name(table_name: &str) -> Result<(), ReedError> {
    if table_name.is_empty() {
        return Err(ReedError::InvalidCsv {
            reason: "Table name cannot be empty".to_string(),
            line: 0,
        });
    }

    // Must start with a letter
    if let Some(first_char) = table_name.chars().next() {
        if !first_char.is_alphabetic() {
            return Err(ReedError::InvalidCsv {
                reason: format!("Table name '{}' must start with a letter", table_name),
                line: 0,
            });
        }
    }

    // Check for invalid characters
    for ch in table_name.chars() {
        if !ch.is_alphanumeric() && ch != '-' && ch != '_' {
            return Err(ReedError::InvalidCsv {
                reason: format!("Invalid character '{}' in table name '{}'", ch, table_name),
                line: 0,
            });
        }
    }

    Ok(())
}
