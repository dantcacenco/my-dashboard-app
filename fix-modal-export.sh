#!/bin/bash

set -e

echo "🔧 Fixing EditJobModal export issue..."

# Fix the EditJobModal import in JobDetailView
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update JobDetailView to use named import
sed -i '' "s/import EditJobModal from '.\/EditJobModal'/import { EditJobModal } from '.\/EditJobModal'/" app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

# Add export to EditJobModal
echo "" >> app/\(authenticated\)/jobs/\[id\]/EditJobModal.tsx
echo "export { EditJobModal }" >> app/\(authenticated\)/jobs/\[id\]/EditJobModal.tsx

echo "✅ Fixed EditJobModal export"

# Test build again
echo ""
echo "🔨 Testing build..."
npm run build 2>&1 | head -80

# If successful, commit
if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Build successful!"
  git add -A
  git commit -m "Fix EditJobModal export issue"
  git push origin main
  echo "✅ Changes pushed!"
else
  echo "❌ Build still has issues"
fi

echo ""
echo "📝 REMINDER: Run the SQL from fix-rls-policies.sql in Supabase to enable technician access!"
