import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

object SimpleIcebergExample {
  def main(args: Array[String]): Unit = {
    println("🚀 Starting Simple Iceberg Example...")
    
    val spark = SparkSession.builder
      .appName("SimpleIcebergExample")
      .getOrCreate()
    
    try {
      runExample(spark)
    } catch {
      case e: Exception =>
        println("❌ Example failed:")
        e.printStackTrace()
    } finally {
      spark.stop()
    }
  }
  
  def runExample(spark: SparkSession): Unit = {
    import spark.implicits._
    
    println("📋 Creating Iceberg namespace and table...")
    
    // Create namespace
    spark.sql("CREATE NAMESPACE IF NOT EXISTS iceberg.demo")
    
    // Drop and recreate table for clean demo
    spark.sql("DROP TABLE IF EXISTS iceberg.demo.employees")
    
    // Create simple Iceberg table
    spark.sql("""
      CREATE TABLE iceberg.demo.employees (
        id BIGINT,
        name STRING,
        department STRING,
        salary DECIMAL(10,2),
        hire_date DATE
      )
      USING iceberg
      PARTITIONED BY (department)
      TBLPROPERTIES (
        'write.format.default' = 'parquet'
      )
    """)
    
    println("✅ Table created successfully!")
    
    // Insert sample data
    val employeesData = Seq(
      (1L, "Alice Johnson", "Engineering", 85000.00, "2023-01-15"),
      (2L, "Bob Smith", "Marketing", 65000.00, "2023-02-01"),
      (3L, "Carol Brown", "Engineering", 90000.00, "2023-01-20"),
      (4L, "David Wilson", "Sales", 70000.00, "2023-02-15"),
      (5L, "Eva Davis", "Marketing", 68000.00, "2023-03-01")
    ).toDF("id", "name", "department", "salary", "hire_date_str")
      .withColumn("hire_date", to_date(col("hire_date_str"), "yyyy-MM-dd"))
      .drop("hire_date_str")
    
    println("📊 Inserting sample data...")
    employeesData.writeTo("iceberg.demo.employees").append()
    
    // Verify data
    val count = spark.table("iceberg.demo.employees").count()
    println(s"✅ Inserted $count rows successfully!")
    
    // Show data
    println("📝 Sample data:")
    spark.table("iceberg.demo.employees").show()
    
    // Show table metadata
    println("📊 Table partitions:")
    spark.sql("SELECT partition, record_count FROM iceberg.demo.employees.partitions").show()
    
    // Show snapshots
    println("📸 Table snapshots:")
    spark.sql("SELECT snapshot_id, committed_at, summary FROM iceberg.demo.employees.snapshots").show(false)
    
    // Analytical query
    println("📈 Department analysis:")
    spark.sql("""
      SELECT 
        department,
        COUNT(*) as employee_count,
        AVG(salary) as avg_salary,
        MAX(salary) as max_salary
      FROM iceberg.demo.employees
      GROUP BY department
      ORDER BY avg_salary DESC
    """).show()
    
    println("🎉 Simple Iceberg example completed successfully!")
  }
}