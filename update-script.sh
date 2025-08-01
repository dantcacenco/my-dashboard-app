#!/bin/bash

echo "🔧 Fixing customer display in ProposalsList..."

# Check if file exists
if [ ! -f "app/proposals/ProposalsList.tsx" ]; then
    echo "❌ Error: app/proposals/ProposalsList.tsx not found"
    exit 1
fi

# Create backup
cp app/proposals/ProposalsList.tsx app/proposals/ProposalsList.tsx.backup
echo "✅ Created backup"

# Fix the customer display with proper optional chaining
sed -i '' 's/{proposal\.customers\[0\]?\.\(name\|email\)}/{proposal.customers?.[0]?.\1/g' app/proposals/ProposalsList.tsx

# Add fallback for name
sed -i '' 's/{proposal\.customers?\.\[0\]?\.name}/{proposal.customers?.[0]?.name || "No customer"}/g' app/proposals/ProposalsList.tsx

# Add fallback for email  
sed -i '' 's/{proposal\.customers?\.\[0\]?\.email}/{proposal.customers?.[0]?.email || ""}/g' app/proposals/ProposalsList.tsx

echo "✅ Fixed customer display code"

# Stage changes
git add app/proposals/ProposalsList.tsx
echo "✅ Staged changes"

# Commit
git commit -m "fix: add optional chaining and fallbacks for customer data display

- Added optional chaining for customers array access
- Added fallback text 'No customer' when name is missing
- Added empty string fallback for email"

echo "✅ Committed changes"

# Push to GitHub
git push origin main

echo "✅ Done! Customer display should now work properly"