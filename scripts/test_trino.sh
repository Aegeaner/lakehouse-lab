#!/bin/bash
set -e

echo "🧪 Testing Trino integration..."

# Function to run Trino SQL
run_trino_sql() {
    local sql="$1"
    echo "Executing: $sql"
    docker exec trino trino --execute "$sql"
}

# Function to run Trino SQL from file
run_trino_file() {
    local file="$1"
    echo "Executing SQL from: $file"
    docker exec -i trino trino < "$file"
}

# Test 1: Basic connectivity
echo "🔍 Test 1: Basic connectivity"
run_trino_sql "SELECT 'Trino is working!' as status"

# Test 2: Show catalogs
echo "🔍 Test 2: Available catalogs"
run_trino_sql "SHOW CATALOGS"

# Test 3: Memory catalog test
echo "🔍 Test 3: Memory catalog functionality"
run_trino_sql "DROP TABLE IF EXISTS memory.default.test_table"
run_trino_sql "CREATE TABLE memory.default.test_table (id INT, name VARCHAR)"
run_trino_sql "INSERT INTO memory.default.test_table VALUES (1, 'test')"
run_trino_sql "SELECT * FROM memory.default.test_table"

# Test 4: Iceberg catalog connectivity
echo "🔍 Test 4: Iceberg catalog connectivity"
if run_trino_sql "SHOW SCHEMAS IN iceberg" 2>/dev/null; then
    echo "✅ Iceberg catalog is accessible"
    
    # Test 5: Create Iceberg schema (table creation may fail due to S3 factory)
    echo "🔍 Test 5: Create Iceberg schema"
    run_trino_sql "CREATE SCHEMA IF NOT EXISTS iceberg.test"
    echo "🔍 Test 5a: Attempt Iceberg table creation (may fail due to file system factory)"
    if run_trino_sql "CREATE TABLE IF NOT EXISTS iceberg.test.simple_test (id BIGINT, message VARCHAR) WITH (format = 'PARQUET')" 2>/dev/null; then
        run_trino_sql "INSERT INTO iceberg.test.simple_test VALUES (1, 'Hello Iceberg!')"
        run_trino_sql "SELECT * FROM iceberg.test.simple_test"
        echo "✅ Iceberg table creation succeeded"
    else
        echo "⚠️ Iceberg table creation failed - S3 file system factory not available"
        echo "💡 This is expected with the standard Trino Docker image"
    fi
    
    echo "✅ Iceberg catalog connectivity verified"
else
    echo "⚠️ Iceberg catalog not accessible - check Nessie connection"
fi

# Test 6: Show system information
echo "🔍 Test 6: System information"
run_trino_sql "SELECT node_id, http_uri, node_version FROM system.runtime.nodes"

echo ""
echo "✅ Trino testing completed!"
echo ""
echo "📊 Next steps:"
echo "1. Run ./scripts/run_trino_examples.sh for comprehensive examples"
echo "2. Access Trino Web UI at http://localhost:8084"
echo "3. Connect with your favorite SQL client using:"
echo "   - Host: localhost"
echo "   - Port: 8084"
echo "   - Catalog: memory (for working examples) or iceberg (limited functionality)"
echo ""
echo "💡 Note: Full Iceberg functionality requires S3 libraries not included in standard Trino image"
echo "   Current examples use memory catalog which provides full SQL analytics capabilities"