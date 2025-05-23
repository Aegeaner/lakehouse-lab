-- Simple Flink to Iceberg Streaming Example
-- This example demonstrates basic streaming from Kafka to Iceberg

-- Create Kafka source table for user events
CREATE TABLE user_events (
    user_id BIGINT,
    event_type STRING,
    event_data STRING,
    event_time TIMESTAMP(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'user_events',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'flink_consumer',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

-- Create Iceberg sink table
CREATE TABLE iceberg_user_events (
    user_id BIGINT,
    event_type STRING,
    event_data STRING,
    event_time TIMESTAMP(3),
    processing_time TIMESTAMP(3)
) PARTITIONED BY (event_type) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'catalog-type' = 'hadoop',
    'warehouse' = 'file:///opt/iceberg/warehouse',
    'database-name' = 'streaming',
    'table-name' = 'user_events',
    'format-version' = '2'
);

