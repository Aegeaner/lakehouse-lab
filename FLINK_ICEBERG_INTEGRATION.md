# 🌊 Flink-Iceberg Integration Guide

This guide provides comprehensive Flink-Iceberg streaming integration with working examples and automation scripts.

## 🚀 Quick Start

### 1. **Setup Environment**
```bash
# Start all services
./start.sh

# Setup Flink-Iceberg integration
./scripts/setup_flink_iceberg.sh
```

### 2. **Run Examples**
```bash
# Generate sample data
python3 scripts/generate_sample_data.py --data-type all

# Run streaming examples
./scripts/run_flink_example.sh simple
./scripts/run_flink_example.sh windowed
./scripts/run_flink_example.sh cdc
```

### 3. **Monitor Results**
- **Flink UI**: http://localhost:8081
- **Check Iceberg tables**: `./scripts/run_examples.sh simple`

## 📂 Example Structure

### 1. **Simple Iceberg Streaming** (`simple_iceberg_streaming.sql`)
**Purpose**: Basic Kafka → Flink → Iceberg pipeline
**Features**:
- Kafka source table for user events
- Real-time streaming to Iceberg
- Partitioned by event type
- Processing timestamp enrichment

**Data Flow**:
```
Kafka Topic (user_events) → Flink → Iceberg Table (streaming.user_events)
```

### 2. **Windowed Aggregations** (`windowed_aggregations.sql`)
**Purpose**: Time-based aggregations with tumbling windows
**Features**:
- Hourly metrics aggregation
- Multiple aggregation functions (AVG, MIN, MAX, COUNT)
- Partitioned by location and date
- Watermark-based event time processing

**Data Flow**:
```
Kafka Topic (metrics) → Flink Tumbling Windows → Iceberg Table (streaming.metrics_hourly)
```

### 3. **Change Data Capture** (`cdc_to_iceberg.sql`)
**Purpose**: CDC event processing and state management
**Features**:
- CDC event parsing (INSERT, UPDATE, DELETE)
- Current state maintenance with upserts
- Complete audit trail
- Primary key handling

**Data Flow**:
```
Kafka Topic (cdc_users) → Flink CDC Processor → {
    Iceberg Table (streaming.users_current) [Current State]
    Iceberg Table (streaming.users_audit) [Audit Trail]
}
```

## 🔧 Technical Architecture

### **Flink Configuration**
- **Parallelism**: 2 (configurable)
- **State Backend**: RocksDB
- **Checkpointing**: File-based with persistence
- **Watermarks**: 5-10 seconds lateness tolerance

### **Iceberg Integration**
- **Catalog Type**: Hadoop (file-based)
- **Format Version**: 2 (supports row-level operations)
- **Warehouse**: `/opt/iceberg/warehouse`
- **Partitioning**: Strategic by high-cardinality columns

### **Kafka Integration**
- **Consumer Groups**: Dedicated per job
- **Startup Mode**: Earliest offset for demos
- **Serialization**: JSON format with timestamp handling
- **Topics**: 3 partitions, 1 replica (development setup)

## 🎯 Learning Objectives

### **Streaming Concepts**
1. **Event Time vs Processing Time**
   - Understanding watermarks and late data handling
   - Event time extraction and timestamp assignment
   - Window triggering based on event time

2. **Exactly-Once Processing**
   - Kafka offset management
   - Flink checkpointing for fault tolerance
   - Iceberg ACID transactions

3. **Windowing Operations**
   - Tumbling windows for regular aggregations
   - Sliding windows for overlapping analysis
   - Session windows for user behavior analysis

### **Data Lake Patterns**
1. **Lambda Architecture Alternative**
   - Real-time streaming layer
   - Batch processing for historical data
   - Unified query interface through Iceberg

2. **Change Data Capture (CDC)**
   - Event sourcing patterns
   - State reconstruction from events
   - Maintaining current vs historical views

3. **Schema Evolution**
   - Adding new columns without breaking pipelines
   - Handling data type changes
   - Version compatibility across services

### **Operational Practices**
1. **Monitoring and Observability**
   - Job metrics and performance monitoring
   - Data quality validation
   - Pipeline health checks

2. **Error Handling**
   - Dead letter queues for poison messages
   - Retry strategies for transient failures
   - Data validation and cleansing

3. **Scalability Patterns**
   - Horizontal scaling with multiple task managers
   - Partitioning strategies for throughput
   - Resource management and optimization

## 🧪 Testing Procedures

### **1. End-to-End Pipeline Test**
```bash
# 1. Setup environment
./scripts/setup_flink_iceberg.sh

# 2. Start simple streaming job
./scripts/run_flink_example.sh simple

# 3. Generate test data
python3 scripts/generate_sample_data.py --data-type user_events --count 50

# 4. Verify data in Iceberg
./scripts/run_examples.sh simple
# Look for: iceberg.streaming.user_events table

# 5. Check Flink UI for job metrics
# Visit: http://localhost:8081
```

