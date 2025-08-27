#!/bin/bash

# Alternative approach to run SQL without Supabase CLI
# Uses direct PostgreSQL connection

echo "============================================"
echo "Running SQL via Direct Connection"
echo "============================================"

# Connection details
DB_HOST="aws-0-us-east-1.pooler.supabase.com"
DB_NAME="postgres"
DB_USER="postgres.dqcxwekmehrqkigcufug"
DB_PASSWORD="cSEX2IYYjeJru6V"
DB_PORT="6543"

# Create SQL file
cat > /tmp/fix_storage_direct.sql << 'EOF'
-- Make buckets public for read access
UPDATE storage.buckets 
SET public = true 
WHERE name IN ('job-photos', 'job-files');

-- Verify bucket settings
SELECT name, public, created_at 
FROM storage.buckets 
WHERE name IN ('job-photos', 'job-files');
EOF

echo "SQL to be executed:"
echo "-------------------"
cat /tmp/fix_storage_direct.sql
echo ""
echo "-------------------"

# Check if psql is installed
if command -v psql &> /dev/null; then
    echo "Running SQL with psql..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f /tmp/fix_storage_direct.sql
else
    echo "psql not found. Installing postgresql client..."
    brew install postgresql@16
    
    # Try again after installation
    if command -v psql &> /dev/null; then
        echo "Running SQL with psql..."
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f /tmp/fix_storage_direct.sql
    else
        echo "ERROR: Could not install or find psql"
        echo ""
        echo "Please run this SQL manually in Supabase Dashboard:"
        echo "https://supabase.com/dashboard/project/dqcxwekmehrqkigcufug/sql/new"
        echo ""
        cat /tmp/fix_storage_direct.sql
    fi
fi

echo ""
echo "============================================"
echo "Alternative: Manual Steps"
echo "============================================"
echo "1. Go to: https://supabase.com/dashboard/project/dqcxwekmehrqkigcufug/sql/new"
echo "2. Copy and paste the SQL above"
echo "3. Click 'Run'"
echo ""
echo "The Supabase CLI link may not be working due to:"
echo "- Password authentication issues"
echo "- Network connectivity"
echo "- CLI version mismatch"
echo ""
echo "Recommendation: Use the Supabase Dashboard SQL editor directly"
echo "============================================"
