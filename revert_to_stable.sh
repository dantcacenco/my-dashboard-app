#!/bin/bash

# Revert code to commit 04d791e53ca32eed6f940f8471f97f35c0a6c4c0
# Preserving all commit history

set -e

echo "============================================"
echo "Reverting code to commit 04d791e"
echo "Preserving all commit history"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# Show current HEAD
echo "Current HEAD:"
git log --oneline -1

# Restore all files from the target commit
echo ""
echo "Restoring all files from commit 04d791e..."
git checkout 04d791e53ca32eed6f940f8471f97f35c0a6c4c0 -- .

# Check status
echo ""
echo "Files restored. Status:"
git status --short | head -20

# Commit the reversion
echo ""
echo "Committing the reversion..."
git add -A
git commit -m "Revert code to commit 04d791e - clean working state

Preserving all commit history from today's work.
Reverting to last known stable state."

# Push to GitHub
echo ""
echo "Pushing to GitHub..."
git push origin main

echo ""
echo "============================================"
echo "SUCCESS! Code reverted to commit 04d791e"
echo "============================================"
echo ""
echo "Current commit history (last 5):"
git log --oneline -5
echo ""
echo "The code is now back to the stable state from commit 04d791e."
echo "All of today's commits are preserved in history."
echo "Ready for a fresh start."
echo "============================================"
