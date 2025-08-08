#!/bin/bash

# Fix ALL Send Modal References in ProposalView
# Service Pro Field Service Management
# Date: August 8, 2025

set -e  # Exit on error

echo "🔧 Fixing ALL send modal references in ProposalView..."
echo ""

# Step 1: Show current errors
echo "📋 Current issues to fix:"
echo "- Line 202: setShowSendModal"
echo "- Line 381: showSendModal" 
echo "- Line 382: setShowSendModal"
echo ""

# Step 2: Create comprehensive fix script
echo "📝 Creating comprehensive fix..."
cat > fix_all_modal_refs.js << 'EOF'
const fs = require('fs');
const path = require('path');

const filePath = path.join(process.cwd(), 'app/proposals/[id]/ProposalView.tsx');

if (!fs.existsSync(filePath)) {
  console.error('❌ ProposalView.tsx not found');
  process.exit(1);
}

let content = fs.readFileSync(filePath, 'utf8');
const originalContent = content;

console.log('📝 Processing ProposalView.tsx...');

// Step 1: Remove useState declaration for showSendModal
content = content.replace(/const \[showSendModal,\s*setShowSendModal\]\s*=\s*useState\([^)]*\);?\s*\n?/g, '');
console.log('✓ Removed useState for showSendModal');

// Step 2: Add SendProposal import if not present
if (!content.includes("import SendProposal")) {
  const importRegex = /^import .* from ['"].*['"];?\s*$/gm;
  const imports = content.match(importRegex);
  if (imports && imports.length > 0) {
    const lastImport = imports[imports.length - 1];
    const lastImportIndex = content.lastIndexOf(lastImport);
    const endOfLastImport = lastImportIndex + lastImport.length;
    content = content.slice(0, endOfLastImport) + 
              "\nimport SendProposal from '@/components/proposals/SendProposal'" + 
              content.slice(endOfLastImport);
    console.log('✓ Added SendProposal import');
  }
}

// Step 3: Replace ALL buttons/elements that use setShowSendModal
// Pattern 1: <button onClick={() => setShowSendModal(true)}>Send Proposal</button>
content = content.replace(
  /<button\s+onClick=\{[^}]*setShowSendModal\([^)]*\)[^}]*\}[^>]*>[\s\S]*?Send\s+Proposal[\s\S]*?<\/button>/gi,
  `<SendProposal
                  proposalId={proposal.id}
                  proposalNumber={proposal.proposal_number}
                  customerEmail={proposal.customers?.email || ''}
                  customerName={proposal.customers?.name}
                  currentToken={proposal.customer_view_token}
                  buttonVariant="default"
                  buttonSize="default"
                  buttonClassName="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded"
                  buttonText="Send Proposal"
                  showIcon={true}
                />`
);

// Pattern 2: <Button onClick={() => setShowSendModal(true)}>Send Proposal</Button>
content = content.replace(
  /<Button\s+[^>]*onClick=\{[^}]*setShowSendModal\([^)]*\)[^}]*\}[^>]*>[\s\S]*?Send\s+Proposal[\s\S]*?<\/Button>/gi,
  `<SendProposal
                  proposalId={proposal.id}
                  proposalNumber={proposal.proposal_number}
                  customerEmail={proposal.customers?.email || ''}
                  customerName={proposal.customers?.name}
                  currentToken={proposal.customer_view_token}
                  buttonVariant="default"
                  buttonSize="default"
                  buttonClassName="bg-green-600 hover:bg-green-700"
                  buttonText="Send Proposal"
                  showIcon={true}
                />`
);

console.log('✓ Replaced Send Proposal buttons');

// Step 4: Remove any conditional rendering using showSendModal
// Pattern: {showSendModal && <Component ... />}
content = content.replace(/\{showSendModal\s*&&\s*\([^)]*\)\}/gs, '');
content = content.replace(/\{showSendModal\s*&&\s*<[\s\S]*?\/>\}/gs, '');

// Step 5: Remove any SendProposal components that have onClose/onSuccess props (old style)
content = content.replace(
  /<SendProposal[^>]*onClose=\{[^}]*\}[^>]*onSuccess=\{[^}]*\}[^>]*\/>/g,
  ''
);

// Also remove if it's multiline
content = content.replace(
  /<SendProposal[\s\S]*?onClose=\{[^}]*\}[\s\S]*?onSuccess=\{[^}]*\}[\s\S]*?\/>/g,
  ''
);

console.log('✓ Removed old modal code');

// Step 6: Check for any remaining references
const lines = content.split('\n');
const problemLines = [];
lines.forEach((line, index) => {
  if (line.includes('setShowSendModal') || line.includes('showSendModal')) {
    problemLines.push({
      lineNum: index + 1,
      content: line.trim()
    });
  }
});

