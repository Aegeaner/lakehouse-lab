-- Schema Evolution Examples with Trino using Memory Catalog
-- Note: Memory catalog doesn't support ALTER TABLE operations
-- This demonstrates alternative approaches for schema changes

-- Clean up any existing table
DROP TABLE IF EXISTS memory.default.user_profiles_v1;
DROP TABLE IF EXISTS memory.default.user_profiles_v2;

-- Create initial table (version 1)
CREATE TABLE memory.default.user_profiles_v1 (
    id BIGINT,
    username VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
);

-- Insert initial data
INSERT INTO memory.default.user_profiles_v1 VALUES
(1, 'alice', 'alice@example.com', CURRENT_TIMESTAMP),
(2, 'bob', 'bob@example.com', CURRENT_TIMESTAMP),
(3, 'charlie', 'charlie@example.com', CURRENT_TIMESTAMP);

-- Query initial state
SELECT * FROM memory.default.user_profiles_v1;

-- Simulate schema evolution by creating new table with additional columns
CREATE TABLE memory.default.user_profiles_v2 (
    id BIGINT,
    user_name VARCHAR,  -- renamed from username
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE,
    age INTEGER,        -- new column
    status VARCHAR      -- new column
);

-- Migrate data with schema changes and defaults
INSERT INTO memory.default.user_profiles_v2 
SELECT 
    id,
    username as user_name,  -- column rename
    email,
    created_at,
    NULL as age,            -- new column with NULL
    'active' as status      -- new column with default
FROM memory.default.user_profiles_v1;

-- Add new records with full schema
INSERT INTO memory.default.user_profiles_v2 VALUES
(4, 'diana', 'diana@example.com', CURRENT_TIMESTAMP, 28, 'active'),
(5, 'eve', 'eve@example.com', CURRENT_TIMESTAMP, 32, 'inactive');

-- Query with evolved schema
SELECT * FROM memory.default.user_profiles_v2;

-- Show how to handle schema evolution patterns
SELECT 
    id, 
    user_name, 
    COALESCE(age, 25) as age_with_default,  -- Handle NULLs
    COALESCE(status, 'unknown') as status_with_default
FROM memory.default.user_profiles_v2;

-- Demonstrate data type compatibility checks
SELECT 
    id,
    user_name,
    email,
    EXTRACT(YEAR FROM created_at) as signup_year,
    CASE 
        WHEN age IS NULL THEN 'Age not provided'
        WHEN age < 30 THEN 'Young'
        ELSE 'Experienced'
    END as age_category,
    status
FROM memory.default.user_profiles_v2
ORDER BY id;

-- Show data distribution after schema evolution
SELECT 
    status,
    COUNT(*) as user_count,
    AVG(COALESCE(age, 25)) as avg_age,
    MIN(created_at) as earliest_signup,
    MAX(created_at) as latest_signup
FROM memory.default.user_profiles_v2
GROUP BY status;