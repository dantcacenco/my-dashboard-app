#!/bin/bash

# Revert to commit e1027fd
set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "🔄 Reverting to commit e1027fd..."
echo "========================================"

# Check current status
echo "📊 Current status:"
git log --oneline -1

# Revert to the specified commit
echo ""
echo "🔄 Reverting to commit e1027fd67e460f2a6197ddf91e74705b29c990b2..."
git reset --hard e1027fd67e460f2a6197ddf91e74705b29c990b2

# Show what we're at now
echo ""
echo "✅ Reverted successfully!"
echo ""
echo "📍 Current commit:"
git log --oneline -1

# Push the revert
echo ""
echo "🚀 Pushing to GitHub..."
git push --force origin main

echo ""
echo "========================================="
echo "✅ REVERT COMPLETE!"
echo "========================================="
echo ""
echo "Status:"
echo "- Reverted to commit e1027fd"
echo "- Ready for fresh start"
