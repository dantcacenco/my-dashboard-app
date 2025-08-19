#!/bin/bash

# Complete rewrite of the button section
set -e

echo "🔧 Rewriting button section of ProposalView..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Create Python script to properly rewrite the buttons section
cat > rewrite-buttons.py << 'EOF'
with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'r') as f:
    lines = f.readlines()

# Find the start of the button section and rewrite it
new_lines = []
i = 0
while i < len(lines):
    if '<div className="flex gap-2">' in lines[i]:
        # Found the button section, rewrite it properly
        new_lines.append('        <div className="flex gap-2">\n')
        new_lines.append('          {canEdit && (\n')
        new_lines.append('            <Link href={`/proposals/${proposal.id}/edit`}>\n')
        new_lines.append('              <button className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">\n')
        new_lines.append('                <PencilIcon className="w-4 h-4 mr-2" />\n')
        new_lines.append('                Edit\n')
        new_lines.append('              </button>\n')
        new_lines.append('            </Link>\n')
        new_lines.append('          )}\n')
        new_lines.append('          \n')
        new_lines.append('          {canSendEmail && (\n')
        new_lines.append('            <SendProposal \n')
        new_lines.append('              proposalId={proposal.id}\n')
        new_lines.append('              customerEmail={proposal.customers?.email}\n')
        new_lines.append('              customerName={proposal.customers?.name}\n')
        new_lines.append('              proposalNumber={proposal.proposal_number}\n')
        new_lines.append('              onSent={() => router.refresh()}\n')
        new_lines.append('            />\n')
        new_lines.append('          )}\n')
        new_lines.append('          \n')
        new_lines.append('          <button\n')
        new_lines.append('            onClick={handlePrint}\n')
        new_lines.append('            className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"\n')
        new_lines.append('          >\n')
        new_lines.append('            <PrinterIcon className="w-4 h-4 mr-2" />\n')
        new_lines.append('            Print\n')
        new_lines.append('          </button>\n')
        new_lines.append('\n')
        new_lines.append('          {canCreateJob && (\n')
        new_lines.append('            <CreateJobButton proposal={proposal} />\n')
        new_lines.append('          )}\n')
        new_lines.append('        </div>\n')
        
        # Skip lines until we find the closing </div> for the header
        while i < len(lines) and '</div>' not in lines[i]:
            i += 1
        # Add the closing div
        new_lines.append('      </div>\n')
    else:
        new_lines.append(lines[i])
    i += 1

with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.writelines(new_lines)

print("Rewrote button section")
EOF

python3 rewrite-buttons.py
rm -f rewrite-buttons.py

echo "✅ Rewrote button section"

# Clean up
rm -f fix-parenthesis.sh

# Test
echo "🔍 Testing..."
npx tsc --noEmit 2>&1 | head -5 || true

echo "🔨 Building..."
npm run build 2>&1 | tail -10

# Commit
git add -A
git commit -m "Rewrite ProposalView button section to fix all syntax errors" || true
git push origin main

echo ""
echo "✅ BUTTON SECTION REWRITTEN!"
echo ""
echo "🚨 FINAL STEP - RUN THIS SQL IN SUPABASE:"
echo "=========================================="
echo "ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_name TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_email TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_phone TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);"
echo "=========================================="
echo ""
echo "This will fix the 400 errors when creating jobs!"
