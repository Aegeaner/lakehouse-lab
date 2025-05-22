-- Simulate a Dremio query using Flink SQL catalog lookup
-- Assume Dremio is mounted on catalog as iceberg.db.sample

SELECT * FROM iceberg_sink LIMIT 10;
