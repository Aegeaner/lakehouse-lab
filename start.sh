#!/bin/bash
set -e

echo "✅ Starting lakehouse-lab environment..."

# Load .env if present
if [ -f .env ]; then
  echo "🔧 Loading environment variables from .env"
  export $(cat .env | grep -v '#' | xargs)
fi

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker and try again."
  exit 1
fi

# Start all services
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d --remove-orphans

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 10

echo "✅ Environment started successfully!"
echo ""
echo "🧭 Service Endpoints:"
echo "MinIO Console:     http://localhost:9001  (Access Key: $MINIO_ACCESS_KEY)"
echo "Nessie API:        http://localhost:19120"
echo "Trino UI:          http://localhost:8080"
echo "Flink Dashboard:   http://localhost:8081"
echo "Spark UI:          http://localhost:8082"
echo "Dremio UI:         http://localhost:9047"
