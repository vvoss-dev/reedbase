# E-Commerce Gap Analysis for ReedBase

## Executive Summary

**Goal:** Make ReedBase viable for full e-commerce applications (not just content layer).

**Current Status:** ReedBase excels at CMS content (product descriptions, UI texts) but lacks critical features for transactional e-commerce operations (checkout, inventory, orders).

**Gap:** Missing ACID transactions, multi-key atomicity, and referential integrity.

---

## Critical E-Commerce Scenarios

### Scenario 1: Shopping Cart Checkout

**User Story:**
> As a customer, I want to checkout with 3 items, update inventory, create order, and process payment atomically - if payment fails, inventory must rollback.

**Current ReedBase (BROKEN):**
```rust
// ❌ NO ATOMICITY - Race conditions possible!

// Step 1: Check inventory
let stock_item1 = db.get("inventory.product.123.stock")?; // "10"
let stock_item2 = db.get("inventory.product.456.stock")?; // "5"

// Step 2: Deduct inventory (NON-ATOMIC!)
db.set("inventory.product.123.stock", "9")?;
db.set("inventory.product.456.stock", "4")?;

// Step 3: Create order
db.set("order.789.status", "pending")?;
db.set("order.789.items", "123,456")?;

// Step 4: Process payment
let payment = process_payment(order_total)?;

// ❌ PROBLEM: If payment fails, inventory is already deducted!
// ❌ PROBLEM: Another customer could buy item between step 1 and 2!
// ❌ PROBLEM: No way to rollback if any step fails!
```

**What's Missing:**
1. ✅ **Transactions (BEGIN/COMMIT/ROLLBACK)**
2. ✅ **Multi-key atomicity** (all-or-nothing updates)
3. ✅ **Isolation levels** (prevent concurrent modifications)
4. ✅ **Optimistic locking** (detect concurrent updates)

---

### Scenario 2: Inventory Management

**User Story:**
> As a warehouse manager, I want to transfer 50 items from warehouse A to warehouse B - if either update fails, neither should happen.

**Current ReedBase (BROKEN):**
```rust
// ❌ NO ATOMICITY

// Deduct from warehouse A
let stock_a = db.get("warehouse.a.product.123.stock")?; // "100"
db.set("warehouse.a.product.123.stock", "50")?;

// ❌ CRASH HERE = 50 items lost forever!

// Add to warehouse B
let stock_b = db.get("warehouse.b.product.123.stock")?; // "20"
db.set("warehouse.b.product.123.stock", "70")?;
```

**What's Missing:**
1. ✅ **Atomic batch operations** (multi-key updates)
2. ✅ **Write-ahead log (WAL)** for crash recovery
3. ✅ **Two-phase commit** for distributed consistency

---

### Scenario 3: Coupon Redemption

**User Story:**
> As a customer, I want to use a one-time coupon code - system must ensure only I can use it, even if 1000 users try simultaneously.

**Current ReedBase (BROKEN):**
```rust
// ❌ RACE CONDITION

// Check if coupon is valid
let coupon = db.get("coupon.SAVE20.uses_left")?; // "1"

// ❌ PROBLEM: 1000 concurrent requests all see "1"!

if coupon == "1" {
    // All 1000 requests enter here!
    db.set("coupon.SAVE20.uses_left", "0")?;
    apply_discount(order)?;
}

// ❌ RESULT: 1000 orders get discount instead of 1!
```

**What's Missing:**
1. ✅ **Compare-and-swap (CAS)** operations
2. ✅ **Atomic increment/decrement** (`INCR`/`DECR` like Redis)
3. ✅ **Pessimistic locking** (lock key during read-modify-write)

---

### Scenario 4: Order Status Consistency

**User Story:**
> As a customer, I want to see consistent order status - if payment succeeded, order status must be "paid", never stuck in "pending".

