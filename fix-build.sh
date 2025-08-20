#!/bin/bash

set -e

echo "🔧 Fixing TypeScript build error..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the TypeScript error in JobDetailView
sed -i '' 's/setJob(prev => ({ ...prev, total_amount: data.total }))/setJob((prev: any) => ({ ...prev, total_amount: data.total }))/' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

# Clean up temporary files
rm -f fix-all-issues.sh complete-fixes.sh full-fix.sh

# Commit the fix
git add -A
git commit -m "Fix TypeScript build error - add type annotation for prev parameter"
git push origin main

echo "✅ Build error fixed and pushed!"
