-- Change Data Capture (CDC) to Iceberg
-- This example demonstrates handling CDC events and maintaining current state in Iceberg

-- Create Kafka source for CDC events
CREATE TABLE cdc_events (
    op_type STRING,  -- INSERT, UPDATE, DELETE
    before ROW<
        id BIGINT,
        name STRING,
        email STRING,
        status STRING,
        updated_at TIMESTAMP(3)
    >,
    after ROW<
        id BIGINT,
        name STRING,
        email STRING,
        status STRING,
        updated_at TIMESTAMP(3)
    >,
    ts_ms BIGINT,
    event_time AS TO_TIMESTAMP(FROM_UNIXTIME(ts_ms / 1000)),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'cdc_users',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'cdc_processor',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

-- Create Iceberg table for current user state
CREATE TABLE iceberg_users_current (
    id BIGINT,
    name STRING,
    email STRING,
    status STRING,
    updated_at TIMESTAMP(3),
    cdc_op_type STRING,
    processing_time TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) PARTITIONED BY (status) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'catalog-type' = 'hadoop',
    'warehouse' = 'file:///opt/iceberg/warehouse',
    'database-name' = 'streaming',
    'table-name' = 'users_current',
    'format-version' = '2',
    'write.upsert.enabled' = 'true'
);

-- Create Iceberg table for CDC audit trail
CREATE TABLE iceberg_users_audit (
    id BIGINT,
    op_type STRING,
    before_name STRING,
    after_name STRING,
    before_email STRING,
    after_email STRING,
    before_status STRING,
    after_status STRING,
    change_timestamp TIMESTAMP(3),
    processing_time TIMESTAMP(3)
) PARTITIONED BY (DATE_FORMAT(change_timestamp, 'yyyy-MM-dd')) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'catalog-type' = 'hadoop',
    'warehouse' = 'file:///opt/iceberg/warehouse',
    'database-name' = 'streaming',
    'table-name' = 'users_audit',
    'format-version' = '2'
);

-- Process CDC events to maintain current state
INSERT INTO iceberg_users_current
SELECT
    COALESCE(after.id, before.id) as id,
    after.name,
    after.email,
    after.status,
    COALESCE(after.updated_at, before.updated_at) as updated_at,
    op_type as cdc_op_type,
    CURRENT_TIMESTAMP as processing_time
FROM cdc_events
WHERE op_type IN ('INSERT', 'UPDATE');

-- Create audit trail for all changes
INSERT INTO iceberg_users_audit
SELECT
    COALESCE(after.id, before.id) as id,
    op_type,
    before.name as before_name,
    after.name as after_name,
    before.email as before_email,
    after.email as after_email,
    before.status as before_status,
    after.status as after_status,
    event_time as change_timestamp,
    CURRENT_TIMESTAMP as processing_time
FROM cdc_events;