**Current ReedBase (BROKEN):**
```rust
// ❌ INCONSISTENT STATE

// Update payment status
db.set("payment.789.status", "success")?;

// ❌ CRASH HERE = payment succeeded but order status never updated!

// Update order status
db.set("order.789.status", "paid")?;

// ❌ RESULT: Customer sees "pending" but was charged!
```

**What's Missing:**
1. ✅ **Multi-key atomicity** (all keys update or none)
2. ✅ **Crash recovery** with WAL
3. ✅ **Referential integrity** (payment.order_id must exist in orders)

---

## Required Features for E-Commerce

### Priority 1: ACID Transactions (CRITICAL)

**API Design:**
```rust
// BEGIN/COMMIT/ROLLBACK support
let tx = db.begin_transaction()?;

// All operations within transaction
tx.set("inventory.product.123.stock", "9")?;
tx.set("order.789.status", "pending")?;
tx.set("order.789.items", "123")?;

// Process payment
match process_payment(order_total) {
    Ok(_) => tx.commit()?,      // All changes persist
    Err(_) => tx.rollback()?,   // All changes discarded
}
```

**Implementation Requirements:**
- ✅ **Write-Ahead Log (WAL)**: Log all changes before applying
- ✅ **Isolation**: Transactions don't see each other's uncommitted changes
- ✅ **Atomicity**: All-or-nothing (COMMIT or ROLLBACK)
- ✅ **Durability**: Committed transactions survive crashes

**Complexity:** High (8-10 weeks)

---

### Priority 2: Atomic Batch Operations (HIGH)

**API Design:**
```rust
// Atomic multi-key updates
db.atomic_batch(|batch| {
    batch.set("warehouse.a.product.123.stock", "50")?;
    batch.set("warehouse.b.product.123.stock", "70")?;
    batch.set("audit.transfer.timestamp", now)?;
    Ok(())
})?;

// All succeed or all fail (no partial updates)
```

**Implementation Requirements:**
- ✅ **WAL-based batching**: Log all changes first
- ✅ **Rollback on failure**: Undo all changes if any fails
- ✅ **Crash recovery**: Replay WAL on startup

**Complexity:** Medium (4-6 weeks)

---

### Priority 3: Compare-and-Swap (CAS) (HIGH)

**API Design:**
```rust
// Atomic compare-and-swap
db.compare_and_swap(
    "coupon.SAVE20.uses_left",
    expected: "1",    // Only update if current value is "1"
    new: "0"
)?;

// Returns:
// - Ok(true) if swap succeeded
// - Ok(false) if current value != expected (retry needed)
// - Err if key doesn't exist
```

**Implementation Requirements:**
- ✅ **Atomic read-modify-write**: Single lock acquisition
- ✅ **Version tracking**: Detect concurrent modifications
- ✅ **Retry logic**: Application must handle CAS failures

**Complexity:** Low-Medium (2-3 weeks)

---

### Priority 4: Atomic Increment/Decrement (MEDIUM)

**API Design:**
```rust
// Redis-like INCR/DECR
db.increment("page.views.product.123", 1)?;      // Atomic +1
db.decrement("inventory.product.123.stock", 1)?; // Atomic -1

// Returns new value after increment/decrement
let new_stock = db.decrement("inventory.product.123.stock", 5)?;
if new_stock < 0 {
    return Err("Out of stock");
}
```

**Implementation Requirements:**
- ✅ **Atomic integer operations**: Lock-free or single-lock
- ✅ **Type validation**: Ensure value is numeric
- ✅ **Overflow protection**: Prevent integer overflow

**Complexity:** Low (1-2 weeks)

---

### Priority 5: Optimistic Locking with Versions (MEDIUM)

**API Design:**
```rust
// Get value with version
let (value, version) = db.get_with_version("product.123.price")?;

// Modify value
let new_price = calculate_discount(value);

// Update only if version unchanged (no concurrent modifications)
db.set_if_version("product.123.price", new_price, version)?;

// Returns:
// - Ok(true) if update succeeded
// - Ok(false) if version mismatch (concurrent update detected)
```

