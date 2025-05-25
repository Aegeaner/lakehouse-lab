# 🚀 Trino-Iceberg Integration Guide

This document provides a comprehensive guide for using Trino with Apache Iceberg in the lakehouse-lab environment.

## 📋 Overview

Trino is a fast distributed SQL query engine designed for interactive analytics queries against data sources of all sizes. In this lab, Trino provides:

- **High-performance SQL queries** on Iceberg tables
- **Advanced analytics capabilities** with window functions, complex aggregations
- **Time travel queries** for historical data analysis
- **Schema evolution support** for flexible data models
- **Cross-catalog joins** between different data sources

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Trino     │    │   Nessie    │    │    MinIO    │
│   Query     │◄───┤   Catalog   │◄───┤   Storage   │
│   Engine    │    │   Service   │    │   (S3-like) │
└─────────────┘    └─────────────┘    └─────────────┘
       │
       ▼
┌─────────────┐
│   Iceberg   │
│   Tables    │
└─────────────┘
```

**Components:**
- **Trino**: SQL query engine and coordinator
- **Nessie**: Git-like catalog for data versioning
- **MinIO**: S3-compatible object storage
- **PostgreSQL**: Metadata store for Nessie
- **Iceberg**: Table format for analytics

## 🚀 Quick Start

### 1. Start the Environment
```bash
./start.sh
```

### 2. Setup Trino Integration
```bash
./scripts/setup_trino.sh
```

### 3. Test the Setup
```bash
./scripts/test_trino.sh
```

### 4. Run Examples
```bash
# Run all examples
./scripts/run_trino_examples.sh

# Run specific examples
./scripts/run_trino_examples.sh basic
./scripts/run_trino_examples.sh analytics
./scripts/run_trino_examples.sh schema
./scripts/run_trino_examples.sh timetravel
```

## 🔧 Configuration

### Trino Configuration Files

Located in `config/trino/`:

#### `config.properties`
```properties
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8084
query.max-memory=1GB
query.max-memory-per-node=512MB
discovery-server.enabled=true
discovery.uri=http://localhost:8084
```

#### `catalog/iceberg.properties`
```properties
connector.name=iceberg
iceberg.catalog.type=nessie
iceberg.nessie.uri=http://nessie:19120/api/v1
iceberg.nessie.default-warehouse-dir=s3://lakehouse/iceberg
hive.s3.endpoint=http://minio:9000
hive.s3.path-style-access=true
hive.s3.aws-access-key=minioadmin
hive.s3.aws-secret-key=minioadmin
hive.s3.ssl.enabled=false
```

## 💻 Using Trino

### Connecting to Trino

#### CLI Access
```bash
# Interactive CLI
docker exec -it trino trino

# Execute single command
docker exec trino trino --execute "SHOW CATALOGS"
```

#### Web UI
Access the Trino Web UI at: http://localhost:8084

#### JDBC Connection
```
URL: jdbc:trino://localhost:8084
Catalog: iceberg
Schema: <your_schema>
User: any_user_name
```

### Available Catalogs

1. **iceberg** - Iceberg tables with Nessie catalog
2. **minio** - Direct Hive access to MinIO
3. **memory** - Temporary in-memory tables

## 📚 Examples Overview

### 1. Basic Operations (`examples/trino-iceberg/basic_queries.sql`)

```sql
-- Create schema
CREATE SCHEMA iceberg.demo;

-- Create table
CREATE TABLE iceberg.demo.customers (
    id BIGINT,
    name VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
) WITH (format = 'PARQUET');

-- Insert data
INSERT INTO iceberg.demo.customers VALUES
(1, 'John Doe', 'john@example.com', CURRENT_TIMESTAMP);

-- Query data
SELECT * FROM iceberg.demo.customers;
```

### 2. Advanced Analytics (`examples/trino-iceberg/advanced_analytics.sql`)

```sql
-- Partitioned table for performance
CREATE TABLE iceberg.analytics.sales (
    id BIGINT,
    amount DECIMAL(10,2),
    sale_date DATE,
    region VARCHAR
) WITH (
    format = 'PARQUET',
    partitioning = ARRAY['region', 'sale_date']
);

-- Window functions
SELECT 
    sale_date,
    region,
    amount,
    SUM(amount) OVER (
        PARTITION BY region 
        ORDER BY sale_date 
        ROWS UNBOUNDED PRECEDING
    ) as running_total
FROM iceberg.analytics.sales;
```

### 3. Schema Evolution (`examples/trino-iceberg/schema_evolution.sql`)

```sql
-- Add columns to existing table
ALTER TABLE iceberg.evolution.user_profiles 
ADD COLUMN age INTEGER;

ALTER TABLE iceberg.evolution.user_profiles 
ADD COLUMN status VARCHAR DEFAULT 'active';

-- Rename columns
ALTER TABLE iceberg.evolution.user_profiles 
RENAME COLUMN username TO user_name;
```

### 4. Time Travel (`examples/trino-iceberg/time_travel.sql`)

```sql
-- Query historical snapshots
SELECT * FROM iceberg.timetravel.inventory 
FOR VERSION AS OF 123456789;

-- Show table history
SELECT * FROM iceberg.timetravel."inventory$history";

-- Show snapshots
SELECT * FROM iceberg.timetravel."inventory$snapshots";
```

## 🔍 Metadata Queries

### Table Information
```sql
-- List all tables
SELECT * FROM iceberg.information_schema.tables;

