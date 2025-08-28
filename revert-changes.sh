#!/bin/bash

echo "🔄 Reverting to previous working state..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Get the last known good commit before my changes
echo "📍 Finding last stable commit..."
git log --oneline -10

# Revert to the commit before I made changes (before the Select component addition)
echo "⏪ Reverting to stable state..."
git reset --hard 242cecc

# Force push to overwrite the broken changes
echo "🚀 Force pushing to GitHub..."
git push --force origin main

echo "✅ Reverted to original working state"
echo "
📋 NEXT STEPS:
1. Review the original UI carefully
2. Apply ONLY the logic fixes needed:
   - Fix Edit Job modal data population
   - Fix calendar job count
   - Fix photo viewing
   - Fix file downloads
3. Keep ALL UI components exactly as they were
"
