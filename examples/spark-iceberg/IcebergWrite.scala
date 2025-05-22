import org.apache.spark.sql.SparkSession

object IcebergWrite {
  def run(spark: SparkSession, warehousePath: String = "file:///opt/iceberg/warehouse"): Unit = {
    try {
      import spark.implicits._
      
      spark.conf.set("spark.sql.catalog.mycatalog", "org.apache.iceberg.spark.SparkCatalog")
      spark.conf.set("spark.sql.catalog.mycatalog.type", "hadoop")
      spark.conf.set("spark.sql.catalog.mycatalog.warehouse", warehousePath)

      spark.sql("DROP TABLE IF EXISTS mycatalog.db.users")
      spark.sql("""
        CREATE TABLE mycatalog.db.users (
          id INT,
          name STRING,
          age INT,
          department STRING,
          join_date STRING
        ) 
        USING iceberg
        PARTITIONED BY (department)
        TBLPROPERTIES (
          'primary-key.columns' = 'id'
        )
      """)
      
      val df = Seq(
        (1, "Alice", 25, "Engineering", "2023-01-01"),
        (2, "Bob", 30, "Marketing", "2023-02-15"),
        (3, "Charlie", 35, "Design", "2023-03-10")
      ).toDF("id", "name", "age", "department", "join_date")
      
      df.writeTo("mycatalog.db.users")
        .partitionedBy($"department") 
        .createOrReplace()
      
      println("Write success!")
      println(s"Written rows: ${df.count()}")
      
    } catch {
      case e: Exception =>
        println("Write failed:")
        e.printStackTrace()
    }
  }
}