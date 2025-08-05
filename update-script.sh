#!/bin/bash
echo "🔧 Fixing dashboard nested array issue with simpler approach..."

# Find and replace the transformation lines
sed -i.bak 's/customers: p.customers ? \[p.customers\] : null \/\/ Convert object to array/customers: Array.isArray(p.customers) ? p.customers : (p.customers ? [p.customers] : null)/g' app/page.tsx
sed -i.bak 's/proposals: a.proposals ? \[a.proposals\] : null \/\/ Convert object to array/proposals: Array.isArray(a.proposals) ? a.proposals : (a.proposals ? [a.proposals] : null)/g' app/page.tsx

# Clean up backup files
rm -f app/page.tsx.bak

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error updating file"
    exit 1
fi

# Commit and push
git add .
git commit -m "fix: prevent nested arrays by checking if already array before wrapping"
git push origin main

echo "✅ Fixed! Dashboard now checks if data is already an array before wrapping"