**Implementation Requirements:**
- ✅ **Version counter per key**: Increment on every write
- ✅ **Version validation**: Check before write
- ✅ **Atomic version increment**: Part of write operation

**Complexity:** Low-Medium (2-3 weeks)

---

### Priority 6: Pessimistic Locking (LOW)

**API Design:**
```rust
// Explicit key locking
let lock = db.lock("inventory.product.123.stock")?;

let stock = lock.get()?;
if stock >= requested {
    lock.set(stock - requested)?;
}

lock.unlock()?; // Or drop(lock) for automatic unlock
```

**Implementation Requirements:**
- ✅ **Per-key locks**: RwLock or Mutex per key
- ✅ **Deadlock detection**: Timeout or deadlock avoidance
- ✅ **Lock timeout**: Prevent eternal locks

**Complexity:** Medium (3-4 weeks)

---

### Priority 7: Referential Integrity (OPTIONAL)

**API Design:**
```rust
// Define foreign key constraint
db.add_constraint(
    table: "order_items",
    column: "order_id",
    references: "orders",
    on_delete: Cascade,
)?;

// Now:
// - Can't create order_item with non-existent order_id
// - Deleting order automatically deletes order_items
```

**Implementation Requirements:**
- ✅ **Constraint registry**: Store FK definitions
- ✅ **Validation on write**: Check FK exists
- ✅ **Cascade operations**: ON DELETE CASCADE/SET NULL

**Complexity:** High (6-8 weeks) + Schema overhead

**Note:** This moves ReedBase towards relational DB territory - may conflict with schemaless philosophy.

---

## Implementation Roadmap

### Phase 1: Foundation (4-6 weeks)

**REED-20-01: Write-Ahead Log (WAL) Implementation**
- Append-only log file (`.reed/wal.log`)
- Log format: `[timestamp][operation][key][old_value][new_value]`
- Replay on crash recovery
- Log rotation and compaction

**Acceptance Criteria:**
- All writes logged before applying
- Crash recovery replays WAL correctly
- WAL compaction after 1000 entries or 10MB

---

### Phase 2: Atomic Operations (6-8 weeks)

**REED-20-02: Atomic Batch Operations**
- `db.atomic_batch()` API
- WAL-based batching
- Rollback on any failure

**REED-20-03: Compare-and-Swap (CAS)**
- `db.compare_and_swap()` API
- Version-based validation
- Atomic read-modify-write

**REED-20-04: Atomic Increment/Decrement**
- `db.increment()` and `db.decrement()` APIs
- Lock-free integer operations
- Overflow protection

**Acceptance Criteria:**
- All operations atomic (no partial updates)
- Concurrent operations don't interfere
- Crash during operation fully rolled back

---

### Phase 3: Transactions (8-10 weeks)

**REED-20-05: ACID Transactions**
- `db.begin_transaction()` API
- COMMIT/ROLLBACK support
- Isolation levels (Read Committed, Serializable)
- Deadlock detection

**Acceptance Criteria:**
- Shopping cart checkout works atomically
- Concurrent transactions isolated
- Rollback undoes all changes
- Crash recovery replays committed transactions

---

### Phase 4: Locking (4-6 weeks)

**REED-20-06: Optimistic Locking**
- `db.get_with_version()` API
- `db.set_if_version()` API
- Per-key version tracking

**REED-20-07: Pessimistic Locking (Optional)**
- `db.lock()` API
- Per-key locks with timeout
- Deadlock detection

**Acceptance Criteria:**
- Coupon redemption prevents double-use
- Concurrent inventory updates detected
- Lock timeout prevents eternal locks

---

## Performance Impact Analysis

### Current Performance (No Transactions):
- Single key lookup: 50-100 μs
- Batch write (10 keys): 500-1000 μs

