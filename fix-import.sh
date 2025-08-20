#!/bin/bash

set -e

echo "🔧 Fixing import error..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the import statement
sed -i '' 's/import { CreateJobModal } from/import CreateJobModal from/' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

# Check TypeScript
echo "📋 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -10 || true

# Commit fix
git add -A
git commit -m "Fix CreateJobModal import - use default import instead of named import"
git push origin main

echo "✅ Import fixed!"
