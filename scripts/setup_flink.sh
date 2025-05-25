#!/bin/bash

# Setup script for Flink-Iceberg integration
set -e

echo "🚀 Setting up Flink-Iceberg Integration"
echo "======================================="

# Check if required containers are running
echo "🔍 Checking required services..."
REQUIRED_SERVICES=("flink-jobmanager" "flink-taskmanager" "kafka" "nessie")
for service in "${REQUIRED_SERVICES[@]}"; do
    if ! docker ps --filter "name=$service" --filter "status=running" | grep -q $service; then
        echo "❌ $service container is not running!"
        echo "💡 Please run: ./start.sh"
        exit 1
    else
        echo "✅ $service is running"
    fi
done

# Wait for Flink to be ready
echo "⏳ Waiting for Flink to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost:8081/overview > /dev/null 2>&1; then
        echo "✅ Flink is ready!"
        break
    fi
    
    echo "Attempt $attempt/$max_attempts - Flink not ready yet..."
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Flink failed to start within timeout period"
    exit 1
fi

# Create Kafka topics for examples
echo "📊 Creating Kafka topics..."
docker exec kafka-container kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --create --if-not-exists \
    --topic user_events \
    --partitions 3 \
    --replication-factor 1 || echo "ℹ️  Topic user_events may already exist"

docker exec kafka-container kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --create --if-not-exists \
    --topic metrics \
    --partitions 3 \
    --replication-factor 1 || echo "ℹ️  Topic metrics may already exist"

docker exec kafka-container kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --create --if-not-exists \
    --topic cdc_users \
    --partitions 3 \
    --replication-factor 1 || echo "ℹ️  Topic cdc_users may already exist"

# List created topics
echo "📋 Available Kafka topics:"
docker exec kafka-container kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --list

# Download required Flink connectors and place them in Flink lib directory
echo "📦 Setting up Flink connectors..."
docker exec flink-jobmanager bash -c "
    cd /opt/flink/lib
    
    # Download Flink Kafka connector
    if [ ! -f flink-sql-connector-kafka-3.2.0-1.20.jar ]; then
        echo 'Downloading Flink Kafka connector...'
        curl -o flink-sql-connector-kafka-3.2.0-1.20.jar -L \
            'https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.2.0-1.20/flink-sql-connector-kafka-3.2.0-1.20.jar'
    fi
    
    # Download Flink Iceberg connector  
    if [ ! -f iceberg-flink-runtime-1.20-1.6.1.jar ]; then
        echo 'Downloading Flink Iceberg connector...'
        curl -o iceberg-flink-runtime-1.20-1.6.1.jar -L \
            'https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.20/1.6.1/iceberg-flink-runtime-1.20-1.6.1.jar'
    fi
    
    # Download Hadoop AWS (for S3 support)
    if [ ! -f hadoop-aws-3.3.4.jar ]; then
        echo 'Downloading Hadoop AWS connector...'
        curl -o hadoop-aws-3.3.4.jar -L \
            'https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar'
    fi
    
    # Download AWS SDK
    if [ ! -f aws-java-sdk-bundle-1.12.262.jar ]; then
        echo 'Downloading AWS SDK...'
        curl -o aws-java-sdk-bundle-1.12.262.jar -L \
            'https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar'
    fi
    
    echo 'Connector setup completed!'
"

# Restart Flink to load new connectors
echo "🔄 Restarting Flink to load connectors..."
docker restart flink-jobmanager flink-taskmanager

# Wait for Flink to restart
echo "⏳ Waiting for Flink to restart..."
sleep 30

attempt=1
while [ $attempt -le 20 ]; do
    if curl -f http://localhost:8081/overview > /dev/null 2>&1; then
        echo "✅ Flink restarted successfully!"
        break
    fi
    
    echo "Attempt $attempt/20 - Waiting for Flink restart..."
    sleep 5
    attempt=$((attempt + 1))
done

# Check if Python dependencies are available for data generation
echo "🐍 Checking Python dependencies for data generation..."
if command -v python3 &> /dev/null; then
    echo "✅ Python3 is available"
    
    # Try to install kafka-python if pip is available
    if command -v pip3 &> /dev/null; then
        echo "📦 Installing kafka-python..."
        pip3 install kafka-python --quiet || echo "⚠️  Could not install kafka-python automatically"
    else
        echo "⚠️  pip3 not available - you may need to install kafka-python manually"
        echo "    Run: pip install kafka-python"
    fi
else
    echo "⚠️  Python3 not available - data generation scripts will not work"
    echo "    Install Python3 to use the data generator"
fi

echo ""
echo "📋 Flink-Iceberg Setup Instructions"
echo "==================================="
echo ""
echo "🌐 1. Access Flink UI: http://localhost:8081"
echo ""
echo "📊 2. Run example SQL scripts:"
echo "   - Simple streaming: ./scripts/run_flink_examples.sh simple"
echo "   - Windowed aggregations: ./scripts/run_flink_examples.sh windowed"
echo "   - CDC processing: ./scripts/run_flink_examples.sh cdc"
echo ""
echo "🔄 3. Generate sample data:"
echo "   - User events: python3 scripts/generate_sample_data.py --data-type user_events"
echo "   - Metrics: python3 scripts/generate_sample_data.py --data-type metrics"
echo "   - CDC events: python3 scripts/generate_sample_data.py --data-type cdc"
echo "   - All types: python3 scripts/generate_sample_data.py --data-type all"
echo ""
echo "🔍 4. Monitor progress:"
echo "   - Flink UI: http://localhost:8081"
echo "   - Check Iceberg tables: ./scripts/run_examples.sh simple"
echo ""
echo "✅ Flink-Iceberg setup completed!"