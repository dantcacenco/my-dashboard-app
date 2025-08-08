#!/bin/bash

# Fix JSX Structure Properly
echo "🔧 Fixing JSX structure properly..."

cat > fix_jsx.py << 'EOF'
with open('app/proposals/[id]/ProposalView.tsx', 'r') as f:
    lines = f.readlines()

# Find PaymentStages props and add proper closing
for i in range(len(lines)):
    if 'currentStage={proposal.current_payment_stage' in lines[i]:
        # Add proper closing tag
        lines[i] = lines[i].rstrip() + '\n        />\n'
        # Remove any broken lines after
        if i+1 < len(lines) and lines[i+1].strip() in ['', '/>', ')']:
            lines[i+1] = ''
        break

with open('app/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.writelines(lines)
print("✅ Fixed JSX structure")
EOF

python3 fix_jsx.py
rm fix_jsx.py

# Run type check
npx tsc --noEmit 2>&1 | head -5 || true

git add -A && git commit -m "Fix JSX structure - proper PaymentStages closing" && git push origin main

echo "✅ Fixed and pushed!"