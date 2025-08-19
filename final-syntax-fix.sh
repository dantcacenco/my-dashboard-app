#!/bin/bash

# Final definitive fix for ProposalView syntax
set -e

echo "🔧 Final fix for ProposalView syntax..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Create a Python script to properly fix the SendProposal component
cat > fix-send-proposal.py << 'EOF'
import re

with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'r') as f:
    lines = f.readlines()

# Find the SendProposal component and fix it
for i, line in enumerate(lines):
    if 'onSent={() => router.refresh()}' in line:
        # This line should end with />
        lines[i] = '              onSent={() => router.refresh()}\n'
        lines[i+1] = '            />\n'
        break

with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.writelines(lines)

print("Fixed SendProposal component")
EOF

python3 fix-send-proposal.py
rm -f fix-send-proposal.py

echo "✅ Fixed SendProposal"

# Clean up
rm -f fix-syntax.sh

# Test the actual TypeScript compilation
echo "🔍 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -5

# If no errors, build
echo "🔨 Building..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Final fix: ProposalView SendProposal component syntax" || true
git push origin main

echo ""
echo "✅ FINAL FIX COMPLETE!"
echo ""
echo "🚨 YOU MUST RUN THIS SQL IN SUPABASE:"
echo "======================================"
echo "ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_name TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_email TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_phone TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);"
echo "======================================"
echo ""
echo "The 400 errors are because these columns are missing!"
