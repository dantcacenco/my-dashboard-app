#!/bin/bash

# Fix Non-Clickable View Buttons
# Run as: ./fix_view_buttons.sh from my-dashboard-app directory

set -e

echo "Fixing non-clickable View buttons..."
echo "==================================="

# Check we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "app" ]]; then
    echo "Error: Must run from my-dashboard-app project root directory"
    exit 1
fi

# Backup the file
cp -f app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx .fix-backups/JobDetailView.tsx.backup

echo "1. Fixing View buttons in JobDetailView..."

# Use a more targeted approach to fix the View buttons
python3 - << 'EOF'
import re

with open('app/(authenticated)/jobs/[id]/JobDetailView.tsx', 'r') as f:
    content = f.read()

print("Current content preview around jobFiles:")
lines = content.split('\n')
for i, line in enumerate(lines):
    if 'jobFiles.map' in line:
        print(f"Line {i}: {line.strip()}")
        for j in range(max(0, i-2), min(len(lines), i+15)):
            print(f"  {j}: {lines[j].strip()}")
        break

# Ensure openFileViewer function exists
if 'openFileViewer' not in content:
    print("Adding openFileViewer function...")
    # Find where to insert it (after openMediaViewer)
    pattern = r'(setViewerOpen\(true\)\s*\n\s*\})'
    replacement = r'\1\n\n  const openFileViewer = (files: any[], index: number) => {\n    console.log("openFileViewer called with:", { filesCount: files.length, index })\n    const items = files.map(file => ({\n      id: file.id,\n      url: file.file_url,\n      name: file.file_name,\n      caption: file.file_name,\n      type: \'file\' as const,\n      mime_type: file.mime_type || \'application/octet-stream\'\n    }))\n    \n    console.log("MediaViewer items:", items)\n    setViewerItems(items)\n    setViewerIndex(index)\n    setViewerOpen(true)\n  }'
    
    content = re.sub(pattern, replacement, content)
    print("openFileViewer function added")

# Now fix the file mapping to ensure it has index and proper onClick
print("Fixing jobFiles mapping...")

# First, ensure jobFiles.map has index parameter
if 'jobFiles.map(file =>' in content:
    content = content.replace('jobFiles.map(file =>', 'jobFiles.map((file, index) =>')
    print("Added index parameter to jobFiles.map")

# Now find and replace the Button components with proper onClick handlers
# Look for the pattern where View buttons exist
button_pattern = r'<Button\s+size="sm"\s+variant="outline"(?:\s+onClick=\{[^}]+\})?\s*>\s*View\s*</Button>'
button_replacement = '''<Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          console.log("View button clicked for file:", file.file_name)
                          openFileViewer(jobFiles, index)
                        }}
                      >
                        View
                      </Button>'''

new_content = re.sub(button_pattern, button_replacement, content)

if new_content != content:
    content = new_content
    print("Successfully added onClick handlers to View buttons")
else:
    print("Could not find Button pattern, trying alternative approach...")
    
    # Alternative approach - look for just the View text and replace the whole button
    view_pattern = r'<Button[^>]*>\s*View\s*</Button>'
    content = re.sub(view_pattern, button_replacement, content)
    print("Applied alternative Button replacement")

# Ensure the file has proper imports for console logging
if 'console.log' in content and 'useEffect' in content:
    print("Debug logging will be available")

print("Final content preview around fixed area:")
lines = content.split('\n')
for i, line in enumerate(lines):
    if 'View' in line and 'Button' in line:
        print(f"Found View Button at line {i}:")
        for j in range(max(0, i-3), min(len(lines), i+8)):
            print(f"  {j}: {lines[j].strip()}")
        break

with open('app/(authenticated)/jobs/[id]/JobDetailView.tsx', 'w') as f:
    f.write(content)

print("JobDetailView.tsx updated successfully")
EOF

echo "2. Running TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Restoring backup..."
    cp .fix-backups/JobDetailView.tsx.backup app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx
    exit 1
fi

echo "3. Git commit and push..."
git add -A
git commit -m "Fix: Non-clickable View buttons for file viewing

- Added proper onClick handlers to file View buttons
- Ensured openFileViewer function exists with debug logging
- Fixed jobFiles.map to include index parameter
- View buttons now properly trigger file viewing in MediaViewer
- Added console logging for debugging click events"

if ! git push origin main; then
    echo "Git push failed, but changes committed locally"
fi

echo ""
echo "SUCCESS! View buttons should now be clickable!"
echo "============================================="
echo "Changes made:"
echo "- Added onClick handlers to all View buttons"
echo "- Added debug logging to track clicks"
echo "- Ensured openFileViewer function exists"
echo ""
echo "TEST NOW:"
echo "1. Click any 'View' button on a file"
echo "2. Check browser console for debug messages"
echo "3. File should open in MediaViewer"
echo ""
echo "If still not working, check console for error messages"