### Estimated Performance (With Transactions):
- Single key lookup: 50-100 μs (unchanged - reads don't need WAL)
- Transaction (10 keys): 2-5 ms (WAL overhead + fsync)
- Atomic batch (10 keys): 1-2 ms (WAL without transaction overhead)
- CAS operation: 100-200 μs (version check + write)

### Trade-Offs:
- ✅ **Reads unchanged**: No performance impact for CMS use cases
- ⚠️ **Writes 2-5x slower**: WAL overhead + fsync for durability
- ✅ **Still 5-20x faster than MySQL**: Even with transactions

---

## Competitive Positioning After Implementation

### ReedBase vs SQL (With Transactions)

| Feature | ReedBase (After) | MySQL | PostgreSQL | SQLite |
|---------|------------------|-------|------------|--------|
| **Single key lookup** | 50-100 μs | 500-2000 μs | 500-2000 μs | 200-500 μs |
| **Transaction (10 keys)** | 2-5 ms | 10-50 ms | 10-50 ms | 5-20 ms |
| **ACID** | ✅ WAL-based | ✅ InnoDB | ✅ MVCC | ✅ WAL mode |
| **JOINs** | ❌ | ✅ | ✅ | ✅ |
| **Foreign keys** | ❌ (optional) | ✅ | ✅ | ✅ |
| **CMS-specific** | ✅ @lang/@env | ❌ | ❌ | ❌ |

**Result:** ReedBase remains 5-20x faster for e-commerce transactions, but loses some advantage due to WAL overhead.

---

### ReedBase vs Embedded Key-Value (With Transactions)

| Feature | ReedBase (After) | LMDB | Sled | RocksDB |
|---------|------------------|------|------|---------|
| **Transactions** | ✅ WAL-based | ✅ MVCC | ✅ MVCC | ❌ |
| **CMS-specific** | ✅ @lang/@env | ❌ | ❌ | ❌ |
| **SQL-like syntax** | ✅ ReedQL | ❌ | ❌ | ❌ |
| **Performance** | 2-5 ms/tx | 1-2 ms/tx | 2-5 ms/tx | 5-10 ms/tx |

**Result:** ReedBase matches Sled for transactions, still offers CMS-specific advantages.

---

## E-Commerce Use Cases (After Implementation)

### ✅ Now Possible: Full E-Commerce Stack

**1. Shopping Cart Checkout**
```rust
let tx = db.begin_transaction()?;

// Check inventory
let stock = tx.get("inventory.product.123.stock")?;
if stock < quantity {
    return Err("Out of stock");
}

// Deduct inventory
tx.decrement("inventory.product.123.stock", quantity)?;

// Create order
tx.set("order.789.status", "pending")?;
tx.set("order.789.items", "123")?;
tx.set("order.789.total", "99.99")?;

// Process payment
match process_payment(99.99) {
    Ok(_) => {
        tx.set("order.789.status", "paid")?;
        tx.commit()?; // All changes persist
    }
    Err(_) => tx.rollback()?, // Inventory restored
}
```

**2. Inventory Transfer**
```rust
db.atomic_batch(|batch| {
    batch.decrement("warehouse.a.product.123.stock", 50)?;
    batch.increment("warehouse.b.product.123.stock", 50)?;
    batch.set("audit.transfer.timestamp", now)?;
    Ok(())
})?;
```

**3. Coupon Redemption**
```rust
// Atomic CAS - prevents double-use
match db.compare_and_swap("coupon.SAVE20.uses_left", "1", "0") {
    Ok(true) => apply_discount(order)?,
    Ok(false) => return Err("Coupon already used"),
    Err(_) => return Err("Invalid coupon"),
}
```

**4. Flash Sale (1000 concurrent customers)**
```rust
// Atomic decrement - prevents overselling
loop {
    let (stock, version) = db.get_with_version("flash_sale.product.123.stock")?;
    
    if stock < 1 {
        return Err("Sold out");
    }
    
    match db.set_if_version("flash_sale.product.123.stock", stock - 1, version) {
        Ok(true) => break, // Success
        Ok(false) => continue, // Retry (concurrent update)
        Err(_) => return Err("System error"),
    }
}
```

---

## Recommended Approach: Hybrid Architecture

**Even with transactions, ReedBase is NOT a full relational database.**

### Best Practice: ReedBase + PostgreSQL

```
PostgreSQL (Relational Data):
├── users (id, email, password_hash)
├── orders (id, user_id, total, status)
├── order_items (id, order_id, product_id, quantity, price)
└── products (id, sku, price, category_id)
    └── Foreign keys, JOINs, complex queries

ReedBase (CMS Content + Fast Lookups):
├── product.{id}.title@de
├── product.{id}.description@en
├── inventory.product.{id}.stock
├── coupon.{code}.uses_left
├── flash_sale.product.{id}.stock
└── Atomic operations, fast lookups, multilingual

Integration:
- PostgreSQL: Create order (relational integrity)
- ReedBase: Deduct inventory (atomic operations)
- Both: Wrapped in distributed transaction if needed
```

**Advantages:**
- PostgreSQL: Relational integrity, JOINs, foreign keys
- ReedBase: 10-100x faster inventory checks, atomic stock updates
- Hybrid: Best of both worlds

---

## Timeline Estimate

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| **Phase 1: WAL** | 4-6 weeks | Crash recovery, log replay |
| **Phase 2: Atomic Ops** | 6-8 weeks | Batch, CAS, INCR/DECR |
| **Phase 3: Transactions** | 8-10 weeks | BEGIN/COMMIT/ROLLBACK |
| **Phase 4: Locking** | 4-6 weeks | Optimistic + pessimistic locks |
| **Testing & Hardening** | 4-6 weeks | E-commerce test suite |
| **Documentation** | 2-3 weeks | E-commerce guides |
| **Total** | **28-39 weeks** | ~6-9 months |

---

## Immediate Next Steps

1. ✅ **Create REED-20 ticket series** (WAL, Atomic Ops, Transactions, Locking)
2. ✅ **Prototype WAL implementation** (`.reed/wal.log` format)
3. ✅ **Benchmark transaction overhead** (target: < 5ms for 10-key transaction)
4. ✅ **Design transaction API** (ergonomic Rust API for BEGIN/COMMIT/ROLLBACK)
5. ✅ **Update PERFORMANCE.md** (position as "SQLite alternative with CMS features")

---

## Open Questions

1. **Isolation level:** Start with Read Committed or go straight to Serializable?
2. **Distributed transactions:** Support two-phase commit for PostgreSQL + ReedBase hybrid?
3. **Foreign keys:** Implement or stay schemaless?
4. **MVCC:** Implement multi-version concurrency control like PostgreSQL/LMDB?
5. **Compaction:** Online compaction or require downtime?

---

## Conclusion

**ReedBase CAN support e-commerce with 6-9 months of development.**

**Key additions needed:**
1. ✅ ACID transactions (BEGIN/COMMIT/ROLLBACK)
2. ✅ Atomic batch operations (multi-key updates)
3. ✅ Compare-and-swap (CAS) for concurrent safety
4. ✅ Atomic increment/decrement (inventory management)
5. ✅ Optimistic locking (version-based concurrency)

**Performance impact:**
- Reads: Unchanged (50-100 μs)
- Writes: 2-5x slower due to WAL (still 5-20x faster than MySQL)

**Positioning:**
> "ReedBase: The embedded database for e-commerce. CMS-native multilingual support + ACID transactions. 5-20x faster than MySQL, simpler than PostgreSQL + Redis."

**Recommendation:**
- Start with Phase 1 (WAL) + Phase 2 (Atomic Ops) for MVP e-commerce support
- Add full transactions (Phase 3) if customer demand justifies 8-10 week investment
- Consider hybrid approach (PostgreSQL + ReedBase) for complex e-commerce
