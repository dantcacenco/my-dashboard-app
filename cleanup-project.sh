#!/bin/bash

echo "🧹 Cleaning up old scripts and temporary files..."

# Remove old script files
rm -f final-build-fix.sh
rm -f fix-sendproposal-correctly.sh
rm -f fix-sendproposal-types.sh
rm -f revert-to-e1027fd.sh
rm -f revert-to-stable.sh
rm -f trigger-vercel-rebuild.sh
rm -f cleanup-old-sessions.sh

# Remove old log files
rm -f build.log
rm -f build_check.log
rm -f type_check.log
rm -f tsconfig.check.tsbuildinfo

# Remove old markdown files (keeping only PROJECT_SCOPE.md and WORKING_SESSION.md)
rm -f FIXES-COMPLETED.md

# Clean up any backup files
find . -name "*.backup" -type f -delete
find . -name "*.bak" -type f -delete

echo "✅ Cleanup complete!"
echo ""
echo "📁 Remaining project files:"
echo "  - PROJECT_SCOPE.md (master reference)"
echo "  - WORKING_SESSION.md (current tasks)"
echo "  - README.md (project readme)"
echo ""

# Commit the cleanup
git add -A
git commit -m "chore: clean up old scripts and temporary files"
git push origin main

echo "✅ Changes committed and pushed!"
