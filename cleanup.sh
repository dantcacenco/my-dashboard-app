#!/bin/bash

set -e

echo "🗑️  Deleting all SQL files from project..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Delete all SQL files
rm -f fix_profiles_rls.sql
rm -f fix-profiles-rls.sql
rm -f fix-rls-policies.sql
rm -f update_rls_policies.sql
rm -f setup_storage.sql
rm -f check-job-assignments.sql
rm -f check-technicians.sql
rm -f setup-database.sql
rm -f fix_user_role.sql
rm -f supabase_setup.sql
rm -f delete-test-jobs.sql
rm -f supabase_setup_fixed.sql
rm -f fix-job-status-constraint.sql
rm -f check-jobs-table.sql
rm -f fix-profiles-rls-final.sql

echo "✅ All SQL files deleted"

# Also clean up shell scripts
echo "🗑️  Cleaning up temporary shell scripts..."
rm -f fix-uploads-and-technician.sh
rm -f fix-modal-export.sh
rm -f final-fix.sh
rm -f complete-fix.sh
rm -f final-complete-fix.sh
rm -f final-typescript-fix.sh
rm -f complete-final-fix.sh

echo "✅ Temporary scripts deleted"

# Commit the cleanup
git add -A
git commit -m "Clean up: Remove all SQL files and temporary scripts

- Deleted 15 SQL files
- Removed temporary fix scripts
- Project folder cleaned up"

git push origin main

echo ""
echo "✅ COMPLETE! All SQL files and temporary scripts removed"
echo "📁 Project folder is now clean"
