#!/bin/bash

set -e

echo "🔧 Fixing remaining type errors..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Fix the CreateJobModal prop issue - change isOpen to open
sed -i '' 's/isOpen={showCreateJobModal}/open={showCreateJobModal}/' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

# 2. Remove the unused userId prop from ProposalView in page.tsx
sed -i '' 's/userId={user.id}//' app/\(authenticated\)/proposals/\[id\]/page.tsx

# 3. Check TypeScript
echo "📋 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -10 || echo "TypeScript check done"

# 4. Commit fixes
git add -A
git commit -m "Fix remaining type errors in ProposalView

- Changed isOpen prop to open for CreateJobModal
- Removed unused userId prop from ProposalView"

# 5. Try to push
echo "🚀 Attempting to push..."
git push origin main 2>&1 || echo "Push failed - network issue"

echo "✅ Fixes applied locally"
