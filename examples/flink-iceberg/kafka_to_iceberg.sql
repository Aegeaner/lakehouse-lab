-- Kafka source to Iceberg sink SQL
CREATE TABLE kafka_events (
  user_id STRING,
  action STRING,
  ts TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'kafka',
  'topic' = 'events',
  'properties.bootstrap.servers' = 'kafka:9092',
  'format' = 'json',
  'scan.startup.mode' = 'earliest-offset'
);

CREATE TABLE iceberg_sink (
  user_id STRING,
  action STRING,
  ts TIMESTAMP(3)
) PARTITIONED BY (action) WITH (
  'connector' = 'iceberg',
  'catalog-name' = 'nessie',
  'catalog-type' = 'nessie',
  'uri' = 'http://nessie:19120/api/v1',
  'warehouse' = 'file:///opt/iceberg/warehouse',
  'format-version' = '2'
);

INSERT INTO iceberg_sink SELECT * FROM kafka_events;
