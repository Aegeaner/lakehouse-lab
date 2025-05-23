#!/bin/bash

# Script to setup Dremio with Iceberg integration
set -e

echo "🔧 Setting up Dremio for Iceberg Integration"
echo "============================================="

# Check if Dremio container is running
if ! docker ps --filter "name=dremio" --filter "status=running" | grep -q dremio; then
    echo "❌ Dremio container is not running!"
    echo "💡 Please run: ./start.sh"
    exit 1
fi

# Wait for Dremio to be ready
echo "⏳ Waiting for Dremio to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s -f http://localhost:9047/status > /dev/null 2>&1; then
        echo "✅ Dremio is ready!"
        break
    fi
    
    echo "Attempt $attempt/$max_attempts - Dremio not ready yet..."
    sleep 10
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "❌ Dremio failed to start within timeout period"
    exit 1
fi

# Check if Dremio is in first-time setup mode
echo "👤 Checking Dremio setup status..."
SETUP_STATUS=$(curl -s "http://localhost:9047/apiv2/bootstrap/firstuser" || echo "needs_setup")

if echo "$SETUP_STATUS" | grep -q "errorMessage"; then
    echo "🔧 Dremio needs manual first-time setup through web UI"
    echo "ℹ️  Automated setup not available - this is normal for fresh installations"
else
    echo "ℹ️  Dremio may already be configured or in setup mode"
fi

# Display setup instructions
echo ""
echo "📋 Dremio Manual Setup Instructions"
echo "==================================="
echo ""
echo "🌐 1. Access Dremio UI: http://localhost:9047"
echo ""
echo "👤 2. Create First User (if prompted):"
echo "   - First Name: Admin"
echo "   - Last Name: User"
echo "   - Username: dremio"
echo "   - Email: admin@dremio.local"
echo "   - Password: dremio123"
echo "   - Click 'Create Account'"
echo ""
echo "🔧 3. Add Data Sources:"
echo ""
echo "   📂 Add File System Source (for Iceberg warehouse):"
echo "   - Click '+ Add Source'"
echo "   - Select 'File System' or 'NAS'"
echo "   - Name: iceberg_warehouse"
echo "   - Root Path: /opt/iceberg/warehouse"
echo "   - Click 'Save'"
echo ""
echo "   ⚠️  Note: Dremio OSS doesn't have native Iceberg support."
echo "        You can browse Parquet files but not use Iceberg metadata."
echo ""
echo "   ⚠️  MinIO S3 Integration (Limited in OSS):"
echo "   - Dremio OSS doesn't support custom S3 endpoints"
echo "   - No endpoint field available in UI for MinIO"
echo "   - Alternative: Use File System source for local data"
echo ""
echo "   📁 Alternative - Add NAS Source (if needed):"
echo "   - Click '+ Add Source'"
echo "   - Select 'NAS'"
echo "   - Name: shared_data"
echo "   - Path: /opt/dremio/datasets"
echo "   - Click 'Save'"
echo ""
echo "📊 4. Test with Sample Queries:"
echo "   - First run: ./scripts/run_examples.sh simple"
echo "   - Browse files in Dremio UI under iceberg_warehouse"
echo "   - You can query Parquet files directly (but not as Iceberg tables)"
echo ""
echo "🔍 5. Verify Setup:"
echo "   - Run: ./scripts/run_examples.sh dremio"
echo ""
echo "✅ Complete these steps, then Dremio integration will work!"