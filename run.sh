#!/bin/bash

# SURGICAL FIX: Target Exact Lines from Diagnostic
# Run as: ./surgical_fix.sh from my-dashboard-app directory

set -e

echo "SURGICAL FIX: Targeting exact lines found in diagnostic..."
echo "======================================================="

# Backup first
cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup

echo "1. First, let's see the current file state around line 561-570..."
echo "Current content:"
sed -n '561,570p' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx | nl -v561

echo ""
echo "2. Adding openFileViewer function if missing..."

# Check if openFileViewer exists
if ! grep -q "const openFileViewer" app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx; then
    echo "Adding openFileViewer function..."
    
    # Find the exact line with setViewerOpen(true) and add after it
    awk '/setViewerOpen\(true\)/ && !added {print; print ""; print "  const openFileViewer = (files: any[], index: number) => {"; print "    console.log(\"File clicked:\", files[index]?.file_name)"; print "    const items = files.map(file => ({"; print "      id: file.id,"; print "      url: file.file_url,"; print "      name: file.file_name,"; print "      type: \"file\","; print "      mime_type: file.mime_type"; print "    }))"; print "    setViewerItems(items)"; print "    setViewerIndex(index)"; print "    setViewerOpen(true)"; print "  }"; added=1; next} 1' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx > temp.tsx && mv temp.tsx app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    
    echo "openFileViewer function added"
else
    echo "openFileViewer function already exists"
fi

echo ""
echo "3. Now fixing the exact jobFiles.map line (line 563)..."

# Replace the specific line - add index parameter
sed -i '' 's/{jobFiles\.map((file) =>/{jobFiles.map((file, index) =>/g' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "Added index parameter to jobFiles.map"

echo ""
echo "4. Making file names clickable and removing View buttons..."

# Make the file name clickable by replacing the <p> tag containing file name
sed -i '' 's/<p className="font-medium">{file\.file_name}<\/p>/<p className="font-medium text-blue-600 hover:text-blue-800 cursor-pointer" onClick={() => openFileViewer(jobFiles, index)}>{file.file_name}<\/p>/g' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

# Remove any View buttons
sed -i '' '/<Button.*>View<\/Button>/d' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

echo "Made file names clickable and removed View buttons"

echo ""
echo "5. Verifying changes..."
echo "New content around line 561-570:"
sed -n '561,575p' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx | nl -v561

echo ""
echo "6. TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Restoring backup..."
    cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    exit 1
fi

echo "7. Git commit and push..."
git add -A
git commit -m "SURGICAL FIX: Target exact lines to make file names clickable

- Added openFileViewer function using awk for precise placement
- Fixed line 563: jobFiles.map((file) => to jobFiles.map((file, index) =>  
- Made file names blue and clickable with onClick handler
- Removed View buttons entirely
- Targeted exact lines found in diagnostic"

git push origin main

echo ""
echo "SUCCESS! Surgical changes applied to exact lines!"
echo "=============================================="
echo ""
echo "Changes made to EXACT lines identified in diagnostic:"
echo "- Line 563: Added index parameter to jobFiles.map"
echo "- File names now have onClick handler"
echo "- View buttons removed"
echo ""
echo "Test now - file names should be blue and clickable!"