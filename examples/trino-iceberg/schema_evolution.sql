-- Schema Evolution Examples with Trino-Iceberg

-- Create initial table
CREATE SCHEMA IF NOT EXISTS iceberg.evolution;

CREATE TABLE iceberg.evolution.user_profiles (
    id BIGINT,
    username VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
) WITH (
    format = 'PARQUET',
    location = 's3://lakehouse/iceberg/evolution/user_profiles'
);

-- Insert initial data
INSERT INTO iceberg.evolution.user_profiles VALUES
(1, 'alice', 'alice@example.com', CURRENT_TIMESTAMP),
(2, 'bob', 'bob@example.com', CURRENT_TIMESTAMP),
(3, 'charlie', 'charlie@example.com', CURRENT_TIMESTAMP);

-- Query initial state
SELECT * FROM iceberg.evolution.user_profiles;

-- Add new columns (schema evolution)
ALTER TABLE iceberg.evolution.user_profiles 
ADD COLUMN age INTEGER;

ALTER TABLE iceberg.evolution.user_profiles 
ADD COLUMN status VARCHAR DEFAULT 'active';

-- Insert data with new schema
INSERT INTO iceberg.evolution.user_profiles VALUES
(4, 'diana', 'diana@example.com', CURRENT_TIMESTAMP, 28, 'active'),
(5, 'eve', 'eve@example.com', CURRENT_TIMESTAMP, 32, 'inactive');

-- Query with evolved schema
SELECT * FROM iceberg.evolution.user_profiles;

-- Show how old data still works (NULL values for new columns)
SELECT 
    id, 
    username, 
    COALESCE(age, 0) as age_with_default,
    COALESCE(status, 'unknown') as status_with_default
FROM iceberg.evolution.user_profiles;

-- Rename a column
ALTER TABLE iceberg.evolution.user_profiles 
RENAME COLUMN username TO user_name;

-- Update old records with new column values
UPDATE iceberg.evolution.user_profiles 
SET age = 25, status = 'active' 
WHERE id = 1;

UPDATE iceberg.evolution.user_profiles 
SET age = 30, status = 'active' 
WHERE id = 2;

UPDATE iceberg.evolution.user_profiles 
SET age = 35, status = 'active' 
WHERE id = 3;

-- Final query
SELECT * FROM iceberg.evolution.user_profiles ORDER BY id;

-- Show table history to see schema changes
SELECT * FROM iceberg.evolution."user_profiles$history";

-- Show table snapshots
SELECT * FROM iceberg.evolution."user_profiles$snapshots";

-- Drop a column (if needed - be careful!)
-- ALTER TABLE iceberg.evolution.user_profiles DROP COLUMN status;