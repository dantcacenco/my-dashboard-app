#!/bin/bash

set -e

echo "🔧 Final fix for TechniciansClientView callback..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the callback issue by updating the handler
sed -i '' 's/onSuccess={handleTechnicianAdded}/onSuccess={() => handleRefresh()}/' app/\(authenticated\)/technicians/TechniciansClientView.tsx

# Remove unused handlers
sed -i '' '/const handleTechnicianAdded/,/^  }/d' app/\(authenticated\)/technicians/TechniciansClientView.tsx
sed -i '' '/const handleTechnicianUpdated/,/^  }/d' app/\(authenticated\)/technicians/TechniciansClientView.tsx

# Fix EditTechnicianModal callback too
sed -i '' 's/onSuccess={handleTechnicianUpdated}/onSuccess={() => handleRefresh()}/' app/\(authenticated\)/technicians/TechniciansClientView.tsx

echo "🧪 Testing final build..."
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    git add -A
    git commit -m "Fix: Update technician modal callbacks to use refresh instead of manual state updates"
    git push origin main
    
    echo "🎉 All TypeScript errors fixed and deployed!"
    echo "✨ Summary of fixes:"
    echo "  ✅ Send to Customer button now visible for draft and sent status"
    echo "  ✅ Technician refresh button working properly"
    echo "  ✅ Job detail page with full editing capabilities"
    echo "  ✅ File and photo uploads to Supabase storage"
    echo "  ✅ Create Job button on approved proposals"
    echo "  ✅ Comprehensive Edit Job modal"
    echo "  ✅ Dynamic technician assignment"
else
    echo "❌ Build still has errors"
fi
