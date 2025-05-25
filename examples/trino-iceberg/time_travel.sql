-- Time Travel Concepts with Trino using Memory Catalog
-- Note: Memory catalog doesn't support Iceberg time travel features
-- This demonstrates versioning patterns and temporal analysis techniques

-- Clean up any existing tables
DROP TABLE IF EXISTS memory.default.inventory_v1;
DROP TABLE IF EXISTS memory.default.inventory_v2;
DROP TABLE IF EXISTS memory.default.inventory_v3;
DROP TABLE IF EXISTS memory.default.inventory_history;

-- Create initial inventory snapshot (Version 1)
CREATE TABLE memory.default.inventory_v1 (
    id BIGINT,
    product_name VARCHAR,
    quantity INTEGER,
    price DECIMAL(10,2),
    snapshot_time TIMESTAMP WITH TIME ZONE,
    version_id INTEGER
);

-- Initial inventory data
INSERT INTO memory.default.inventory_v1 VALUES
(1, 'Laptop', 50, 999.99, CURRENT_TIMESTAMP, 1),
(2, 'Mouse', 200, 29.99, CURRENT_TIMESTAMP, 1),
(3, 'Keyboard', 100, 79.99, CURRENT_TIMESTAMP, 1);

-- Check initial state
SELECT * FROM memory.default.inventory_v1;

-- Create second version after changes (Version 2)
CREATE TABLE memory.default.inventory_v2 (
    id BIGINT,
    product_name VARCHAR,
    quantity INTEGER,
    price DECIMAL(10,2),
    snapshot_time TIMESTAMP WITH TIME ZONE,
    version_id INTEGER
);

-- Simulate changes: sell laptops, restock mice
INSERT INTO memory.default.inventory_v2 VALUES
(1, 'Laptop', 45, 999.99, CURRENT_TIMESTAMP, 2),  -- Sold 5 laptops
(2, 'Mouse', 250, 29.99, CURRENT_TIMESTAMP, 2),   -- Restocked mice
(3, 'Keyboard', 100, 79.99, CURRENT_TIMESTAMP, 2); -- No change

-- Create third version with more changes (Version 3)
CREATE TABLE memory.default.inventory_v3 (
    id BIGINT,
    product_name VARCHAR,
    quantity INTEGER,
    price DECIMAL(10,2),
    snapshot_time TIMESTAMP WITH TIME ZONE,
    version_id INTEGER
);

-- More changes: price adjustment, new product
INSERT INTO memory.default.inventory_v3 VALUES
(1, 'Laptop', 45, 999.99, CURRENT_TIMESTAMP, 3),
(2, 'Mouse', 250, 29.99, CURRENT_TIMESTAMP, 3),
(3, 'Keyboard', 100, 69.99, CURRENT_TIMESTAMP, 3),  -- Price reduced
(4, 'Monitor', 30, 299.99, CURRENT_TIMESTAMP, 3);   -- New product

-- Create a unified history table
CREATE TABLE memory.default.inventory_history (
    id BIGINT,
    product_name VARCHAR,
    quantity INTEGER,
    price DECIMAL(10,2),
    snapshot_time TIMESTAMP WITH TIME ZONE,
    version_id INTEGER
);

-- Combine all versions into history
INSERT INTO memory.default.inventory_history 
SELECT * FROM memory.default.inventory_v1
UNION ALL
SELECT * FROM memory.default.inventory_v2
UNION ALL
SELECT * FROM memory.default.inventory_v3;

-- Show complete history
SELECT * FROM memory.default.inventory_history 
ORDER BY id, version_id;

-- Simulate time travel: Query specific version
SELECT 'Version 1 State:' as query_type, * 
FROM memory.default.inventory_history 
WHERE version_id = 1
UNION ALL
SELECT 'Version 2 State:', * 
FROM memory.default.inventory_history 
WHERE version_id = 2;

-- Compare versions (simulate time travel comparison)
WITH v1 AS (
    SELECT id, product_name, quantity as old_quantity, price as old_price
    FROM memory.default.inventory_history 
    WHERE version_id = 1
),
v3 AS (
    SELECT id, product_name, quantity as new_quantity, price as new_price
    FROM memory.default.inventory_history 
    WHERE version_id = 3
)
SELECT 
    COALESCE(v1.id, v3.id) as id,
    COALESCE(v1.product_name, v3.product_name) as product_name,
    v1.old_quantity,
    v3.new_quantity,
    COALESCE(v3.new_quantity, 0) - COALESCE(v1.old_quantity, 0) as quantity_change,
    v1.old_price,
    v3.new_price,
    COALESCE(v3.new_price, 0) - COALESCE(v1.old_price, 0) as price_change,
    CASE 
        WHEN v1.id IS NULL THEN 'NEW'
        WHEN v3.id IS NULL THEN 'DELETED'
        ELSE 'MODIFIED'
    END as change_type
FROM v1 
FULL OUTER JOIN v3 ON v1.id = v3.id
ORDER BY id;

-- Audit trail: show all changes over time
SELECT 
    product_name,
    version_id,
    quantity,
    price,
    snapshot_time,
    LAG(quantity) OVER (PARTITION BY id ORDER BY version_id) as prev_quantity,
    LAG(price) OVER (PARTITION BY id ORDER BY version_id) as prev_price
FROM memory.default.inventory_history
ORDER BY id, version_id;

-- Inventory trends over time
SELECT 
    version_id,
    COUNT(DISTINCT id) as product_count,
    SUM(quantity) as total_inventory,
    AVG(price) as avg_price,
    MAX(snapshot_time) as snapshot_time
FROM memory.default.inventory_history
GROUP BY version_id
ORDER BY version_id;

-- Find products with price changes
SELECT 
    product_name,
    MIN(price) as lowest_price,
    MAX(price) as highest_price,
    MAX(price) - MIN(price) as price_variance,
    COUNT(DISTINCT version_id) as versions_tracked
FROM memory.default.inventory_history
GROUP BY product_name
HAVING COUNT(DISTINCT price) > 1;