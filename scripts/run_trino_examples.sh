#!/bin/bash
set -e

echo "🎯 Running Trino-Iceberg examples..."

EXAMPLES_DIR="/home/aegeaner/Code/lakehouse-lab/examples/trino-iceberg"

# Function to run Trino SQL from file
run_trino_file() {
    local file="$1"
    local description="$2"
    echo ""
    echo "🔍 Running: $description"
    echo "📁 File: $file"
    echo "----------------------------------------"
    
    if [ -f "$file" ]; then
        # Filter out comments and empty lines for cleaner output
        grep -v '^--' "$file" | grep -v '^$' | docker exec -i trino trino
        echo "✅ Completed: $description"
    else
        echo "❌ File not found: $file"
        return 1
    fi
}

# Function to run specific SQL command
run_trino_sql() {
    local sql="$1"
    echo "Executing: $sql"
    docker exec trino trino --execute "$sql"
}

# Check if Trino is running
if ! docker ps | grep -q trino; then
    echo "❌ Trino container is not running. Please start with ./start.sh and run ./scripts/setup_trino.sh"
    exit 1
fi

# Parse command line argument
EXAMPLE_TYPE=${1:-"all"}

case $EXAMPLE_TYPE in
    "basic")
        echo "🎯 Running basic queries example..."
        run_trino_file "$EXAMPLES_DIR/basic_queries.sql" "Basic SQL Operations"
        ;;
    "analytics")
        echo "🎯 Running advanced analytics example..."
        run_trino_file "$EXAMPLES_DIR/advanced_analytics.sql" "Advanced Analytics Queries"
        ;;
    "schema")
        echo "🎯 Running schema evolution example..."
        run_trino_file "$EXAMPLES_DIR/schema_evolution.sql" "Schema Evolution Demo"
        ;;
    "timetravel")
        echo "🎯 Running time travel example..."
        run_trino_file "$EXAMPLES_DIR/time_travel.sql" "Time Travel and Versioning Concepts"
        ;;
    "all")
        echo "🎯 Running all Trino examples..."
        run_trino_file "$EXAMPLES_DIR/basic_queries.sql" "Basic SQL Operations"
        
        echo ""
        echo "⏳ Waiting 2 seconds between examples..."
        sleep 2
        
        run_trino_file "$EXAMPLES_DIR/advanced_analytics.sql" "Advanced Analytics Queries"
        
        echo ""
        echo "⏳ Waiting 2 seconds between examples..."
        sleep 2
        
        run_trino_file "$EXAMPLES_DIR/schema_evolution.sql" "Schema Evolution Demo"
        
        echo ""
        echo "⏳ Waiting 2 seconds between examples..."
        sleep 2
        
        run_trino_file "$EXAMPLES_DIR/time_travel.sql" "Time Travel and Versioning Concepts"
        ;;
    *)
        echo "❌ Invalid example type: $EXAMPLE_TYPE"
        echo ""
        echo "Usage: $0 [basic|analytics|schema|timetravel|all]"
        echo ""
        echo "Examples:"
        echo "  $0 basic      - Run basic queries only"
        echo "  $0 analytics  - Run advanced analytics queries"
        echo "  $0 schema     - Run schema evolution examples"
        echo "  $0 timetravel - Run time travel examples"
        echo "  $0 all        - Run all examples (default)"
        exit 1
        ;;
esac

echo ""
echo "✅ Trino examples completed successfully!"
echo ""
echo "🎉 What you've accomplished:"
echo "- Created Iceberg tables with Trino"
echo "- Performed CRUD operations on lakehouse data"
echo "- Demonstrated schema evolution capabilities"
echo "- Explored time travel and versioning features"
echo "- Ran advanced analytics queries"
echo ""
echo "🔍 Explore more:"
echo "- Access Trino Web UI: http://localhost:8084"
echo "- Connect Trino CLI: docker exec -it trino trino"
echo "- View table metadata: SELECT * FROM iceberg.information_schema.tables"
echo "- Check snapshots: SELECT * FROM <schema>.<table>\$snapshots"