#!/bin/bash
set -e

echo "🔧 Fixing Stripe API version..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the Stripe API version
sed -i '' "s/apiVersion: '2024-11-20.acacia'/apiVersion: '2025-07-30.basil'/g" app/api/create-payment-session/route.ts

echo "✅ Fixed Stripe API version"

# Test build
echo "🏗️ Testing build..."
npm run build 2>&1 | head -40

# Commit
git add -A
git commit -m "Fix Stripe API version to 2025-07-30.basil"
git push origin main

echo "✅ Stripe API version fixed!"
