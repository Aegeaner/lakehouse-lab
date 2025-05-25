#!/bin/bash
set -e

echo "🔧 Setting up Trino integration..."

# Check if Trino container is running
if ! docker ps | grep -q trino; then
    echo "❌ Trino container is not running. Please start the environment first with ./start.sh"
    exit 1
fi

# Wait for Trino to be ready
echo "⏳ Waiting for Trino to be ready..."
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -sf http://localhost:8084/v1/info > /dev/null 2>&1; then
        echo "✅ Trino is ready!"
        break
    fi
    echo "Waiting for Trino... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "❌ Timeout waiting for Trino to start"
    exit 1
fi

# Check Nessie is ready
echo "⏳ Checking Nessie catalog service..."
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -sf http://localhost:19120/api/v1/trees > /dev/null 2>&1; then
        echo "✅ Nessie catalog is ready!"
        break
    fi
    echo "Waiting for Nessie... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "❌ Timeout waiting for Nessie to start"
    exit 1
fi

# Check MinIO is ready
echo "⏳ Checking MinIO storage..."
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        echo "✅ MinIO storage is ready!"
        break
    fi
    echo "Waiting for MinIO... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "❌ Timeout waiting for MinIO to start"
    exit 1
fi

# Create MinIO bucket for lakehouse data
echo "🪣 Setting up MinIO bucket..."
docker exec minio mc alias set local http://localhost:9000 minioadmin minioadmin
docker exec minio mc mb local/lakehouse --ignore-existing

echo "✅ Trino setup completed successfully!"
echo ""
echo "🎯 You can now:"
echo "1. Connect to Trino CLI: docker exec -it trino trino"
echo "2. Access Trino Web UI: http://localhost:8084"
echo "3. Run example queries from examples/trino-iceberg/"
echo "4. Use ./scripts/test_trino.sh to run basic tests"