### **2. Windowed Aggregation Test**
```bash
# 1. Start aggregation job
./scripts/run_flink_example.sh windowed

# 2. Generate continuous metrics
python3 scripts/generate_sample_data.py --data-type metrics --count 200 --delay 0.5

# 3. Wait for window to complete (1 hour in production, faster in demo)
# 4. Check aggregated results in Iceberg
```

### **3. CDC Processing Test**
```bash
# 1. Start CDC processor
./scripts/run_flink_example.sh cdc

# 2. Generate CDC events
python3 scripts/generate_sample_data.py --data-type cdc --count 30 --delay 2

# 3. Verify both current state and audit trail tables
# - streaming.users_current (latest state)
# - streaming.users_audit (change history)
```

### **4. Interactive Testing**
```bash
# Start interactive SQL CLI
./scripts/run_flink_example.sh interactive

# Run queries:
SHOW TABLES;
DESCRIBE iceberg_user_events;
SELECT COUNT(*) FROM iceberg_user_events;
SELECT event_type, COUNT(*) FROM iceberg_user_events GROUP BY event_type;
```

## 📊 Data Validation

### **Data Quality Checks**
1. **Count Validation**
   ```sql
   -- Compare Kafka input vs Iceberg output counts
   SELECT COUNT(*) FROM iceberg_user_events;
   ```

2. **Duplicate Detection**
   ```sql
   -- Check for duplicate processing
   SELECT user_id, event_time, COUNT(*) 
   FROM iceberg_user_events 
   GROUP BY user_id, event_time 
   HAVING COUNT(*) > 1;
   ```

3. **Partition Verification**
   ```sql
   -- Verify partitioning is working
   SELECT event_type, COUNT(*) 
   FROM iceberg_user_events 
   GROUP BY event_type;
   ```

### **Performance Metrics**
- **Throughput**: Events processed per second
- **Latency**: End-to-end processing time
- **Backpressure**: Queue depth and processing delays
- **Resource Utilization**: CPU, memory, and network usage

## 🔍 Troubleshooting

### **Common Issues**

1. **Connector Not Found**
   ```
   Error: Could not find any factory for identifier 'iceberg'
   ```
   **Solution**: Run `./scripts/setup_flink_iceberg.sh` to download connectors

2. **Kafka Connection Refused**
   ```
   Error: Connection to node -1 could not be established
   ```
   **Solution**: Ensure Kafka container is running and accessible

3. **Checkpoint Failures**
   ```
   Error: Could not checkpoint state
   ```
   **Solution**: Check disk space and checkpoint directory permissions

4. **Schema Evolution Errors**
   ```
   Error: Schema compatibility check failed
   ```
   **Solution**: Use Iceberg's schema evolution features or recreate tables

### **Debug Commands**
```bash
# Check Flink logs
docker logs flink-jobmanager
docker logs flink-taskmanager

# Check Kafka topics
docker exec kafka-container kafka-topics.sh --bootstrap-server localhost:9092 --list

# Check Kafka messages
docker exec kafka-container kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic user_events \
  --from-beginning --max-messages 10

# Monitor job status
curl -s http://localhost:8081/jobs | python3 -m json.tool
```

## 🎓 Advanced Concepts

### **1. Exactly-Once Semantics**
Learn how Flink achieves exactly-once processing through:
- **Two-Phase Commit Protocol**: Coordinated commits across sources and sinks
- **Checkpointing**: Consistent snapshots of application state
- **Idempotent Operations**: Safe replay of events

### **2. Complex Event Processing**
Explore advanced patterns:
- **Pattern Detection**: Using Flink CEP for fraud detection
- **Session Windows**: Grouping events by user sessions
- **Late Data Handling**: Dealing with out-of-order events

### **3. Schema Registry Integration**
Future enhancements:
- **Confluent Schema Registry**: Centralized schema management
- **Avro/Protobuf**: Efficient serialization formats
- **Schema Evolution**: Backward/forward compatibility

### **4. Multi-Tenant Architectures**
Scaling considerations:
- **Namespace Isolation**: Separate Iceberg databases per tenant
- **Resource Allocation**: CPU/memory limits per tenant
- **Security**: Authentication and authorization

## 📈 Production Considerations

### **Deployment Strategies**
1. **Blue-Green Deployments**: Zero-downtime updates
2. **Canary Releases**: Gradual rollout of changes
3. **A/B Testing**: Feature validation with live traffic

### **Monitoring and Alerting**
1. **Application Metrics**: Custom business metrics
2. **Infrastructure Metrics**: System health monitoring
3. **Data Quality Metrics**: Automated data validation

### **Disaster Recovery**
1. **Cross-Region Replication**: Data durability
2. **Backup Strategies**: Point-in-time recovery
3. **Failover Procedures**: Automated recovery processes

---

🎉 **Congratulations!** You now have a complete understanding of Flink-Iceberg streaming integration with practical, hands-on experience in modern data lake architectures.