-- Time Travel Examples with Trino-Iceberg

-- Create a table for time travel demonstration
CREATE SCHEMA IF NOT EXISTS iceberg.timetravel;

CREATE TABLE iceberg.timetravel.inventory (
    id BIGINT,
    product_name VARCHAR,
    quantity INTEGER,
    price DECIMAL(10,2),
    last_updated TIMESTAMP WITH TIME ZONE
) WITH (
    format = 'PARQUET',
    location = 's3://lakehouse/iceberg/timetravel/inventory'
);

-- Initial inventory data
INSERT INTO iceberg.timetravel.inventory VALUES
(1, 'Laptop', 50, 999.99, CURRENT_TIMESTAMP),
(2, 'Mouse', 200, 29.99, CURRENT_TIMESTAMP),
(3, 'Keyboard', 100, 79.99, CURRENT_TIMESTAMP);

-- Check initial state and get snapshot info
SELECT * FROM iceberg.timetravel.inventory;

-- Show snapshots (save the snapshot IDs for later use)
SELECT 
    snapshot_id,
    committed_at,
    summary
FROM iceberg.timetravel."inventory$snapshots"
ORDER BY committed_at;

-- Simulate inventory changes over time
-- Update 1: Sell some laptops
UPDATE iceberg.timetravel.inventory 
SET quantity = 45, last_updated = CURRENT_TIMESTAMP 
WHERE id = 1;

-- Wait a moment to create distinct timestamps
-- In a real scenario, these would be separate transactions

-- Update 2: Restock mice
UPDATE iceberg.timetravel.inventory 
SET quantity = 250, last_updated = CURRENT_TIMESTAMP 
WHERE id = 2;

-- Update 3: Price change for keyboard
UPDATE iceberg.timetravel.inventory 
SET price = 69.99, last_updated = CURRENT_TIMESTAMP 
WHERE id = 3;

-- Add new product
INSERT INTO iceberg.timetravel.inventory VALUES
(4, 'Monitor', 30, 299.99, CURRENT_TIMESTAMP);

-- Current state
SELECT * FROM iceberg.timetravel.inventory ORDER BY id;

-- Show all snapshots now
SELECT 
    snapshot_id,
    committed_at,
    summary
FROM iceberg.timetravel."inventory$snapshots"
ORDER BY committed_at;

-- Time travel queries using snapshot IDs
-- Replace SNAPSHOT_ID_HERE with actual snapshot ID from the snapshots query above

-- Query state at a specific snapshot
-- SELECT * FROM iceberg.timetravel.inventory FOR VERSION AS OF SNAPSHOT_ID_HERE;

-- Query using timestamp (approximate)
-- SELECT * FROM iceberg.timetravel.inventory FOR TIMESTAMP AS OF TIMESTAMP '2024-01-01 12:00:00';

-- Compare current vs historical data
-- WITH historical AS (
--     SELECT id, product_name, quantity as old_quantity, price as old_price
--     FROM iceberg.timetravel.inventory FOR VERSION AS OF SNAPSHOT_ID_HERE
-- ),
-- current AS (
--     SELECT id, product_name, quantity as new_quantity, price as new_price
--     FROM iceberg.timetravel.inventory
-- )
-- SELECT 
--     h.id,
--     h.product_name,
--     h.old_quantity,
--     c.new_quantity,
--     (c.new_quantity - h.old_quantity) as quantity_change,
--     h.old_price,
--     c.new_price,
--     (c.new_price - h.old_price) as price_change
-- FROM historical h
-- JOIN current c ON h.id = c.id;

-- Show table history for audit trail
SELECT * FROM iceberg.timetravel."inventory$history" ORDER BY made_current_at;

-- Show file-level changes
SELECT 
    file_path,
    file_format,
    record_count,
    file_size_in_bytes
FROM iceberg.timetravel."inventory$files";

-- Rollback example (careful - this creates a new snapshot with old data)
-- INSERT INTO iceberg.timetravel.inventory 
-- SELECT * FROM iceberg.timetravel.inventory FOR VERSION AS OF SNAPSHOT_ID_HERE
-- WHERE id = 1;