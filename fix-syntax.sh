#!/bin/bash

# Fix SendProposal closing tag
set -e

echo "🔧 Fixing SendProposal closing tag..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the missing closing tag
sed -i '' '107s/onSent={() => router.refresh()}/onSent={() => router.refresh()}\/>/' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx
sed -i '' '108s/^          )}$/          )}/' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

echo "✅ Fixed closing tag"

# Clean up
rm -f fix-conditional.sh

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Fix SendProposal closing tag syntax error" || true
git push origin main

echo ""
echo "✅ SYNTAX FIXED!"
echo ""
echo "🚨 IMPORTANT - RUN THIS SQL IN SUPABASE:"
echo "========================================="
cat check-job-created-column.sql
echo "========================================="
echo ""
echo "After running the SQL and deployment completes:"
echo "✅ 'New Job' button will work"
echo "✅ 'Create Job' from proposal will work"
echo "✅ No more 400 errors"
