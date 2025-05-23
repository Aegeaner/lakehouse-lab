#!/bin/bash

# Script to run Spark-Iceberg examples
set -e

echo "🧪 Lakehouse Lab - Spark Iceberg Examples Runner"
echo "================================================="

# Check if Docker containers are running
echo "🔍 Checking Docker containers..."
if ! docker ps --filter "name=spark-master" --filter "status=running" | grep -q spark-master; then
    echo "❌ Spark master container is not running!"
    echo "💡 Please run: ./start.sh"
    exit 1
fi

if ! docker ps --filter "name=dremio" --filter "status=running" | grep -q dremio; then
    echo "⚠️  Dremio container is not running!"
    echo "💡 Dremio integration examples may fail"
fi

# Function to run examples using spark-shell with piped commands
run_example() {
    local example_name=$1
    local scala_file=$2
    
    echo ""
    echo "🚀 Running example: $example_name"
    echo "------------------------------------"
    
    # Use echo to pipe commands to spark-shell
    docker exec $(docker ps -qf "ancestor=bitnami/spark:latest" -f "label=role=master") bash -c "
        echo ':load /opt/bitnami/spark/jobs/$scala_file
${example_name}.main(Array())
:quit' | spark-shell \
            --jars /opt/bitnami/spark/external-jars/dremio-jdbc-driver-26.0.0-202504290223270716-afdd6663.jar \
            --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.4.2,org.apache.iceberg:iceberg-nessie:1.4.2,org.apache.hadoop:hadoop-aws:3.3.4 \
            --conf 'spark.jars.ivySettings=/opt/bitnami/spark/conf/ivysettings.xml' \
            --conf spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog \
            --conf spark.sql.catalog.iceberg.type=hadoop \
            --conf spark.sql.catalog.iceberg.warehouse=file:///opt/iceberg/warehouse \
            --conf spark.sql.catalog.nessie=org.apache.iceberg.spark.SparkCatalog \
            --conf spark.sql.catalog.nessie.catalog-impl=org.apache.iceberg.nessie.NessieCatalog \
            --conf spark.sql.catalog.nessie.uri=http://nessie:19120/api/v1 \
            --conf spark.sql.catalog.nessie.ref=main \
            --conf spark.sql.catalog.nessie.warehouse=s3a://lakehouse/warehouse \
            --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 \
            --conf spark.hadoop.fs.s3a.access.key=minioadmin \
            --conf spark.hadoop.fs.s3a.secret.key=minioadmin \
            --conf spark.hadoop.fs.s3a.path.style.access=true \
            --conf spark.hadoop.fs.s3a.connection.ssl.enabled=false \
            --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
            --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
    "
}

# Parse command line arguments
case "${1:-simple}" in
    "simple")
        echo "🚀 Running Simple Iceberg Example..."
        run_example "SimpleIcebergExample" "SimpleIcebergExample.scala"
        ;;
    "dremio")
        echo "🚀 Running Dremio Query Example..."
        run_example "SimpleDremioExample" "SimpleDremioExample.scala"
        ;;
    "all")
        echo "🚀 Running All Examples..."
        echo ""
        echo "1️⃣ Running Simple Iceberg Example..."
        run_example "SimpleIcebergExample" "SimpleIcebergExample.scala"
        echo ""
        echo "2️⃣ Running Dremio Query Example..."
        run_example "SimpleDremioExample" "SimpleDremioExample.scala"
        ;;
    "help"|"-h"|"--help")
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  simple       Run simple Iceberg example (default)"
        echo "  dremio       Run Dremio query example"
        echo "  all          Run all examples"
        echo "  help         Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0           # Run simple example"
        echo "  $0 simple    # Run simple example"
        echo "  $0 dremio    # Test Dremio connectivity"
        echo "  $0 all       # Run all examples"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "💡 Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo "✅ Examples execution completed!"
echo ""
echo "📋 Next steps:"
echo "  - Check Iceberg warehouse: ./iceberg-warehouse/"
echo "  - Access Dremio UI: http://localhost:9047"
echo "  - Access Spark UI: http://localhost:8082"
echo "  - Run Spark shell: ./scripts/run_spark_shell.sh"