#!/bin/bash
docker exec -it $(docker ps -qf "ancestor=bitnami/spark:latest" -f "label=role=master") spark-shell \
--jars /opt/bitnami/spark/external-jars/dremio-jdbc-driver-26.0.0-202504290223270716-afdd6663.jar \
--packages org.apache.iceberg:iceberg-spark-runtime-3.3_2.12:1.4.2 \
--conf "spark.jars.ivySettings=/opt/bitnami/spark/conf/ivysettings.xml" \
--conf spark.sql.catalog.nessie=org.apache.iceberg.spark.SparkCatalog \
--conf spark.sql.catalog.nessie.catalog-impl=org.apache.iceberg.nessie.NessieCatalog \
--conf spark.sql.catalog.nessie.uri=http://nessie:19120/api/v1 \
--conf spark.sql.catalog.nessie.ref=main \
--conf spark.sql.catalog.nessie.warehouse=s3a://lakehouse/warehouse \
--conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 \
--conf spark.hadoop.fs.s3a.access.key=minioadmin \
--conf spark.hadoop.fs.s3a.secret.key=minioadmin \
--conf spark.hadoop.fs.s3a.path.style.access=true \
--conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem