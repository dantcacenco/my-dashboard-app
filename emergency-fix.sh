#!/bin/bash

# Emergency fix for broken ProposalView
set -e

echo "🚨 Emergency fix for ProposalView..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Restore the correct CreateJobButton usage in ProposalView
echo "📝 Fixing ProposalView syntax error..."
cat > fix-proposalview-emergency.py << 'EOF'
with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'r') as f:
    lines = f.readlines()

# Find and fix the duplicated CreateJobButton lines
fixed_lines = []
skip_next = 0
for i, line in enumerate(lines):
    if skip_next > 0:
        skip_next -= 1
        continue
    
    if '<CreateJobButton proposal={proposal} />' in line:
        # Add it once and skip any duplicates
        fixed_lines.append('            <CreateJobButton proposal={proposal} />\n')
        # Skip the next lines if they're duplicates
        j = i + 1
        while j < len(lines) and '<CreateJobButton proposal={proposal} />' in lines[j]:
            skip_next += 1
            j += 1
    elif line.strip() == '/>':
        # Skip orphaned closing tags
        continue
    else:
        fixed_lines.append(line)

with open('app/(authenticated)/proposals/[id]/ProposalView.tsx', 'w') as f:
    f.writelines(fixed_lines)

print("Fixed ProposalView.tsx")
EOF

python3 fix-proposalview-emergency.py
rm -f fix-proposalview-emergency.py

echo "✅ Fixed syntax error"

# Clean up all temp files
rm -f final-job-fix.sh

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -10

# Commit the fix
git add -A
git commit -m "Emergency fix: Repair ProposalView syntax error" || true
git push origin main

echo ""
echo "✅ EMERGENCY FIX APPLIED!"
echo ""
echo "⚠️ STILL NEED TO RUN SQL in Supabase:"
echo "--------------------------------------"
echo "ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_name TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_email TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS customer_phone TEXT;"
echo "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS created_by UUID;"
echo "--------------------------------------"
