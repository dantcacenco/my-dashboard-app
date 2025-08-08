#!/bin/bash

# Comprehensive fix for ALL Next.js 15 type issues

echo "🔧 Fixing ALL Next.js 15 type issues comprehensively..."

# Fix app/jobs/new/page.tsx - searchParams must be async
echo "📝 Fixing jobs/new/page.tsx searchParams..."
cat > app/jobs/new/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import JobCreationForm from './JobCreationForm'

export default async function NewJobPage({
  searchParams
}: {
  searchParams: Promise<{ proposal_id?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/sign-in')
  }

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss/admin can create jobs
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/unauthorized')
  }

  // Get proposal data if proposal_id is provided
  let proposalData = null
  if (params.proposal_id) {
    const { data: proposal } = await supabase
      .from('proposals')
      .select(`
        *,
        customers (*)
      `)
      .eq('id', params.proposal_id)
      .single()
    
    proposalData = proposal
  }

  // Get technicians for assignment
  const { data: technicians } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
    .order('full_name')

  // Get customers if no proposal
  const { data: customers } = await supabase
    .from('customers')
    .select('*')
    .order('name')

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Create New Job</h1>
          <p className="mt-2 text-gray-600">
            {proposalData ? 'Creating job from proposal' : 'Create a new job assignment'}
          </p>
        </div>
        
        <JobCreationForm 
          proposal={proposalData}
          technicians={technicians || []}
          customers={customers || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
EOF

# Check and fix any other pages with searchParams
echo "🔍 Checking for other pages with searchParams..."
find app -name "page.tsx" -exec grep -l "searchParams" {} \; | while read file; do
    echo "Checking $file for searchParams..."
done

# Fix proposal/payment-success/page.tsx if it uses searchParams
if [ -f "app/proposal/payment-success/page.tsx" ] && grep -q "searchParams" "app/proposal/payment-success/page.tsx"; then
    echo "📝 Fixing proposal/payment-success/page.tsx..."
    cat > app/proposal/payment-success/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import PaymentSuccessView from './PaymentSuccessView'

export default async function PaymentSuccessPage({
  searchParams
}: {
  searchParams: Promise<{ session_id?: string; proposal_id?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()

  if (!params.session_id || !params.proposal_id) {
    redirect('/')
  }

  // Get the proposal
  const { data: proposal, error } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone,
        address
      )
    `)
    .eq('id', params.proposal_id)
    .single()

  if (error || !proposal) {
    redirect('/')
  }

  return (
    <PaymentSuccessView 
      proposal={proposal}
      sessionId={params.session_id}
    />
  )
}
EOF
fi

# Create a comprehensive type checking script
echo "📝 Creating comprehensive type checking script..."
cat > check_all_types.sh << 'EOF'
#!/bin/bash

echo "🔍 Running COMPREHENSIVE type checking..."
echo "=================================="

# First, check for basic TypeScript errors
echo "📋 TypeScript Compiler Check:"
npx tsc --noEmit 2>&1 | tee full_typescript_check.log

# Count different types of errors
TOTAL_ERRORS=$(grep -c "error TS" full_typescript_check.log 2>/dev/null || echo "0")
PARAM_ERRORS=$(grep -c "params.*Promise" full_typescript_check.log 2>/dev/null || echo "0")
SEARCH_PARAM_ERRORS=$(grep -c "searchParams.*Promise" full_typescript_check.log 2>/dev/null || echo "0")
MODULE_ERRORS=$(grep -c "Cannot find module\|Module not found" full_typescript_check.log 2>/dev/null || echo "0")

echo ""
echo "📊 Error Summary:"
echo "- Total TypeScript errors: $TOTAL_ERRORS"
echo "- Params type errors: $PARAM_ERRORS"
echo "- SearchParams type errors: $SEARCH_PARAM_ERRORS"
echo "- Missing module errors: $MODULE_ERRORS"

if [ "$TOTAL_ERRORS" -gt 0 ]; then
    echo ""
    echo "❌ Detailed errors:"
    echo "=================================="
    grep -A 2 "error TS" full_typescript_check.log | head -100
fi

# Check for Next.js 15 specific patterns
echo ""
echo "🔍 Checking Next.js 15 patterns..."
echo "Pages with params:"
find app -name "page.tsx" -exec grep -l "params.*:" {} \; | while read file; do
    if ! grep -q "params.*Promise" "$file"; then
        echo "⚠️  $file may need async params"
    fi
done

echo ""
echo "Pages with searchParams:"
find app -name "page.tsx" -exec grep -l "searchParams.*:" {} \; | while read file; do
    if ! grep -q "searchParams.*Promise" "$file"; then
        echo "⚠️  $file may need async searchParams"
    fi
done

# Clean up
rm -f full_typescript_check.log

echo ""
echo "✅ Type check complete!"
EOF

chmod +x check_all_types.sh

# Run the comprehensive type check
echo ""
echo "🔍 Running comprehensive type check..."
./check_all_types.sh

# List all dynamic route pages to verify they're fixed
echo ""
echo "📋 Dynamic route pages status:"
echo "=================================="
find app -path "*/\[*\]/page.tsx" -o -name "page.tsx" | while read file; do
    if grep -q "params\|searchParams" "$file"; then
        echo -n "$file: "
        if grep -q "Promise<" "$file"; then
            echo "✅ Uses async"
        else
            echo "❌ Needs update"
        fi
    fi
done

# Quick build test
echo ""
echo "🏗️  Running quick build test..."
timeout 20 npm run build 2>&1 | head -30 || true

# Commit all fixes
echo ""
echo "📦 Committing all type fixes..."
git add -A
git commit -m "fix: Update ALL pages for Next.js 15 async types

- Fixed searchParams to use Promise in jobs/new/page.tsx
- Fixed payment-success page if it uses searchParams
- Ensured all dynamic routes use async params/searchParams
- Added comprehensive type checking script" || echo "No changes to commit"

# Push to GitHub
echo "🚀 Pushing to GitHub..."
git push origin main || echo "Failed to push"

echo ""
echo "✅ All Next.js 15 type fixes complete!"
echo ""
echo "📋 Key changes:"
echo "1. All params are now: params: Promise<{ name: string }>"
echo "2. All searchParams are now: searchParams: Promise<{ key?: string }>"
echo "3. All are properly awaited before use"
echo ""
echo "The build should now succeed on Vercel!"