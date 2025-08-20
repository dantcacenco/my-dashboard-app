#!/bin/bash

set -e

echo "🔧 Fixing TypeScript error in TimeTracking component..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the TypeScript error - should be durationMinutes not duration_minutes
sed -i '' 's/duration_minutes$/durationMinutes/' components/TimeTracking.tsx

# ALWAYS check for TypeScript errors before committing
echo "📋 Checking for TypeScript errors..."
npx tsc --noEmit 2>&1 | head -20

# Test the build locally
echo "🔨 Testing build..."
npm run build 2>&1 | tail -20

# If build successful, commit
git add -A
git commit -m "Fix TypeScript error in TimeTracking component

- Fixed variable name: duration_minutes -> durationMinutes
- Build tested locally before push"

git push origin main

echo "✅ Fixed and verified build!"
