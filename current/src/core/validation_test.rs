// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for validation utilities.

#[cfg(test)]
mod tests {
    use super::super::validation::*;

    // Key validation tests
    #[test]
    fn test_validate_key_simple() {
        assert!(validate_key("page.title").is_ok());
    }

    #[test]
    fn test_validate_key_with_language_suffix() {
        assert!(validate_key("page.title@de").is_ok());
        assert!(validate_key("page.title@en").is_ok());
    }

    #[test]
    fn test_validate_key_with_environment_suffix() {
        assert!(validate_key("config.value@dev").is_ok());
        assert!(validate_key("config.value@prod").is_ok());
    }

    #[test]
    fn test_validate_key_with_hyphens() {
        assert!(validate_key("page-title").is_ok());
    }

    #[test]
    fn test_validate_key_with_underscores() {
        assert!(validate_key("page_title").is_ok());
    }

    #[test]
    fn test_validate_key_empty() {
        assert!(validate_key("").is_err());
    }

    #[test]
    fn test_validate_key_with_spaces() {
        assert!(validate_key("page title").is_err());
    }

    #[test]
    fn test_validate_key_with_special_chars() {
        assert!(validate_key("page.title!").is_err());
        assert!(validate_key("page#title").is_err());
    }

    // Table name validation tests
    #[test]
    fn test_validate_table_name_simple() {
        assert!(validate_table_name("users").is_ok());
    }

    #[test]
    fn test_validate_table_name_with_hyphens() {
        assert!(validate_table_name("user-data").is_ok());
    }

    #[test]
    fn test_validate_table_name_with_underscores() {
        assert!(validate_table_name("user_data").is_ok());
    }

    #[test]
    fn test_validate_table_name_empty() {
        assert!(validate_table_name("").is_err());
    }

    #[test]
    fn test_validate_table_name_starts_with_number() {
        assert!(validate_table_name("123users").is_err());
    }

    #[test]
    fn test_validate_table_name_starts_with_hyphen() {
        assert!(validate_table_name("-users").is_err());
    }

    #[test]
    fn test_validate_table_name_with_special_chars() {
        assert!(validate_table_name("users@de").is_err());
        assert!(validate_table_name("users.data").is_err());
    }
}
