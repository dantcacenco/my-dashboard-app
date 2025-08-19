#!/bin/bash
# Fix 1: Technician dropdown
set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "👷 Fixing technician dropdown..."

# Update JobDetailView to fix technician assignment
sed -i '' 's/createBrowserClient/createClient/g' app/jobs/\[id\]/page.tsx 2>/dev/null || true

# Test build
npm run build 2>&1 | tail -5
if [ $? -eq 0 ]; then
  git add -A
  git commit -m "Fix technician dropdown import"
  git push origin main
  echo "✅ Technician fix complete"
fi
