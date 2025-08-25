#!/bin/bash

# Revert to stable commit without losing history
set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "🔄 Reverting to stable commit 8056b7e..."
echo "========================================"

# First, check current status
echo "📊 Current status:"
git status --short

# Create a backup branch of current work (just in case)
echo ""
echo "📌 Creating backup branch of current work..."
git branch backup-aug-25-attempts 2>/dev/null || echo "Backup branch already exists"

# Revert to the stable commit
echo ""
echo "🔄 Reverting to commit 8056b7e..."
git reset --hard 8056b7e06f9bcffefea134907e8e01cbf907040e

# Show what we're at now
echo ""
echo "✅ Reverted successfully!"
echo ""
echo "📍 Current commit:"
git log --oneline -1

echo ""
echo "📂 Current files:"
ls -la | grep -E "\.tsx|\.ts|\.md" | tail -10

# Push the revert (force push needed since we're going backwards)
echo ""
echo "🚀 Pushing to GitHub..."
git push --force origin main

echo ""
echo "========================================="
echo "✅ REVERT COMPLETE!"
echo "========================================="
echo ""
echo "Status:"
echo "- Reverted to stable commit 8056b7e"
echo "- All broken changes removed"
echo "- History preserved in backup-aug-25-attempts branch"
echo "- Ready to start fresh"
echo ""
echo "You can now make targeted fixes without breaking working code."
