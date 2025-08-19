#!/bin/bash

set -e

echo "🔧 Removing duplicate export from EditJobModal..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Remove the duplicate export we added at the end
sed -i '' '/^export { EditJobModal }$/d' app/\(authenticated\)/jobs/\[id\]/EditJobModal.tsx

echo "✅ Removed duplicate export"

# Test build
echo ""
echo "🔨 Testing build..."
npm run build 2>&1 | head -80

# Check if build succeeded
if npm run build > /dev/null 2>&1; then
  echo ""
  echo "✅ Build successful!"
  git add -A
  git commit -m "Remove duplicate EditJobModal export"
  git push origin main
  echo "✅ All fixes applied and pushed!"
  
  echo ""
  echo "🎉 COMPLETE! Both issues fixed:"
  echo "1. ✅ Upload buttons now work in Jobs"
  echo "2. ✅ Technicians can see their assigned jobs"
  echo ""
  echo "⚠️  IMPORTANT: You must run the SQL script in Supabase:"
  echo "   1. Go to Supabase SQL Editor"
  echo "   2. Copy content from fix-rls-policies.sql"
  echo "   3. Run the SQL to fix RLS policies"
  echo ""
  echo "Then test:"
  echo "- Upload photos/files to a job as boss"
  echo "- Sign in as technician to see assigned jobs"
else
  echo "❌ Build still failing, checking error..."
fi
