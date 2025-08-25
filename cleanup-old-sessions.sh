#!/bin/bash

echo "🧹 Cleaning up old working session files..."

# Remove old working session files from root directory
echo "Removing old session files from root..."
rm -f working-session-august-19-complete.md
rm -f working-session-august-19-continued.md
rm -f working-session-august-19-final.md
rm -f working-session-august-19.md
rm -f working-session-final.md
rm -f working_session_aug_20.md
rm -f working_session_aug_20_final.md

# Remove the entire "MD files (project scope)" directory with old files
echo "Removing old MD files directory..."
rm -rf "MD files (project scope)"

# List remaining .md files to confirm
echo ""
echo "✅ Cleanup complete! Remaining documentation files:"
ls -la *.md | grep -E "PROJECT_SCOPE|WORKING_SESSION|README|FIXES"

echo ""
echo "📁 Current documentation structure:"
echo "  - PROJECT_SCOPE.md (Master reference document)"
echo "  - WORKING_SESSION.md (Current implementation tasks)"
echo "  - README.md (Original Next.js readme)"
echo "  - FIXES-COMPLETED.md (Historical fixes record)"

echo ""
echo "✅ All old/conflicting session files have been removed!"
echo ""
echo "👍 GREEN LIGHT: You can now also delete all working session documents"
echo "   from the project files section in the Claude desktop app."
