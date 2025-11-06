// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! B+-Tree on-disc index engine.
//!
//! Generic persistent index implementation using B+-Trees with mmap-based
//! file access for production use.
//!
//! ## Features
//!
//! - **On-Disc Persistence**: mmap-based file I/O (FreeBSD-compatible)
//! - **Crash Safety**: Write-Ahead-Log (WAL) for recovery
//! - **Range Queries**: Efficient range scans via linked leaf pages
//! - **Memory Efficient**: ~50MB for 10M keys (vs 1.5GB HashMap)
//! - **Fast Cold Start**: <100ms to load (vs 10s HashMap rebuild)
//!
//! ## Example Usage
//!
//! ```rust
//! use reedbase::store::btree::{Order, WriteAheadLog};
//!
//! // Create Order
//! let order = Order::new(512)?; // 512 keys per node
//!
//! // Open WAL
//! let mut wal = WriteAheadLog::open("data.wal")?;
//! wal.log_insert("key", vec![1, 2, 3])?;
//!
//! # Ok::<(), reedbase::ReedError>(())
//! ```

mod node;
mod page;
mod types;
mod wal;

#[cfg(test)]
#[path = "types_test.rs"]
mod types_test;

#[cfg(test)]
#[path = "page_test.rs"]
mod page_test;

// Re-export public API
pub use node::{InternalNode, LeafNode};
pub use page::{DATA_SIZE, HEADER_SIZE, PAGE_SIZE, Page, PageHeader};
pub use types::{BTREE_MAGIC, NodeType, Order, PageId};
pub use wal::{WalEntry, WriteAheadLog};

// NOTE: Index trait will be re-exported here in 020-[STORE]-05
// when indices module is implemented:
// pub use crate::store::indices::Index;
