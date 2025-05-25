#!/bin/bash
echo "🧨 Stopping and cleaning lakehouse-lab environment..."

docker-compose down -v
docker system prune -f

echo "🧼 Environment cleaned. You may now run ./start.sh to redeploy."
