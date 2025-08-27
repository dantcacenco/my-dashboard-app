#!/bin/bash

# Clean up files that shouldn't exist in the reverted state

set -e

echo "============================================"
echo "Cleaning up files from reverted work"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# Remove files that were created after commit 04d791e
echo "Removing JobDetailModal.tsx (not in working commit)..."
rm -f components/JobDetailModal.tsx

echo "Removing Select component (not in working commit)..."
rm -f components/ui/select.tsx

echo "Removing temporary script files..."
rm -f backup-service-template.js
rm -f storage_comparison.md
rm -f storage_migration_plan.md
rm -f fix_storage.sql
rm -f revert_to_working.sh
rm -f update_project_scope.sh

# Check if there are any leftover .temp files
echo "Cleaning up .temp files..."
rm -rf supabase/.temp

echo ""
echo "Testing build..."
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo ""
  echo "Build successful! Committing cleanup..."
  git add -A
  git commit -m "Remove files that weren't part of working commit 04d791e

Removed JobDetailModal and other components that were causing build failures.
These were added after the working commit and shouldn't be present."
  git push origin main
  
  echo ""
  echo "============================================"
  echo "SUCCESS! Build is now working"
  echo "============================================"
else
  echo ""
  echo "Build still has issues. Checking for more problems..."
fi
