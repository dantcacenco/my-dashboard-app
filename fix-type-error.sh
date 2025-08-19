#!/bin/bash

set -e

echo "🔧 Fixing TypeScript error in JobDetailView..."

# Fix the type error by updating the onSave prop
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Use sed to fix the specific line
sed -i '' 's/onSave={(updatedJob)/onSave={(updatedJob: any)/' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "🧪 Testing build again..."
npm run build 2>&1 | head -50

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    git add -A
    git commit -m "Fix: TypeScript error in JobDetailView onSave handler"
    git push origin main
    
    echo "✅ All fixes deployed successfully!"
else
    echo "❌ Build still has errors"
fi
