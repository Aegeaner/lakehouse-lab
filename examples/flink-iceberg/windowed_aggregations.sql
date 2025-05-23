-- Windowed Aggregations with Flink and Iceberg
-- This example demonstrates tumbling window aggregations from Kafka to Iceberg

-- Create Kafka source for metrics data
CREATE TABLE metrics_stream (
    sensor_id STRING,
    metric_name STRING,
    metric_value DOUBLE,
    location STRING,
    event_time TIMESTAMP(3),
    WATERMARK FOR event_time AS event_time - INTERVAL '10' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'metrics',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'metrics_aggregator',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.timestamp-format.standard' = 'ISO-8601'
);

-- Create Iceberg table for aggregated metrics
CREATE TABLE iceberg_metrics_hourly (
    window_start TIMESTAMP(3),
    window_end TIMESTAMP(3),
    sensor_id STRING,
    location STRING,
    metric_name STRING,
    avg_value DOUBLE,
    min_value DOUBLE,
    max_value DOUBLE,
    count_values BIGINT,
    processing_time TIMESTAMP(3)
) PARTITIONED BY (location, DATE_FORMAT(window_start, 'yyyy-MM-dd')) WITH (
    'connector' = 'iceberg',
    'catalog-name' = 'iceberg_catalog',
    'catalog-type' = 'hadoop',
    'warehouse' = 'file:///opt/iceberg/warehouse',
    'database-name' = 'streaming',
    'table-name' = 'metrics_hourly',
    'format-version' = '2'
);

-- Perform hourly aggregations
INSERT INTO iceberg_metrics_hourly
SELECT
    TUMBLE_START(event_time, INTERVAL '1' HOUR) as window_start,
    TUMBLE_END(event_time, INTERVAL '1' HOUR) as window_end,
    sensor_id,
    location,
    metric_name,
    AVG(metric_value) as avg_value,
    MIN(metric_value) as min_value,
    MAX(metric_value) as max_value,
    COUNT(*) as count_values,
    CURRENT_TIMESTAMP as processing_time
FROM metrics_stream
GROUP BY 
    TUMBLE(event_time, INTERVAL '1' HOUR),
    sensor_id,
    location,
    metric_name;