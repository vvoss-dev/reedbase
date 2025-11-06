// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! ReedBase: CSV-based versioned database with Smart Indices and ReedQL.
//!
//! This is the v0.2.0-beta Clean Room rebuild.

pub mod core;
pub mod api;
pub mod store;
pub mod validate;
pub mod process;
pub mod ops;

pub mod error;

// Re-exports
pub use error::ReedError;

/// ReedBase version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
