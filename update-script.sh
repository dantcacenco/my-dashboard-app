#!/bin/bash

echo "🔧 Fixing Stripe API version..."

# Fix the Stripe API version to match the type definition
perl -i -pe "s/apiVersion: '[\d-]+\.[\w]+'/apiVersion: '2025-07-30.basil'/" app/api/create-payment/route.ts

# Commit the fix
git add .
git commit -m "fix: use correct Stripe API version 2025-07-30.basil"
git push origin main

echo "✅ Fixed Stripe API version!"
echo ""
echo "The build should now pass with the correct API version."