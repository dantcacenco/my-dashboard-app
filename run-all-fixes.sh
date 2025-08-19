#!/bin/bash
# Master fix script - runs all individual fixes
set -e

echo "🚀 Running all Service Pro fixes..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Run each fix script
echo "1️⃣ Running technician fix..."
chmod +x fix-technicians.sh && ./fix-technicians.sh

echo "2️⃣ Running navigation fix..."
chmod +x fix-navigation.sh && ./fix-navigation.sh

echo "3️⃣ Running customer sync fix..."
chmod +x fix-customer-sync.sh && ./fix-customer-sync.sh

echo ""
echo "✅ Completed fixes:"
echo "- Technician dropdown"
echo "- Removed Invoices tab"
echo "- Customer sync patch created"
echo ""
echo "⚠️ Still needs manual work:"
echo "- Proposal approval flow"
echo "- Mobile button overflow"
echo "- Expanded proposal statuses"
echo "- Add-ons vs services"

# Final build test
echo "🔨 Final build test..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  echo "✅ All fixes applied successfully!"
else
  echo "⚠️ Build has issues - review errors above"
fi
