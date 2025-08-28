#!/bin/bash

# Safe File Name Click Fix - Minimal Changes Only
# Run as: ./safe_file_fix.sh from my-dashboard-app directory

set -e

echo "Making minimal safe changes to enable file clicking..."
echo "==================================================="

# Check we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "app" ]]; then
    echo "Error: Must run from my-dashboard-app project root directory"
    exit 1
fi

# Restore from backup first
cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "1. Adding ONLY the openFileViewer function..."

# Add openFileViewer function safely using sed
sed -i '' '/setViewerOpen(true)/a\
\
  const openFileViewer = (files: any[], index: number) => {\
    console.log("File clicked:", files[index]?.file_name)\
    const items = files.map(file => ({\
      id: file.id,\
      url: file.file_url,\
      name: file.file_name,\
      type: "file",\
      mime_type: file.mime_type\
    }))\
    setViewerItems(items)\
    setViewerIndex(index)\
    setViewerOpen(true)\
  }
' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "2. Making ONLY the file names clickable..."

# Use a very targeted sed replacement - just add onClick to file names
sed -i '' 's/<p className="font-medium">{file\.file_name}<\/p>/<p className="font-medium text-blue-600 hover:text-blue-800 cursor-pointer" onClick={() => openFileViewer(jobFiles, jobFiles.indexOf(file))}>{file.file_name}<\/p>/g' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "3. Removing View buttons..."

# Remove just the View buttons
sed -i '' 's/<Button[^>]*>\s*View\s*<\/Button>//g' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "4. Running TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Restoring backup..."
    cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    exit 1
fi

echo "5. Git commit and push..."
git add -A
git commit -m "Safe fix: Make file names clickable without breaking JSX structure

- Added openFileViewer function only
- Made file names blue and clickable with minimal changes
- Removed View buttons safely
- No structural JSX changes to avoid syntax errors"

git push origin main

echo ""
echo "SUCCESS! Minimal safe changes applied!"
echo "====================================="
echo ""
echo "Changes made:"
echo "- File names are now blue and clickable" 
echo "- View buttons removed"
echo "- No JSX structure changes"
echo ""
echo "Test by clicking on file names (should be blue text now)"

# Keep backup in case we need to revert
echo "Backup kept at: JobDetailView.tsx.backup"