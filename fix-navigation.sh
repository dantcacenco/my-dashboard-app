#!/bin/bash
# Fix 2: Remove Invoices tab
set -e
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

echo "🗑️ Removing Invoices tab..."

# Update Navigation to remove Invoices
sed -i '' "/{ href: '\/invoices'/d" app/components/Navigation.tsx 2>/dev/null || true

# Test and commit
npm run build 2>&1 | tail -5
if [ $? -eq 0 ]; then
  git add -A
  git commit -m "Remove Invoices tab from navigation"
  git push origin main
  echo "✅ Navigation fixed"
fi
