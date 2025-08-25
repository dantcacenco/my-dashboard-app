#!/bin/bash

# Force Vercel to rebuild by making a small change
set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "🔄 Triggering Vercel rebuild..."
echo "================================"

# Add or update a timestamp comment in package.json to trigger rebuild
echo ""
echo "📝 Adding rebuild trigger..."

# Create a small change - add/update a comment in README or package.json
if [ -f "README.md" ]; then
  echo "" >> README.md
  echo "<!-- Rebuild trigger: $(date '+%Y-%m-%d %H:%M:%S') -->" >> README.md
  echo "✅ Added timestamp to README.md"
else
  # If no README, create a rebuild trigger file
  echo "# Rebuild Trigger" > .rebuild-trigger
  echo "Last rebuild: $(date '+%Y-%m-%d %H:%M:%S')" >> .rebuild-trigger
  echo "✅ Created rebuild trigger file"
fi

# Commit and push
echo ""
echo "📦 Committing change..."
git add -A
git commit -m "Trigger Vercel rebuild - reverting to stable build e1027fd"

echo ""
echo "🚀 Pushing to GitHub (will trigger Vercel)..."
git push origin main

echo ""
echo "========================================="
echo "✅ VERCEL REBUILD TRIGGERED!"
echo "========================================="
echo ""
echo "Status:"
echo "- Commit pushed to GitHub"
echo "- Vercel will automatically rebuild"
echo "- Using stable commit e1027fd as base"
echo ""
echo "Check your Vercel dashboard for build progress!"
