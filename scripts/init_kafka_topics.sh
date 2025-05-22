#!/bin/bash
echo "Creating Kafka topic: events"

TOPIC_NAME="events"

KAFKA_CMD="docker exec -it $(docker ps -qf "ancestor=bitnami/kafka") kafka-topics.sh --bootstrap-server localhost:9092"
EXISTS=$($KAFKA_CMD --list | grep -w "$TOPIC_NAME")

if [ -n "$EXISTS" ]; then
  echo "Topic $TOPIC_NAME exists, deleting..."
  # 删除Topic（需确保delete.topic.enable=true）
  $KAFKA_CMD --delete --topic "$TOPIC_NAME"
  sleep 5
fi

# 重新创建Topic
echo "Recreating Topic $TOPIC_NAME..."
$KAFKA_CMD --create --topic "$TOPIC_NAME" --partitions 1 --replication-factor 1
echo "Topic created successfully!"