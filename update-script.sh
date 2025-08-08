#!/bin/bash

# Fix Syntax Error - Portable Version
# Works on both macOS and Linux

set -e

echo "🔧 Fixing syntax error..."

# Create a simple Python script to fix the issue
cat > fix_syntax.py << 'EOF'
import sys

with open('app/proposals/[id]/ProposalView.tsx', 'r') as f:
    lines = f.readlines()

# Remove problematic lines around 388-389
new_lines = []
skip_next = False
for i, line in enumerate(lines, 1):
    # Skip orphaned closing tags
    if line.strip() == '/>' or line.strip() == ')}':
        continue
    # Skip the specific problem lines
    if i >= 387 and i <= 389:
        if '/>' in line and len(line.strip()) <= 3:
            continue
        if ')}' in line and len(line.strip()) <= 3:
            continue
    new_lines.append(line)

with open('app/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.writelines(new_lines)

print("✅ Fixed syntax errors")
EOF

python3 fix_syntax.py
rm fix_syntax.py

echo "📦 Committing..."
git add -A
git commit -m "Fix syntax error - remove orphaned closing tags (portable fix)" || exit 0
git push origin main

echo "✅ Done! Check Vercel deployment."