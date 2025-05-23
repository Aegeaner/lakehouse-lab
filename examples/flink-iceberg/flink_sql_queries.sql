-- Flink SQL Interactive Queries for Iceberg Tables
-- Use these queries in Flink SQL CLI to explore streaming job results
-- Run: ./scripts/run_flink_example.sh interactive

-- Show all available tables
SHOW TABLES;

-- Explore user events table
DESCRIBE iceberg_user_events;
SELECT COUNT(*) FROM iceberg_user_events;
SELECT event_type, COUNT(*) as event_count FROM iceberg_user_events GROUP BY event_type;
SELECT * FROM iceberg_user_events ORDER BY processing_time DESC LIMIT 10;

-- Explore hourly metrics (if windowed aggregation job has run)  
DESCRIBE iceberg_metrics_hourly;
SELECT COUNT(*) FROM iceberg_metrics_hourly;
SELECT location, metric_name, avg_value FROM iceberg_metrics_hourly ORDER BY window_start DESC LIMIT 10;

-- Explore CDC tables (if CDC job has run)
DESCRIBE iceberg_users_current;
SELECT COUNT(*) FROM iceberg_users_current;
SELECT id, name, status, cdc_op_type FROM iceberg_users_current ORDER BY processing_time DESC;

DESCRIBE iceberg_users_audit; 
SELECT COUNT(*) FROM iceberg_users_audit;
SELECT id, op_type, before_status, after_status FROM iceberg_users_audit ORDER BY change_timestamp DESC LIMIT 10;

-- Time-based analysis
SELECT 
  DATE_FORMAT(processing_time, 'yyyy-MM-dd HH:mm') as minute_window,
  COUNT(*) as events_per_minute
FROM iceberg_user_events 
GROUP BY DATE_FORMAT(processing_time, 'yyyy-MM-dd HH:mm')
ORDER BY minute_window DESC;

-- Note: To run these queries:
-- 1. Start Flink SQL CLI: ./scripts/run_flink_example.sh interactive
-- 2. Copy and paste queries above
-- 3. Or create a .sql file and load it with \i filename.sql
