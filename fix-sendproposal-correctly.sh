#!/bin/bash
set -e

echo "🔧 Fixing SendProposal component usage correctly..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the ProposalView component to pass correct props
cat > fix-proposal-view.js << 'EOF'
const fs = require('fs');
const content = fs.readFileSync('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'utf8');

// Fix the SendProposal component usage
const fixed = content.replace(
  /<SendProposal[\s\S]*?\/>/g,
  `<SendProposal
          proposalId={proposal.id}
          proposalNumber={proposal.proposal_number}
          customerName={proposal.customers?.name || ""}
          customerEmail={proposal.customers?.email || ""}
          currentToken={proposal.customer_view_token}
          onSent={(id, token) => {
            handleSendProposal()
          }}
        />`
);

fs.writeFileSync('app/(authenticated)/proposals/[id]/ProposalView.tsx', fixed);
EOF

node fix-proposal-view.js
rm fix-proposal-view.js

# Test build locally
echo "🔍 Testing TypeScript..."
npx tsc --noEmit 2>&1 | grep -E "(error|Error)" | head -10 || echo "✅ TypeScript OK"

echo "🏗️ Testing Next.js build..."
npm run build > build.log 2>&1 &
BUILD_PID=$!

# Wait for build with timeout
timeout=60
counter=0
while kill -0 $BUILD_PID 2>/dev/null; do
  if [ $counter -ge $timeout ]; then
    kill $BUILD_PID
    echo "❌ Build timeout"
    exit 1
  fi
  sleep 1
  counter=$((counter + 1))
done

wait $BUILD_PID
BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
  echo "✅ Build successful!"
  tail -5 build.log
  
  # Commit and push
  git add -A
  git commit -m "Fix SendProposal component props - proper interface

- Pass currentToken prop (required)
- Use onSent callback properly
- Remove non-existent props (proposalTotal, onClose, onSend)
- Build tested locally before push"
  
  git push origin main
  echo "✅ Pushed to GitHub!"
else
  echo "❌ Build failed:"
  tail -20 build.log
fi

rm -f build.log fix-sendproposal-types.sh