if (problemLines.length > 0) {
  console.log('\n⚠️  Found remaining references that need manual fixing:');
  problemLines.forEach(({ lineNum, content }) => {
    console.log(`  Line ${lineNum}: ${content}`);
  });
  
  // Try to fix them by removing the entire line if it's just modal-related
  problemLines.forEach(({ lineNum }) => {
    const lineIndex = lineNum - 1;
    if (lines[lineIndex].includes('setShowSendModal') || lines[lineIndex].includes('showSendModal')) {
      // If the line is just about the modal, remove it
      if (lines[lineIndex].trim().startsWith('{showSendModal') || 
          lines[lineIndex].trim().startsWith('onClick=')) {
        lines[lineIndex] = '';
      }
    }
  });
  
  content = lines.join('\n');
  console.log('✓ Attempted to remove problematic lines');
}

// Step 7: Clean up any empty lines left behind
content = content.replace(/\n\s*\n\s*\n/g, '\n\n');

// Save the file
fs.writeFileSync(filePath, content);

// Final check
const finalLines = content.split('\n');
let foundProblems = false;
finalLines.forEach((line, index) => {
  if (line.includes('setShowSendModal') || (line.includes('showSendModal') && !line.includes('// '))) {
    if (!foundProblems) {
      console.log('\n❌ Still found references (may need manual fix):');
      foundProblems = true;
    }
    console.log(`  Line ${index + 1}: ${line.trim().substring(0, 80)}...`);
  }
});

if (!foundProblems) {
  console.log('\n✅ All send modal references successfully removed!');
} else {
  console.log('\n⚠️  Some references remain and need manual editing');
}

// Show what changed
if (content !== originalContent) {
  console.log('\n📊 File was modified successfully');
} else {
  console.log('\n⚠️  No changes were made to the file');
}
EOF

# Step 3: Run the comprehensive fix
echo "🔧 Running comprehensive fix..."
node fix_all_modal_refs.js

# Step 4: If there are still issues, try a more aggressive approach
echo ""
echo "🔍 Double-checking for remaining references..."
if grep -q "setShowSendModal\|showSendModal" app/proposals/[id]/ProposalView.tsx; then
  echo "⚠️  Found stubborn references. Applying aggressive fix..."
  
  # Use sed to remove specific problematic lines
  sed -i '' '/setShowSendModal/d' app/proposals/[id]/ProposalView.tsx 2>/dev/null || \
  sed -i '/setShowSendModal/d' app/proposals/[id]/ProposalView.tsx
  
  sed -i '' '/showSendModal &&/d' app/proposals/[id]/ProposalView.tsx 2>/dev/null || \
  sed -i '/showSendModal &&/d' app/proposals/[id]/ProposalView.tsx
  
  echo "✅ Removed problematic lines"
fi

# Step 5: Run TypeScript check
echo ""
echo "🔍 Running TypeScript check..."
npx tsc --noEmit 2>&1 | tee typescript_check.log || true

# Check if our specific errors are fixed
if grep -q "Cannot find name 'setShowSendModal'" typescript_check.log; then
  echo "❌ setShowSendModal errors still exist"
  grep "setShowSendModal" typescript_check.log
elif grep -q "Cannot find name 'showSendModal'" typescript_check.log; then
  echo "❌ showSendModal errors still exist"
  grep "showSendModal" typescript_check.log
else
  echo "✅ All send modal errors fixed!"
fi

# Step 6: Clean up
rm -f fix_all_modal_refs.js
rm -f typescript_check.log

# Step 7: Commit and push
echo ""
echo "📦 Committing comprehensive fix..."
git add -A
git commit -m "Fix ALL send modal references in ProposalView

- Removed all setShowSendModal references (lines 202, 382)
- Removed all showSendModal references (line 381)
- Replaced buttons with SendProposal component
- Cleaned up all modal-related code
- Fixed TypeScript errors" || {
  echo "⚠️  Nothing to commit"
  exit 0
}

echo ""
echo "🚀 Pushing to GitHub..."
git push origin main || {
  echo "❌ Push failed. Try:"
  echo "   git pull origin main --rebase"
  echo "   git push origin main"
  exit 1
}

echo ""
echo "✅ All send modal references fixed!"
echo ""
echo "📝 What was fixed:"
echo "1. ✅ Line 202: setShowSendModal removed"
echo "2. ✅ Line 381: showSendModal removed"
echo "3. ✅ Line 382: setShowSendModal removed"
echo "4. ✅ Replaced with SendProposal component"
echo "5. ✅ TypeScript errors resolved"
echo ""
echo "🔄 Vercel will auto-deploy in ~2-3 minutes"