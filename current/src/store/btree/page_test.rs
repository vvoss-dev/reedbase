// Copyright 2025 Vivian Voss. Licensed under the Apache License, Version 2.0.
// SPDX-License-Identifier: Apache-2.0

//! Tests for B-Tree page management.

use super::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_page_size_constants() {
        assert_eq!(PAGE_SIZE, 4096);
        assert_eq!(HEADER_SIZE, 32);
        assert_eq!(DATA_SIZE, 4064);
        assert_eq!(HEADER_SIZE + DATA_SIZE, PAGE_SIZE);
    }

    #[test]
    fn test_header_serialization() {
        let header = PageHeader {
            magic: BTREE_MAGIC,
            page_type: NodeType::Leaf as u8,
            num_keys: 42,
            next_page: 123,
            checksum: 0xDEADBEEF,
            _padding: [0u8; 17],
        };

        let bytes = header.to_bytes();
        assert_eq!(bytes.len(), HEADER_SIZE);

        let decoded = PageHeader::from_bytes(&bytes).unwrap();
        assert_eq!(decoded.magic, BTREE_MAGIC);
        assert_eq!(decoded.page_type, NodeType::Leaf as u8);
        assert_eq!(decoded.num_keys, 42);
        assert_eq!(decoded.next_page, 123);
        assert_eq!(decoded.checksum, 0xDEADBEEF);
    }

    #[test]
    fn test_header_invalid_magic() {
        let mut bytes = [0u8; HEADER_SIZE];
        bytes[0..4].copy_from_slice(&0xBADC0DE_u32.to_be_bytes());

        let result = PageHeader::from_bytes(&bytes);
        assert!(result.is_err());
    }

    #[test]
    fn test_page_new_internal() {
        let page = Page::new_internal(0);
        assert_eq!(page.header.magic, BTREE_MAGIC);
        assert_eq!(page.header.page_type, NodeType::Internal as u8);
        assert_eq!(page.header.num_keys, 0);
        assert_eq!(page.header.next_page, 0);
        assert_eq!(page.data.len(), DATA_SIZE);

        // Checksum should be valid for zeroed data
        let expected_checksum = crc32fast::hash(&page.data);
        assert_eq!(page.header.checksum, expected_checksum);
    }

    #[test]
    fn test_page_new_leaf() {
        let page = Page::new_leaf(0);
        assert_eq!(page.header.magic, BTREE_MAGIC);
        assert_eq!(page.header.page_type, NodeType::Leaf as u8);
        assert_eq!(page.header.num_keys, 0);
        assert_eq!(page.header.next_page, 0);
        assert_eq!(page.data.len(), DATA_SIZE);
    }

    #[test]
    fn test_page_set_data() {
        let mut page = Page::new_leaf(0);
        let original_checksum = page.header.checksum;

        let new_data = vec![1u8; DATA_SIZE];
        page.set_data(new_data);

        // Checksum should be updated
        assert_ne!(page.header.checksum, original_checksum);
        assert_eq!(page.header.checksum, crc32fast::hash(&page.data));
    }

    #[test]
    fn test_page_get_data() {
        let page = Page::new_leaf(0);
        let data = page.get_data();
        assert_eq!(data.len(), DATA_SIZE);
        assert!(data.iter().all(|&b| b == 0)); // All zeros initially
    }

    #[test]
    fn test_page_validate_success() {
        let page = Page::new_internal(0);
        assert!(page.validate().is_ok());
    }

    #[test]
    fn test_page_validate_invalid_magic() {
        let mut page = Page::new_leaf(0);
        page.header.magic = 0xBADC0DE;
        assert!(page.validate().is_err());
    }

    #[test]
    fn test_page_validate_invalid_checksum() {
        let mut page = Page::new_leaf(0);
        page.header.checksum = 0xDEADBEEF; // Wrong checksum
        assert!(page.validate().is_err());
    }

    #[test]
    #[should_panic(expected = "Data must be exactly 4064 bytes")]
    fn test_page_set_data_wrong_size() {
        let mut page = Page::new_leaf(0);
        let wrong_size_data = vec![1u8; 100]; // Wrong size
        page.set_data(wrong_size_data);
    }
}
