import org.apache.spark.sql.SparkSession
import java.sql.{Connection, DriverManager}

object SimpleDremioExample {
  def main(args: Array[String]): Unit = {
    println("🔍 Starting Simple Dremio Example...")
    
    val spark = SparkSession.builder
      .appName("SimpleDremioExample")
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
    println("🔧 Testing Dremio connectivity...")
    
    // Test basic connectivity first
    testBasicConnectivity()
    
    // Try to query through Spark JDBC
    queryThroughSpark(spark)
    
    // Provide setup instructions
    provideSetupInstructions()
  }
  
  def testBasicConnectivity(): Unit = {
    try {
      println("📡 Testing Dremio JDBC connection...")
      Class.forName("com.dremio.jdbc.Driver")
      
      val connection: Connection = DriverManager.getConnection(
        "jdbc:dremio:direct=dremio:31010",
        "dremio", 
        "dremio123"
      )
      
      val statement = connection.createStatement()
      val resultSet = statement.executeQuery("SELECT 1 as connection_test")
      
      if (resultSet.next()) {
        println("✅ Dremio JDBC connection successful!")
        println(s"   Test result: ${resultSet.getInt(1)}")
      }
      
      // Try to show available schemas
      try {
        val schemasRs = statement.executeQuery("SHOW SCHEMAS")
        println("📋 Available schemas in Dremio:")
        while (schemasRs.next()) {
          println(s"   - ${schemasRs.getString(1)}")
        }
        schemasRs.close()
      } catch {
        case e: Exception =>
          println("⚠️  Could not list schemas. This is normal if no data sources are configured yet.")
          println(s"   Details: ${e.getMessage}")
      }
      
      statement.close()
      connection.close()
      
    } catch {
      case _: ClassNotFoundException =>
        println("❌ Dremio JDBC driver not found!")
        println("💡 Ensure dremio-jdbc-driver jar is in the external-jars directory")
      case e: Exception if e.getMessage.contains("Authentication failed") =>
        println("🔐 Dremio authentication failed!")
        println("💡 This means Dremio is running but needs initial setup.")
        println("   Please complete the setup steps below.")
      case e: Exception =>
        println(s"❌ Dremio connection failed: ${e.getMessage}")
        println("💡 Possible causes:")
        println("   - Dremio container is not running")
        println("   - Dremio is still starting up (wait 2-3 minutes)")
        println("   - Network connectivity issues")
    }
  }
  
  def queryThroughSpark(spark: SparkSession): Unit = {
    println("\n🔍 Testing Spark JDBC integration with Dremio...")
    
    try {
      // Try to query a simple test query first
      val df = spark.read
        .format("jdbc")
        .option("url", "jdbc:dremio:direct=dremio:31010")
        .option("driver", "com.dremio.jdbc.Driver")
        .option("dbtable", "(SELECT 'Hello from Dremio!' as message) as test")
        .option("user", "dremio")
        .option("password", "dremio123")
        .load()

      println("✅ Spark JDBC query successful!")
      println("📝 Test query result:")
      df.show()
      
      println("💡 To query Iceberg data through Dremio:")
      println("   1. Add File System source pointing to /opt/iceberg/warehouse")
      println("   2. Browse Parquet files in the Dremio UI")
      println("   3. Query files directly (Dremio OSS doesn't support Iceberg metadata)")
      
    } catch {
      case e: Exception =>
        println(s"⚠️  Spark JDBC query failed: ${e.getMessage}")
        println("💡 This is expected if:")
        println("   - Dremio user is not set up yet")
        println("   - Authentication credentials are incorrect")
        println("   - Dremio is not properly configured")
    }
  }
  
  def provideSetupInstructions(): Unit = {
    println("\n📋 Dremio Setup Instructions")
    println("============================")
    println()
    println("🌐 1. Access Dremio UI: http://localhost:9047")
    println("👤 2. Login with credentials:")
    println("     Username: dremio")
    println("     Password: dremio123")
    println()
    println("🔧 3. Add File System source (Dremio OSS limitation):")
    println("     - Click 'Add Source'")
    println("     - Select 'File System' or 'NAS'")
    println("     - Name: iceberg_warehouse")
    println("     - Root Path: /opt/iceberg/warehouse")
    println("     - Click 'Save'")
    println()
    println("📊 4. Browse and query Parquet files:")
    println("     - Navigate to iceberg_warehouse in Dremio UI")
    println("     - Browse to find Parquet files")
    println("     - Query files directly (no Iceberg metadata in OSS)")
    println("     - Example: SELECT * FROM iceberg_warehouse.\"path/to/file.parquet\";")
    println()
    println("⚠️  5. MinIO S3 Integration Limitations:")
    println("     - Dremio OSS doesn't support custom S3 endpoints")
    println("     - No endpoint field in UI for MinIO connections")
    println("     - AWS S3 source only works with real AWS S3")
    println()
    println("🔧 5. Alternative - Add NAS source (if needed):")
    println("     - Click 'Add Source'")
    println("     - Select 'NAS'")
    println("     - Name: shared_data")
    println("     - Path: /opt/dremio/datasets")
    println("     - This provides access to shared file storage")
    println()
    println("✅ Setup complete! You can now query Iceberg tables through Dremio.")
  }
}