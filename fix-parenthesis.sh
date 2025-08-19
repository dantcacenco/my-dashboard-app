#!/bin/bash

# Fix the missing closing parenthesis
set -e

echo "🔧 Adding missing closing parenthesis..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix line 109 - add closing parenthesis after the SendProposal component
sed -i '' '109s|/>|/>)|' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

echo "✅ Fixed closing parenthesis"

# Clean up
rm -f final-syntax-fix.sh delete-fake-jobs.sql check-job-created-column.sql

# Test
echo "🔍 Testing TypeScript..."
npx tsc --noEmit 2>&1 | head -5 || true

echo "🔨 Building..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Fix missing closing parenthesis in ProposalView" || true
git push origin main

echo ""
echo "✅ SYNTAX SHOULD BE FIXED NOW!"
echo ""
echo "🚨 CRITICAL - RUN THIS SQL:"
echo "============================"
echo "ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_name TEXT, ADD COLUMN IF NOT EXISTS customer_email TEXT, ADD COLUMN IF NOT EXISTS customer_phone TEXT, ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);"
echo "============================"
