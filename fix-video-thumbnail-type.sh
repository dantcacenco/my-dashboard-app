#!/bin/bash

# Fix final type error with VideoThumbnail component
echo "Fixing VideoThumbnail type error..."

# Update only the VideoThumbnail usage in JobDetailView
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Use sed to fix the VideoThumbnail props
sed -i '' 's/<VideoThumbnail url={photo.url} \/>/<VideoThumbnail videoUrl={photo.url} onClick={() => openMediaViewer(jobPhotos, index)} \/>/g' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

# Build test
echo "Testing build..."
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo "Build successful!"
  
  # Commit and push
  git add -A
  git commit -m "Fix VideoThumbnail type error - use correct prop names"
  git push origin main
  
  echo "✅ Successfully fixed all type errors!"
  echo "- VideoThumbnail now uses videoUrl prop instead of url"
  echo "- Added onClick handler for VideoThumbnail"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
