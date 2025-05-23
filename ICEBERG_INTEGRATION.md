# 🧊 Iceberg Integration Guide

This guide provides clean, focused examples for using Apache Iceberg with Spark and Dremio in the lakehouse-lab environment.

## 🚀 Quick Start

1. **Start the environment:**
   ```bash
   ./start.sh
   ```

2. **Wait for all services to be ready** (especially Dremio, which takes ~2-3 minutes)

3. **Run the examples:**
   ```bash
   # Run simple Iceberg example (default)
   ./scripts/run_examples.sh

   # Or run specific examples
   ./scripts/run_examples.sh simple    # Basic Iceberg operations
   ./scripts/run_examples.sh dremio    # Dremio connectivity test
   ./scripts/run_examples.sh all       # Run all examples
   ```

4. **Setup Dremio integration:**
   ```bash
   ./scripts/setup_dremio.sh
   ```

## 📋 What's Been Enhanced

### ✅ Fixed Issues
- **Spark-Iceberg Integration**: Proper catalog configuration with extensions
- **Schema Creation**: Automated Iceberg table schema creation
- **Data Types**: Enhanced with proper DATE, TIMESTAMP, and DECIMAL types
- **Partitioning**: Improved partitioning strategies for better performance
- **Dremio Connectivity**: Fixed JDBC connection and query examples
- **Error Handling**: Comprehensive error handling and diagnostics
- **Simplified Codebase**: Removed complex examples, keeping only essential ones

### 🆕 Current Examples

## 📂 Example Structure

### 1. SimpleIcebergExample.scala
- Basic Iceberg table creation and operations
- Clean data ingestion with proper types
- Partition management demonstration
- Table metadata exploration
- Data verification and queries

### 2. SimpleDremioExample.scala  
- Tests Dremio JDBC connectivity
- Provides comprehensive setup instructions
- Error handling and diagnostics
- **Note**: Dremio OSS has limited Iceberg support (file browsing only)

## 🔧 Configuration Details

### Spark Configuration
The following configurations are now properly set:

```properties
# Iceberg catalog
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hadoop
spark.sql.catalog.iceberg.warehouse=file:///opt/iceberg/warehouse

# Nessie catalog (for versioning)
spark.sql.catalog.nessie=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.nessie.catalog-impl=org.apache.iceberg.nessie.NessieCatalog
spark.sql.catalog.nessie.uri=http://nessie:19120/api/v1

# S3A for MinIO integration
spark.hadoop.fs.s3a.endpoint=http://minio:9000
spark.hadoop.fs.s3a.access.key=minioadmin
spark.hadoop.fs.s3a.secret.key=minioadmin
spark.hadoop.fs.s3a.path.style.access=true

# Iceberg extensions
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
```

### Dremio Integration
- Manual setup instructions for Dremio configuration
- File System source for browsing Iceberg warehouse
- JDBC connectivity examples
- **Limitations**: 
  - Dremio OSS doesn't have full Iceberg metadata support
  - No custom S3 endpoint support (MinIO integration not available)

## 📊 Sample Data Schema

The SimpleIcebergExample creates:

### iceberg.demo.employees
```sql
id BIGINT
name STRING  
department STRING
salary DECIMAL(10,2)
hire_date DATE
-- PARTITIONED BY (department)
```

## 🎯 Key Features Demonstrated

### 1. Basic Iceberg Operations
```scala
// Create namespace and table
spark.sql("CREATE NAMESPACE IF NOT EXISTS iceberg.demo")
spark.sql("CREATE TABLE iceberg.demo.employees ...")

// Insert data with proper types
employeesData.writeTo("iceberg.demo.employees").append()
```

### 2. Metadata Exploration
```scala
// Show partitions
spark.sql("SELECT partition, record_count FROM iceberg.demo.employees.partitions")

// Show snapshots
spark.sql("SELECT snapshot_id, committed_at FROM iceberg.demo.employees.snapshots")
```

### 3. Simple Analytics
```scala
// Department analysis
spark.sql("""
  SELECT department, COUNT(*) as employee_count, AVG(salary) as avg_salary
  FROM iceberg.demo.employees
  GROUP BY department
""")
```

## 🔍 Troubleshooting

### Common Issues

1. **Dremio connection fails**
   - Wait for Dremio to fully start (2-3 minutes)
   - Run `./scripts/setup_dremio.sh` to configure sources
   - Check Dremio UI at http://localhost:9047

2. **MinIO S3 source fails**
   - Dremio OSS doesn't support custom S3 endpoints
   - Use File System source instead for local data access
   - MinIO integration requires Dremio Enterprise/Cloud

3. **Permission errors on warehouse**
   - Ensure proper file permissions on `./iceberg-warehouse`
   - Check Docker volume mounts

### Verification Steps

1. **Check containers are running:**
   ```bash
   docker ps
   ```

2. **Verify Iceberg warehouse:**
   ```bash
   ls -la ./iceberg-warehouse/
   ```

3. **Access UIs:**
   - Spark Master: http://localhost:8082
   - Dremio: http://localhost:9047
   - MinIO: http://localhost:9001

## 📚 Additional Resources

- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Spark-Iceberg Integration](https://iceberg.apache.org/docs/latest/spark-configuration/)
- [Dremio with Iceberg](https://docs.dremio.com/data-sources/object/iceberg/)

---

🎉 **Happy Iceberging!** This clean setup provides a focused foundation for exploring data lakehouse patterns with Apache Iceberg.