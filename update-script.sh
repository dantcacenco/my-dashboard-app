#!/bin/bash

# Fix missing opening tag around line 74

echo "🔧 Fixing missing component tag..."

# Fix with Python for consistency
cat > fix_tag.py << 'EOF'
with open('app/proposals/[id]/ProposalView.tsx', 'r') as f:
    lines = f.readlines()

# Find the issue around line 74
for i in range(70, min(75, len(lines))):
    if 'progressAmount=' in lines[i]:
        # Check if there's a component opening before these props
        found_opening = False
        for j in range(i-5, i):
            if j >= 0 and '<PaymentStages' in lines[j]:
                found_opening = True
                break
        
        if not found_opening:
            # Add the opening tag
            lines[i-3] = lines[i-3] + '        <PaymentStages\n'
            print(f"Added <PaymentStages> opening tag")
        break

# Also check for closing tag
for i in range(70, min(76, len(lines))):
    if '</div>' in lines[i] and i > 0:
        # Make sure it's />
        lines[i] = lines[i].replace('</div>', '/>')
        break

with open('app/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.writelines(lines)

print("✅ Fixed")
EOF

python3 fix_tag.py
rm fix_tag.py

git add -A
git commit -m "Fix missing component opening tag" || exit 0
git push origin main

echo "✅ Pushed fix"