# 🧪 lakehouse-lab

本项目提供一个本地一键部署的 Lakehouse 实验环境，包含 Kafka、Flink、Spark、Trino、MinIO、Nessie 和 Dremio OSS，支持 Scala 操作 Iceberg 表及 Kafka → Flink → Iceberg 的流处理示例。

## ✅ 包含内容

- Spark、Flink、Kafka、MinIO、Trino、Nessie、Dremio OSS
- Scala 示例：Spark 写入 Iceberg 表
- Flink SQL：Kafka 流式写入 Iceberg 表
- Apache 2.0 License

## ⚠️ 重要说明

- **Dremio OSS 限制**: 不支持原生 Iceberg 连接器和自定义 S3 端点
- **完整 Iceberg 体验**: 请使用 Spark 进行 Iceberg 操作
- **详细限制说明**: 见 `DREMIO_OSS_LIMITATIONS.md`

## 🚀 快速启动

```bash
chmod +x start.sh reset.sh scripts/*.sh
./start.sh
