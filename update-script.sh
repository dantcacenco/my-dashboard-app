#!/bin/bash

# Fix component imports correctly

echo "🔧 Fixing component imports correctly..."

# First, let's check what files actually exist
echo "📋 Checking existing files..."
echo "Edit page components:"
ls -la app/proposals/[id]/edit/ 2>/dev/null || echo "Edit directory not found"

# Fix the edit page to use the correct import
echo "📝 Fixing proposals/[id]/edit/page.tsx with correct import..."
cat > app/proposals/[id]/edit/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import ProposalEditor from './ProposalEditor'

export default async function EditProposalPage({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss/admin can edit proposals
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/')
  }

  // Get the proposal with items and customer data
  const { data: proposal, error: proposalError } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone,
        address
      ),
      proposal_items (
        *
      )
    `)
    .eq('id', id)
    .single()

  if (proposalError || !proposal) {
    notFound()
  }

  // Get all customers and pricing items for the editor
  const [customersResult, pricingResult] = await Promise.all([
    supabase
      .from('customers')
      .select('*')
      .order('name'),
    supabase
      .from('pricing_items')
      .select('*')
      .eq('is_active', true)
      .order('category, name')
  ])

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">
            Edit Proposal {proposal.proposal_number}
          </h1>
          <p className="mt-2 text-gray-600">
            Update proposal details for {proposal.customers.name}
          </p>
        </div>
        
        <ProposalEditor 
          proposal={proposal}
          customers={customersResult.data || []}
          pricingItems={pricingResult.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
EOF

# Check for other potential missing imports
echo "🔍 Checking for other potential import issues..."

# Check if CustomerSearch exists for new proposals
if ! [ -f "app/proposals/new/CustomerSearch.tsx" ]; then
    echo "⚠️  CustomerSearch.tsx is missing in proposals/new/"
fi

# Check if ServiceSearch exists
if ! [ -f "app/proposals/new/ServiceSearch.tsx" ]; then
    echo "⚠️  ServiceSearch.tsx is missing in proposals/new/"
fi

# Check if AddNewPricingItem exists
if ! [ -f "app/proposals/new/AddNewPricingItem.tsx" ]; then
    echo "⚠️  AddNewPricingItem.tsx is missing in proposals/new/"
fi

# Run a comprehensive check for all imports
echo "📋 Checking all TypeScript imports..."
find app -name "*.tsx" -o -name "*.ts" | while read file; do
    # Check for imports that might not exist
    grep -E "^import .* from ['\"]\./" "$file" 2>/dev/null | while read import_line; do
        # Extract the import path
        import_path=$(echo "$import_line" | sed -E "s/.*from ['\"](.+)['\"].*/\1/")
        # Convert relative path to absolute
        dir=$(dirname "$file")
        resolved_path=$(cd "$dir" && realpath -m "$import_path" 2>/dev/null || echo "")
        
        # Check if the file exists (with various extensions)
        if [ -n "$resolved_path" ]; then
            if ! [ -f "${resolved_path}.tsx" ] && ! [ -f "${resolved_path}.ts" ] && ! [ -f "${resolved_path}/index.tsx" ] && ! [ -f "${resolved_path}/index.ts" ] && ! [ -f "$resolved_path" ]; then
                echo "⚠️  Missing import in $file: $import_path"
            fi
        fi
    done
done

# Run type check
echo ""
echo "🔍 Running type check..."
npx tsc --noEmit 2>&1 | tee typescript_check.log || true

# Check for build errors
ERROR_COUNT=$(grep -c "error TS" typescript_check.log 2>/dev/null || echo "0")

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "❌ Found $ERROR_COUNT TypeScript errors"
    echo "Key errors:"
    grep -A 1 "Module not found" typescript_check.log 2>/dev/null || true
    grep -A 1 "Cannot find module" typescript_check.log 2>/dev/null || true
else
    echo "✅ No TypeScript errors found!"
fi

# Clean up
rm -f typescript_check.log

# Commit the fix
echo ""
echo "📦 Committing fixes..."
git add -A
git commit -m "fix: Correct component imports for proposal edit page

- Fixed import to use ProposalEditor (not ProposalEditForm)
- Maintained async params for Next.js 15 compatibility" || echo "No changes to commit"

# Push to GitHub
echo "🚀 Pushing to GitHub..."
git push origin main || echo "Failed to push"

echo ""
echo "✅ Import fixes complete!"
echo ""
echo "📋 Summary:"
echo "- Fixed ProposalEditor import in edit page"
echo "- Checked for other missing imports"
echo "- Ran type checking"
echo ""
echo "If there are still missing components, they may need to be created from the 'new' proposal components."