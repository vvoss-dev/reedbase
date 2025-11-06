// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Error types for ReedBase.
//!
//! This module will be implemented in Phase 1 (Core Module).

use std::fmt;

/// ReedBase error type.
///
/// This is a placeholder for the Clean Room rebuild.
/// Full implementation will be done in ticket 010-[CORE]-04.
#[derive(Debug)]
pub enum ReedError {
    /// Placeholder variant
    Placeholder,
}

impl fmt::Display for ReedError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ReedError::Placeholder => write!(f, "Placeholder error"),
        }
    }
}

impl std::error::Error for ReedError {}
