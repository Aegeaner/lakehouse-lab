# 🚨 Dremio OSS Limitations

This document explains the limitations of Dremio OSS in the lakehouse-lab environment.

## ❌ **What Doesn't Work in Dremio OSS:**

### 1. **Iceberg Native Support**
- ❌ No Iceberg connector in source options
- ❌ No Iceberg metadata catalog integration
- ❌ Cannot query Iceberg tables directly with schema evolution, time travel, etc.

### 2. **MinIO/Custom S3 Endpoints**
- ❌ No endpoint field in S3 source configuration
- ❌ Only works with real AWS S3 endpoints
- ❌ Cannot connect to local MinIO instance
- ❌ S3-compatible storage requires Dremio Enterprise/Cloud

### 3. **Advanced Features**
- ❌ Limited to basic SQL operations
- ❌ No advanced data lake features
- ❌ No custom connector development

## ✅ **What Does Work in Dremio OSS:**

### 1. **File System Access**
- ✅ File System source for local directories
- ✅ NAS source for network attached storage
- ✅ Direct Parquet file querying
- ✅ Basic SQL operations on files

### 2. **JDBC Connectivity**
- ✅ JDBC driver works for programmatic access
- ✅ Basic query execution
- ✅ Integration with Spark via JDBC

### 3. **Data Browsing**
- ✅ Browse directory structures
- ✅ Preview file contents
- ✅ Basic data exploration

## 🔧 **Working Configuration for This Lab:**

### File System Source Setup:
```
Source Type: File System
Name: iceberg_warehouse
Root Path: /opt/iceberg/warehouse
```

### What You Can Do:
1. **Browse Iceberg warehouse files**
   - Navigate through partition directories
   - View Parquet files created by Spark
   - Explore data structure

2. **Query Parquet files directly**
   ```sql
   SELECT * FROM iceberg_warehouse."db/users/data/department=Engineering/file.parquet"
   ```

3. **Basic analytics on files**
   ```sql
   SELECT department, COUNT(*) 
   FROM iceberg_warehouse."db/users/data/department=Engineering/file.parquet"
   GROUP BY department
   ```

## 💡 **Recommendations:**

### For Full Iceberg Experience:
- **Use Spark directly** for Iceberg operations
- **Use Trino** (included in docker-compose) for better Iceberg support
- **Consider Dremio Cloud/Enterprise** for production use

### For This Demo Environment:
1. **Primary**: Spark + Iceberg integration
2. **Secondary**: Dremio for basic file browsing and querying
3. **Alternative**: Trino for more advanced Iceberg queries

## 🎯 **Realistic Use Cases for Dremio OSS:**

1. **Data Lake File Explorer**
   - Browse and discover data files
   - Quick data previews
   - Basic data quality checks

2. **Simple Analytics**
   - Ad-hoc queries on Parquet files
   - Basic reporting on file-based data
   - Data validation queries

3. **JDBC Integration**
   - Connect BI tools via JDBC
   - Programmatic data access
   - Simple data extraction

## 📋 **Summary:**

Dremio OSS is useful for **basic file querying and browsing** but lacks the advanced features needed for full lakehouse operations. For this lab:

- **Spark** = Full Iceberg feature set ✅
- **Dremio OSS** = File browsing and basic queries ✅
- **MinIO integration** = Not available in OSS ❌
- **Native Iceberg** = Not available in OSS ❌

This is actually representative of real-world open source vs. enterprise tool differences!