// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! ReedBase: CSV-based versioned database with Smart Indices and ReedQL.
//!
//! This is the v0.2.0-beta Clean Room rebuild.

pub mod api;
pub mod core;
pub mod ops;
pub mod process;
pub mod store;
pub mod validate;

pub mod error;

#[cfg(test)]
#[path = "error_test.rs"]
mod error_test;

// Re-exports
pub use error::{ReedError, ReedResult};

/// ReedBase version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
