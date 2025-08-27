#!/bin/bash

# Revert to working commit while preserving history
# This will restore code from 04d791e without losing recent commits

set -e

echo "============================================"
echo "Reverting to working commit 04d791e"
echo "Preserving all commit history"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# Show current status
echo "Current HEAD:"
git log --oneline -1

echo ""
echo "Target commit to restore:"
git log --oneline -1 04d791e53ca32eed6f940f8471f97f35c0a6c4c0

echo ""
echo "Checking out all files from the working commit..."
# This restores all files to the state they were in at that commit
git checkout 04d791e53ca32eed6f940f8471f97f35c0a6c4c0 -- .

echo ""
echo "Files restored. Checking status..."
git status --short

echo ""
echo "Committing the reversion..."
git add -A
git commit -m "Revert codebase to working state from commit 04d791e (preserving history)

This reverts the code to the last known working state while keeping all commit history intact.
Previous work on storage migration and backup systems is preserved in git history.
Reverting due to build issues with recent changes."

echo ""
echo "Pushing to GitHub..."
git push origin main

echo ""
echo "============================================"
echo "SUCCESS! Codebase reverted to working state"
echo "============================================"
echo ""
echo "Current status:"
git log --oneline -5
echo ""
echo "All recent commits are preserved in history."
echo "The codebase is now back to the working state from commit 04d791e."
echo ""
echo "Ready for you to explain what needs to be worked on next."
echo "============================================"
