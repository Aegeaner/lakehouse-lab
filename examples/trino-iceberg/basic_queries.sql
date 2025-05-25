-- Basic Trino-Iceberg Query Examples

-- Show available catalogs
SHOW CATALOGS;

-- Show schemas in iceberg catalog
SHOW SCHEMAS IN iceberg;

-- Create a new schema
CREATE SCHEMA IF NOT EXISTS iceberg.demo;

-- Create a simple Iceberg table
CREATE TABLE iceberg.demo.customers (
    id BIGINT,
    name VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
) WITH (
    format = 'PARQUET',
    location = 's3://lakehouse/iceberg/demo/customers'
);

-- Insert sample data
INSERT INTO iceberg.demo.customers VALUES
(1, 'John Doe', 'john@example.com', CURRENT_TIMESTAMP),
(2, 'Jane Smith', 'jane@example.com', CURRENT_TIMESTAMP),
(3, 'Bob Johnson', 'bob@example.com', CURRENT_TIMESTAMP);

-- Query the table
SELECT * FROM iceberg.demo.customers;

-- Show table properties
SHOW CREATE TABLE iceberg.demo.customers;

-- Query table metadata
SELECT * FROM iceberg.demo."customers$history";
SELECT * FROM iceberg.demo."customers$snapshots";
SELECT * FROM iceberg.demo."customers$files";

-- Time travel query (using snapshot ID from previous query)
-- SELECT * FROM iceberg.demo.customers FOR VERSION AS OF 123456789;

-- Update records
UPDATE iceberg.demo.customers 
SET email = 'john.doe@newcompany.com' 
WHERE id = 1;

-- Delete records
DELETE FROM iceberg.demo.customers WHERE id = 3;

-- Show final state
SELECT * FROM iceberg.demo.customers;