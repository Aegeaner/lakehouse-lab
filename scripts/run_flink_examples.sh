#!/bin/bash

# Script to run Flink-Iceberg SQL examples
set -e

echo "🌊 Flink-Iceberg Examples Runner"
echo "================================="

# Check if Flink is running
if ! curl -s -f http://localhost:8081/overview > /dev/null 2>&1; then
    echo "❌ Flink is not running or not accessible!"
    echo "💡 Please run: ./scripts/setup_flink.sh"
    exit 1
fi

# Function to submit SQL job to Flink
submit_sql_job() {
    local sql_file=$1
    local job_name=$2
    
    echo ""
    echo "🚀 Submitting SQL job: $job_name"
    echo "📄 SQL file: $sql_file"
    echo "------------------------------------"
    
    if [ ! -f "$sql_file" ]; then
        echo "❌ SQL file not found: $sql_file"
        return 1
    fi
    
    # Copy SQL file to Flink container
    docker cp "$sql_file" flink-jobmanager:/tmp/job.sql
    
    # Initialize tables first (DDL only)
    docker exec -i flink-jobmanager bash -c "
        echo 'Creating tables...'
        /opt/flink/bin/sql-client.sh --init /tmp/job.sql \
            -j /opt/flink/lib/flink-sql-connector-kafka-3.2.0-1.20.jar \
            -j /opt/flink/lib/iceberg-flink-runtime-1.20-1.6.1.jar \
            -j /opt/flink/lib/hadoop-aws-3.3.4.jar \
            -j /opt/flink/lib/aws-java-sdk-bundle-1.12.262.jar
    " || echo "⚠️  Table creation may have issues"
    
    echo "✅ Job submitted! Check Flink UI at http://localhost:8081 for status"
}

# Function to run SQL commands interactively
run_interactive_sql() {
    echo ""
    echo "🔧 Starting Flink SQL CLI (interactive mode)"
    echo "============================================"
    echo "Available commands:"
    echo "  SHOW TABLES;"
    echo "  DESCRIBE table_name;"
    echo "  SELECT * FROM table_name LIMIT 10;"
    echo "  EXIT; (to quit)"
    echo ""
    
    docker exec -it flink-jobmanager /opt/flink/bin/sql-client.sh embedded \
        -j /opt/flink/lib/flink-sql-connector-kafka-3.2.0-1.20.jar \
        -j /opt/flink/lib/iceberg-flink-runtime-1.20-1.6.1.jar \
        -j /opt/flink/lib/hadoop-aws-3.3.4.jar \
        -j /opt/flink/lib/aws-java-sdk-bundle-1.12.262.jar
}

# Function to show job status
show_job_status() {
    echo ""
    echo "📊 Flink Job Status"
    echo "==================="
    
    # Get jobs via REST API
    curl -s http://localhost:8081/jobs | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    jobs = data.get('jobs', [])
    if not jobs:
        print('No running jobs found')
    else:
        print(f'Found {len(jobs)} job(s):')
        for job in jobs:
            print(f'  Job ID: {job[\"id\"]}')
            print(f'  Status: {job[\"status\"]}')
            print('  ---')
except:
    print('Could not parse job status')
" 2>/dev/null || echo "⚠️  Could not retrieve job status"
}

# Function to stop all jobs
stop_all_jobs() {
    echo ""
    echo "🛑 Stopping all Flink jobs..."
    
    curl -s http://localhost:8081/jobs | python3 -c "
import sys, json, urllib.request
try:
    data = json.load(sys.stdin)
    jobs = data.get('jobs', [])
    for job in jobs:
        if job['status'] == 'RUNNING':
            job_id = job['id']
            print(f'Stopping job {job_id}...')
            # Cancel job
            req = urllib.request.Request(f'http://localhost:8081/jobs/{job_id}/cancel', method='PATCH')
            urllib.request.urlopen(req)
    print('All jobs stopped')
except Exception as e:
    print(f'Error stopping jobs: {e}')
" 2>/dev/null || echo "⚠️  Could not stop jobs automatically"
}

# Parse command line arguments
case "${1:-help}" in
    "simple")
        echo "🚀 Running Simple Iceberg Streaming Example..."
        submit_sql_job "examples/flink-iceberg/simple_iceberg_streaming.sql" "Simple Streaming"
        echo ""
        echo "🔄 Starting streaming job..."
        echo "⚠️  Note: The streaming INSERT job needs to be started manually or via REST API"
        echo "💡 To start the streaming job:"
        echo "   ./scripts/run_flink_examples.sh interactive"
        echo "   Then execute: INSERT INTO iceberg_user_events SELECT user_id, event_type, event_data, event_time, CURRENT_TIMESTAMP as processing_time FROM user_events;"
        ;;
    "windowed")
        echo "🚀 Running Windowed Aggregations Example..."
        submit_sql_job "examples/flink-iceberg/windowed_aggregations.sql" "Windowed Aggregations"
        ;;
    "cdc")
        echo "🚀 Running CDC to Iceberg Example..."
        submit_sql_job "examples/flink-iceberg/cdc_to_iceberg.sql" "CDC Processing"
        ;;
    "interactive"|"sql")
        run_interactive_sql
        ;;
    "status")
        show_job_status
        ;;
    "stop")
        stop_all_jobs
        ;;
    "help"|"-h"|"--help")
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  simple       Run simple Kafka to Iceberg streaming"
        echo "  windowed     Run windowed aggregations example"
        echo "  cdc          Run CDC (Change Data Capture) example"
        echo "  interactive  Start interactive Flink SQL CLI"
        echo "  status       Show running job status"
        echo "  stop         Stop all running jobs"
        echo "  help         Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 simple           # Run simple streaming example"
        echo "  $0 interactive      # Start SQL CLI for manual queries"
        echo "  $0 status           # Check job status"
        echo ""
        echo "Before running examples:"
        echo "  1. Setup: ./scripts/setup_flink.sh"
        echo "  2. Generate data: python3 scripts/generate_sample_data.py"
        echo "  3. Run example: $0 simple"
        echo "  4. Monitor: http://localhost:8081"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "💡 Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo "📋 Next steps:"
echo "  - Monitor jobs: http://localhost:8081"
echo "  - Generate data: python3 scripts/generate_sample_data.py"
echo "  - Check results: ./scripts/run_examples.sh simple"
echo "  - Interactive SQL: $0 interactive"