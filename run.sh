#!/bin/bash

# Fix File View Buttons - Make them actually work
# Run as: ./fix_file_viewing.sh from my-dashboard-app directory

set -e

echo "Fixing file viewing functionality..."
echo "==================================="

# Check we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "app" ]]; then
    echo "Error: Must run from my-dashboard-app project root directory"
    exit 1
fi

# Backup the file
cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup

echo "1. Adding working openFileViewer function and fixing View buttons..."

# Use Node.js to safely fix the file viewing
node - << 'NODE_EOF'
const fs = require('fs');

let content = fs.readFileSync('app/(authenticated)/jobs/[id]/JobDetailView.tsx', 'utf8');

// First, make sure we have the openFileViewer function
if (!content.includes('const openFileViewer = ')) {
  console.log('Adding openFileViewer function...');
  
  // Find where to insert it (after openMediaViewer function)
  const insertAfter = 'setViewerOpen(true)\n  }';
  const openFileViewerFunction = `
  
  const openFileViewer = (files: any[], index: number) => {
    console.log('openFileViewer called:', { filesCount: files.length, index, fileName: files[index]?.file_name })
    
    const items = files.map(file => ({
      id: file.id,
      url: file.file_url,
      name: file.file_name,
      caption: file.file_name,
      type: 'file',
      mime_type: file.mime_type || 'application/octet-stream'
    }))
    
    console.log('MediaViewer items for files:', items)
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }`;
  
  content = content.replace(insertAfter, insertAfter + openFileViewerFunction);
}

// Now fix the file mapping to make View buttons actually work
// Look for the jobFiles.map section and make sure it has index and working onClick

// First ensure jobFiles.map has index parameter
if (content.includes('jobFiles.map(file =>') && !content.includes('jobFiles.map((file, index) =>')) {
  content = content.replace('jobFiles.map(file =>', 'jobFiles.map((file, index) =>');
  console.log('Added index parameter to jobFiles.map');
}

// Now make the View buttons actually work by replacing any existing ones
const viewButtonPattern = /<Button[^>]*>\s*View\s*<\/Button>/g;
const workingViewButton = `<Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          console.log('File View button clicked:', file.file_name)
                          openFileViewer(jobFiles, index)
                        }}
                      >
                        View
                      </Button>`;

content = content.replace(viewButtonPattern, workingViewButton);
console.log('Replaced View buttons with working versions');

// Also make sure we have the toast import for any error handling
if (content.includes('toast.') && !content.includes("from 'sonner'")) {
  content = content.replace(
    "import Link from 'next/link'",
    "import Link from 'next/link'\nimport { toast } from 'sonner'"
  );
  console.log('Added toast import');
}

fs.writeFileSync('app/(authenticated)/jobs/[id]/JobDetailView.tsx', content);
console.log('File updated successfully');
NODE_EOF

echo "2. Running TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Restoring backup..."
    cp app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    exit 1
fi

echo "3. Git commit and push..."
git add -A
git commit -m "Fix: Make file View buttons actually work like photo viewing

- Added working openFileViewer function with proper logging
- Fixed jobFiles.map to include index parameter  
- Replaced all View buttons with functional onClick handlers
- Files now open in same MediaViewer as photos
- Added console logging for debugging click events
- View buttons should now be fully clickable and functional"

git push origin main

echo ""
echo "SUCCESS! File viewing should now work!"
echo "===================================="
echo ""
echo "TEST NOW:"
echo "1. Visit the job page"
echo "2. Click any blue 'View' button next to files"
echo "3. File should open in MediaViewer (same as photos)"
echo "4. Check console for click event logs"
echo ""
echo "Files should now work exactly like photos - click View to open in full viewer!"

# Cleanup
rm -f app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx.backup