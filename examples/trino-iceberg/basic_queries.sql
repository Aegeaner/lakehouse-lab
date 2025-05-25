-- Basic Trino Query Examples using Memory Catalog
-- Note: Memory catalog is temporary but demonstrates all Trino SQL features

-- Show available catalogs
SHOW CATALOGS;

-- Show schemas in memory catalog
SHOW SCHEMAS IN memory;

-- Clean up any existing table
DROP TABLE IF EXISTS memory.default.customers;

-- Create tables in memory catalog (temporary but fully functional)
CREATE TABLE memory.default.customers (
    id BIGINT,
    name VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
);

-- Insert sample data
INSERT INTO memory.default.customers VALUES
(1, 'John Doe', 'john@example.com', CURRENT_TIMESTAMP),
(2, 'Jane Smith', 'jane@example.com', CURRENT_TIMESTAMP),
(3, 'Bob Johnson', 'bob@example.com', CURRENT_TIMESTAMP);

-- Query the table
SELECT * FROM memory.default.customers;

-- Show table properties
SHOW CREATE TABLE memory.default.customers;

-- Note: Memory catalog doesn't support UPDATE/DELETE operations
-- Instead, we can demonstrate data filtering and transformation

-- Show final state
SELECT * FROM memory.default.customers;

-- Advanced queries
SELECT 
    COUNT(*) as total_customers,
    MIN(created_at) as first_signup,
    MAX(created_at) as last_signup
FROM memory.default.customers;

-- Window functions
SELECT 
    id,
    name,
    email,
    ROW_NUMBER() OVER (ORDER BY created_at) as signup_order
FROM memory.default.customers;