# 🧪 lakehouse-lab

本项目提供一个本地一键部署的 Lakehouse 实验环境，包含 Kafka、Flink、Spark、Trino、MinIO、Nessie 和 Dremio OSS，支持 Scala 操作 Iceberg 表及 Kafka → Flink → Iceberg 的流处理示例。

## ✅ 包含内容

- **数据处理引擎**: Spark、Flink、Kafka、MinIO、Trino、Nessie、Dremio OSS
- **Spark 示例**: Scala 操作 Iceberg 表，批处理分析
- **Flink 示例**: 实时流处理，Kafka → Flink → Iceberg 管道
- **多种用例**: 简单流处理、窗口聚合、CDC 处理
- **自动化脚本**: 一键部署、数据生成、测试验证
- **Apache 2.0 License**

## ⚠️ 重要说明

- **Dremio OSS 限制**: 不支持原生 Iceberg 连接器和自定义 S3 端点
- **完整 Iceberg 体验**: Spark (批处理) + Flink (流处理)
- **详细说明文档**: 
  - Spark 集成: `ICEBERG_INTEGRATION.md`
  - Flink 集成: `FLINK_ICEBERG_INTEGRATION.md`
  - Dremio 限制: `DREMIO_OSS_LIMITATIONS.md`

## 🚀 快速启动

### 1. 启动环境
```bash
chmod +x start.sh reset.sh scripts/*.sh
./start.sh
```

### 2. Spark-Iceberg 批处理
```bash
# 运行 Spark 示例
./scripts/run_examples.sh simple

# 配置 Dremio (可选)
./scripts/setup_dremio.sh
```

### 3. Flink-Iceberg 流处理
```bash
# 设置 Flink 集成
./scripts/setup_flink_iceberg.sh

# 生成测试数据
python3 scripts/generate_sample_data.py --data-type all

# 运行流处理示例
./scripts/run_flink_example.sh simple

# 运行完整测试
./scripts/test_flink_iceberg.sh
```

### 4. 访问 UI
- **Flink**: http://localhost:8081
- **Spark**: http://localhost:8082  
- **Dremio**: http://localhost:9047
- **MinIO**: http://localhost:9001
