#!/bin/bash
echo "🔧 Searching and replacing Stripe API version..."

# Find all files containing the old Stripe API version and replace with the new one
find . -type f -name "*.ts" -o -name "*.tsx" | while read file; do
    if grep -q "2024-11-20.acacia" "$file"; then
        echo "Updating Stripe API version in: $file"
        sed -i 's/2024-11-20.acacia/2025-07-30.basil/g' "$file"
    fi
done

# Check if any changes were made
if git diff --quiet; then
    echo "No files needed updating"
else
    echo "✅ Updated Stripe API version in the following files:"
    git diff --name-only
fi

# Commit and push
git add .
git commit -m "fix: update Stripe API version to 2025-07-30.basil"
git push origin main

echo "✅ Stripe API version updated successfully!"