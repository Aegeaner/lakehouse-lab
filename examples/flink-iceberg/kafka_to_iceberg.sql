-- Enhanced Kafka source to Iceberg sink SQL
-- This is the improved version - use simple_iceberg_streaming.sql instead

-- Legacy example for reference:
CREATE TABLE kafka_events (
  user_id STRING,
  action STRING,
  ts TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'user_events',  -- Updated to match new topic naming
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id' = 'legacy_consumer',
  'format' = 'json',
  'scan.startup.mode' = 'earliest-offset'
);

CREATE TABLE iceberg_sink (
  user_id STRING,
  action STRING,
  ts TIMESTAMP(3),
  processing_time TIMESTAMP(3)
) PARTITIONED BY (action) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'iceberg_catalog',
  'catalog-type' = 'hadoop',  -- Using hadoop catalog for simplicity
  'warehouse' = 'file:///opt/iceberg/warehouse',
  'database-name' = 'streaming',
  'table-name' = 'legacy_events',
  'format-version' = '2'
);

-- Enhanced insert with processing timestamp
INSERT INTO iceberg_sink 
SELECT 
  user_id,
  action,
  ts,
  CURRENT_TIMESTAMP as processing_time
FROM kafka_events;

-- Note: For new implementations, use simple_iceberg_streaming.sql which includes:
-- - Better error handling
-- - Improved partitioning strategy  
-- - Enhanced data types and validation
