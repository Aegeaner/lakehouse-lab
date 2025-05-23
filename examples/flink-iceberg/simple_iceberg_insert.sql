-- Insert job: Stream data from Kafka to Iceberg with processing timestamp
INSERT INTO iceberg_user_events 
SELECT 
    user_id,
    event_type,
    event_data,
    event_time,
    CURRENT_TIMESTAMP as processing_time
FROM user_events;