-- Show table structure
DESCRIBE iceberg.demo.customers;

-- Show create statement
SHOW CREATE TABLE iceberg.demo.customers;
```

### Iceberg-Specific Metadata
```sql
-- Table snapshots
SELECT * FROM iceberg.demo."customers$snapshots";

-- Table history
SELECT * FROM iceberg.demo."customers$history";

-- Table files
SELECT * FROM iceberg.demo."customers$files";

-- Partition information
SELECT * FROM iceberg.demo."customers$partitions";
```

## ⚡ Performance Tips

### 1. Partitioning
```sql
-- Create partitioned table
CREATE TABLE iceberg.perf.events (
    id BIGINT,
    event_date DATE,
    region VARCHAR,
    data JSON
) WITH (
    format = 'PARQUET',
    partitioning = ARRAY['region', 'event_date']
);
```

### 2. Query Optimization
```sql
-- Use partition pruning
SELECT * FROM iceberg.perf.events 
WHERE region = 'US' AND event_date = DATE '2024-01-01';

-- Projection pushdown
SELECT id, region FROM iceberg.perf.events 
WHERE region = 'US';
```

### 3. Columnar Storage Benefits
- **Parquet format** provides excellent compression
- **Column pruning** reduces I/O
- **Predicate pushdown** improves filtering

## 🔧 Troubleshooting

### Common Issues

#### 1. Trino Not Starting
```bash
# Check container logs
docker logs trino

# Verify configuration
docker exec trino cat /etc/trino/config.properties
```

#### 2. Catalog Connection Issues
```bash
# Test Nessie connectivity
curl http://localhost:19120/api/v1/trees

# Test MinIO connectivity
curl http://localhost:9000/minio/health/live
```

#### 3. Query Failures
```sql
-- Check query information
SELECT * FROM system.runtime.queries 
WHERE state = 'FAILED' 
ORDER BY created DESC;
```

### Performance Debugging
```sql
-- Monitor running queries
SELECT 
    query_id,
    state,
    query,
    cumulative_memory,
    elapsed_time
FROM system.runtime.queries 
WHERE state = 'RUNNING';

-- Check node resources
SELECT * FROM system.runtime.nodes;
```

## 🌟 Advanced Features

### 1. Cross-Catalog Queries
```sql
-- Join data across catalogs
SELECT 
    i.customer_id,
    m.customer_name
FROM iceberg.sales.orders i
JOIN memory.default.customers m ON i.customer_id = m.id;
```

### 2. Data Migration
```sql
-- Migrate data from Hive to Iceberg
CREATE TABLE iceberg.migration.new_table 
AS SELECT * FROM minio.default.old_table;
```

### 3. Data Quality Checks
```sql
-- Check for duplicates
SELECT customer_id, COUNT(*) 
FROM iceberg.demo.customers 
GROUP BY customer_id 
HAVING COUNT(*) > 1;

-- Data profiling
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT customer_id) as unique_customers,
    MIN(created_at) as oldest_record,
    MAX(created_at) as newest_record
FROM iceberg.demo.customers;
```

## 🔐 Security Considerations

### Access Control
- Trino supports **system access control** and **catalog access control**
- For production: implement **authentication** and **authorization**
- Current setup: **development mode** with no authentication

### Data Encryption
- **MinIO encryption**: Configure server-side encryption
- **Trino encryption**: Enable HTTPS for client connections
- **Iceberg encryption**: Table-level encryption support

## 🚀 Production Recommendations

### 1. Scaling
- **Multi-node Trino cluster** for production workloads
- **Dedicated coordinators** and workers
- **Resource isolation** per workload

### 2. Monitoring
- **Query performance** monitoring
- **Resource utilization** tracking  
- **Data freshness** validation

### 3. Backup & Recovery
- **Nessie backup** strategies
- **MinIO replication** setup
- **Disaster recovery** planning

## 📊 Integration with Other Tools

### BI Tools
- **Tableau**: Use Trino JDBC driver
- **Power BI**: Connect via ODBC/JDBC
- **Grafana**: SQL data source integration

### Programming Languages
```python
# Python with trino-python-client
import trino

conn = trino.dbapi.connect(
    host='localhost',
    port=8084,
    user='user',
    catalog='iceberg',
    schema='demo'
)

cursor = conn.cursor()
cursor.execute('SELECT * FROM customers')
rows = cursor.fetchall()
```

### Data Science
- **Jupyter notebooks** with Trino magic commands
- **Apache Spark** integration via JDBC
- **Apache Airflow** for ETL workflows

## 📈 Next Steps

1. **Explore advanced SQL features** in Trino
2. **Integrate with BI tools** using JDBC/ODBC
3. **Set up automated data pipelines** with Apache Airflow
4. **Implement monitoring** and alerting
5. **Scale to multi-node cluster** for production

## 🎯 Summary

The Trino-Iceberg integration provides:

- ✅ **High-performance analytics** on lakehouse data
- ✅ **ACID transactions** with consistency guarantees  
- ✅ **Schema evolution** without data rewrites
- ✅ **Time travel** for historical analysis
- ✅ **Scalable architecture** for growing datasets
- ✅ **Standard SQL interface** for familiar querying

This setup demonstrates a modern lakehouse architecture suitable for both experimental and production workloads.