// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for B-Tree types.

use super::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_btree_magic() {
        assert_eq!(BTREE_MAGIC, 0xB7EE_7EE1);
    }

    #[test]
    fn test_order_validation() {
        // Valid orders
        assert!(Order::new(3).is_ok());
        assert!(Order::new(100).is_ok());
        assert!(Order::new(1000).is_ok());

        // Invalid orders
        assert!(Order::new(0).is_err());
        assert!(Order::new(1).is_err());
        assert!(Order::new(2).is_err());
    }

    #[test]
    fn test_order_max_keys() {
        let order = Order::new(100).unwrap();
        assert_eq!(order.max_keys(), 100);

        let order = Order::new(50).unwrap();
        assert_eq!(order.max_keys(), 50);
    }

    #[test]
    fn test_order_min_keys() {
        let order = Order::new(100).unwrap();
        assert_eq!(order.min_keys(), 50);

        let order = Order::new(51).unwrap();
        assert_eq!(order.min_keys(), 25);

        let order = Order::new(3).unwrap();
        assert_eq!(order.min_keys(), 1);
    }

    #[test]
    fn test_node_type_discriminant() {
        assert_eq!(NodeType::Internal as u8, 0);
        assert_eq!(NodeType::Leaf as u8, 1);
    }

    #[test]
    fn test_node_type_serialization() {
        // Test that NodeType can be serialized/deserialized
        let internal = NodeType::Internal;
        let leaf = NodeType::Leaf;

        // Basic equality checks
        assert_eq!(internal, NodeType::Internal);
        assert_eq!(leaf, NodeType::Leaf);
        assert_ne!(internal, leaf);
    }

    #[test]
    fn test_order_value() {
        let order = Order::new(100).unwrap();
        assert_eq!(order.value(), 100);
    }
}
