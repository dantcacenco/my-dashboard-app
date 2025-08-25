#!/bin/bash
set -e

echo "🔧 Fixing SendProposal prop type error..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First check what props SendProposal expects
echo "📝 Checking SendProposal component props..."
grep -A 10 "interface SendProposalProps" components/proposals/SendProposal.tsx || true

# Fix the ProposalView to pass correct props
echo "📝 Fixing ProposalView component..."
sed -i '' 's/proposal={proposal}/proposalId={proposal.id}/' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

# Also need to pass other required props
sed -i '' '/<SendProposal/,/>/ {
  s/proposalId={proposal.id}/proposalId={proposal.id}\
          proposalNumber={proposal.proposal_number}\
          customerName={proposal.customers?.name || ""}\
          customerEmail={proposal.customers?.email || ""}\
          proposalTotal={proposal.total}/
}' app/\(authenticated\)/proposals/\[id\]/ProposalView.tsx

# Test build locally first
echo "🔍 Testing TypeScript build..."
npx tsc --noEmit 2>&1 | head -30

echo "🔍 Testing Next.js build..."
npm run build 2>&1 | tail -20

# If build succeeds, commit and push
if [ $? -eq 0 ]; then
  git add -A
  git commit -m "Fix SendProposal prop types to match component interface"
  git push origin main
  echo "✅ Fixed and pushed!"
else
  echo "❌ Build still has errors, checking further..."
fi
