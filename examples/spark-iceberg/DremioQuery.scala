import org.apache.spark.sql.SparkSession

object DremioQuery {
  def run(spark: SparkSession): Unit = {
    val spark = SparkSession.builder
      .appName("DremioQuery")
      .master("local[*]")
      .getOrCreate()

    try {
      val df = spark.read
        .format("jdbc")
        .option("url", "jdbc:dremio:direct=localhost:31010")
        .option("driver", "com.dremio.jdbc.Driver")
        .option("dbtable", "iceberg.db.sample")
        .option("user", "dremio")
        .option("password", "dremio123")
        .load()

      println(s"Data rows: ${df.count()}")
      df.show()
    } catch {
      case e: Exception => 
        println("JDBC connect failed:")
        e.printStackTrace()
    } finally {
      spark.stop()
    }
  }
}
