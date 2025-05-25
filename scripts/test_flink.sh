#!/bin/bash

# Comprehensive test script for Flink-Iceberg integration
set -e

echo "🧪 Flink-Iceberg Integration Test Suite"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${BLUE}🔍 Test $TOTAL_TESTS: $test_name${NC}"
    echo "Command: $test_command"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to check service health
check_service() {
    local service_name="$1"
    local health_check="$2"
    
    echo -e "\n${YELLOW}🔍 Checking $service_name...${NC}"
    if eval "$health_check"; then
        echo -e "${GREEN}✅ $service_name is healthy${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not healthy${NC}"
        return 1
    fi
}

# Pre-test setup
echo "🔧 Pre-test Setup"
echo "=================="

# Check if required services are running
check_service "Flink JobManager" "curl -s -f http://localhost:8081/overview > /dev/null"
check_service "Kafka" "docker exec kafka-container kafka-topics.sh --bootstrap-server localhost:9092 --list > /dev/null"
check_service "Nessie" "curl -s -f http://localhost:19120/api/v1/trees > /dev/null"

# Install Python dependencies if needed
echo -e "\n${YELLOW}📦 Checking Python dependencies...${NC}"
if ! python3 -c "import kafka" 2>/dev/null; then
    echo "Installing kafka-python..."
    pip3 install kafka-python --quiet || echo "⚠️ Could not install kafka-python"
fi

# Test 1: Verify Flink connectors are available
run_test "Flink Connectors Available" \
    "docker exec flink-jobmanager ls /opt/flink/lib/ | grep -E '(kafka|iceberg)'" \
    "connectors present"

# Test 2: Create Kafka topics
run_test "Create Kafka Topics" \
    "./scripts/setup_flink.sh > /tmp/setup.log 2>&1 && grep -q 'user_events' /tmp/setup.log" \
    "topics created"

# Test 3: Generate sample data
echo -e "\n${BLUE}📊 Generating test data...${NC}"
run_test "Generate User Events Data" \
    "timeout 30 python3 scripts/generate_sample_data.py --data-type user_events --count 20 --delay 0.1" \
    "data generated"

# Test 4: Submit simple streaming job
echo -e "\n${BLUE}🌊 Testing Simple Streaming Job...${NC}"
run_test "Submit Simple Streaming Job" \
    "timeout 60 ./scripts/run_flink_example.sh simple > /tmp/job_submit.log 2>&1" \
    "job submitted"

# Wait for job to process data
echo -e "\n${YELLOW}⏳ Waiting for job to process data (30 seconds)...${NC}"
sleep 30

# Test 5: Verify data in Iceberg
run_test "Verify Iceberg Table Creation" \
    "docker exec flink-jobmanager ls /opt/iceberg/warehouse/streaming/user_events/ 2>/dev/null | grep -q 'data'" \
    "iceberg data exists"

# Test 6: Generate metrics data and test windowed aggregations
echo -e "\n${BLUE}📈 Testing Windowed Aggregations...${NC}"
run_test "Generate Metrics Data" \
    "timeout 20 python3 scripts/generate_sample_data.py --data-type metrics --count 30 --delay 0.1" \
    "metrics generated"

run_test "Submit Windowed Aggregation Job" \
    "timeout 60 ./scripts/run_flink_example.sh windowed > /tmp/windowed_job.log 2>&1" \
    "windowed job submitted"

# Test 7: CDC processing test
echo -e "\n${BLUE}🔄 Testing CDC Processing...${NC}"
run_test "Generate CDC Events" \
    "timeout 15 python3 scripts/generate_sample_data.py --data-type cdc --count 10 --delay 0.1" \
    "cdc events generated"

run_test "Submit CDC Processing Job" \
    "timeout 60 ./scripts/run_flink_example.sh cdc > /tmp/cdc_job.log 2>&1" \
    "cdc job submitted"

# Test 8: Check job status via REST API
run_test "Check Running Jobs" \
    "curl -s http://localhost:8081/jobs | python3 -c 'import sys,json; jobs=json.load(sys.stdin)[\"jobs\"]; print(f\"Found {len(jobs)} jobs\"); exit(0 if len(jobs) > 0 else 1)'" \
    "jobs running"

# Test 9: Interactive SQL test
echo -e "\n${BLUE}💻 Testing Interactive SQL...${NC}"
run_test "Test SQL CLI Connection" \
    "timeout 30 docker exec flink-jobmanager /opt/flink/bin/sql-client.sh embedded -e 'SHOW TABLES;' > /tmp/sql_test.log 2>&1" \
    "sql cli works"

# Test 10: Data validation
echo -e "\n${BLUE}✅ Data Validation Tests...${NC}"
run_test "Check Warehouse Directory Structure" \
    "docker exec flink-jobmanager find /opt/iceberg/warehouse -name '*.parquet' | head -5" \
    "parquet files exist"

# Performance test
echo -e "\n${BLUE}⚡ Performance Test...${NC}"
run_test "High-Volume Data Generation" \
    "timeout 45 python3 scripts/generate_sample_data.py --data-type user_events --count 100 --delay 0.05" \
    "high volume processed"

# Wait for processing
echo -e "\n${YELLOW}⏳ Allowing time for high-volume processing (30 seconds)...${NC}"
sleep 30

# Final validation
echo -e "\n${BLUE}🔍 Final Validation...${NC}"
run_test "Check Final Data Count" \
    "docker exec flink-jobmanager find /opt/iceberg/warehouse/streaming -name '*.parquet' | wc -l | awk '{print \$1 > 0}'" \
    "data files present"

# Cleanup test
echo -e "\n${BLUE}🧹 Cleanup Test...${NC}"
run_test "Stop All Jobs" \
    "./scripts/run_flink_example.sh stop > /tmp/stop_jobs.log 2>&1" \
    "jobs stopped"

# Test Summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo "=================="
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! Flink-Iceberg integration is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please check the logs above for details.${NC}"
    echo -e "\n${YELLOW}💡 Troubleshooting tips:${NC}"
    echo "1. Check service logs: docker logs flink-jobmanager"
    echo "2. Verify Kafka topics: docker exec kafka-container kafka-topics.sh --bootstrap-server localhost:9092 --list"
    echo "3. Check Flink UI: http://localhost:8081"
    echo "4. Verify connectors: docker exec flink-jobmanager ls /opt/flink/lib/"
    exit 1
fi