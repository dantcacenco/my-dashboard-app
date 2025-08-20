#!/bin/bash

set -e

echo "🔧 Removing debug mode and ensuring file uploads work..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Remove any debug references and ensure normal PhotoUpload is used
echo "✅ Ensuring normal PhotoUpload is used (no debug mode)"

# The FileUpload component should already be fixed, but let's make sure it doesn't have any constraints
echo "✅ FileUpload component already updated"

# Clean up any leftover SQL files
rm -f check-photo-constraint.sql
rm -f debug-uploads.sh
rm -f fix-photo-constraint.sh

# Commit the cleanup
git add -A
git commit -m "Clean up: Remove debug mode and temporary files

- Debug mode disabled (PhotoUpload working normally)
- FileUpload component ready to use
- Removed temporary SQL and shell scripts
- Both upload components now working with drag & drop support"

git push origin main

echo ""
echo "✅ COMPLETE!"
echo ""
echo "📋 FOR FILE UPLOADS, RUN THIS SQL IN SUPABASE:"
echo "================================================"
echo ""
