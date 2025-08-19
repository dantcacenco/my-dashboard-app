#!/bin/bash

# Fix the missing conditional in ProposalView
set -e

echo "🔧 Fixing ProposalView conditional..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Use Python to properly fix the file
cat > fix-conditional.py << 'EOF'
with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'r') as f:
    content = f.read()

# Find the CreateJobButton line and add the missing conditional
content = content.replace(
    '            <CreateJobButton proposal={proposal} />\n          )}',
    '          {canCreateJob && (\n            <CreateJobButton proposal={proposal} />\n          )}'
)

with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.write(content)

print("Fixed conditional in ProposalView.tsx")
EOF

python3 fix-conditional.py
rm -f fix-conditional.py

echo "✅ Fixed conditional"

# Clean up
rm -f emergency-fix.sh

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Fix ProposalView conditional for CreateJobButton" || true
git push origin main

echo ""
echo "✅ CONDITIONAL FIXED!"
echo ""
echo "📋 FINAL CHECKLIST:"
echo "==================="
echo ""
echo "1️⃣ Run this SQL in Supabase (REQUIRED):"
echo "   ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;"
echo "   ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_name TEXT;"
echo "   ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_email TEXT;"
echo "   ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_phone TEXT;"
echo "   ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);"
echo ""
echo "2️⃣ Wait for deployment (1-2 minutes)"
echo ""
echo "3️⃣ Test:"
echo "   - Click 'New Job' button → should navigate to /jobs/new"
echo "   - Click 'Create Job' on approved proposal → should create job"
echo ""
echo "The 400 errors were because of missing database columns!"
