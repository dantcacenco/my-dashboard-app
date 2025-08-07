#!/bin/bash

# Fix Proposal Pages with CORRECT Table Name
# Service Pro Field Service Management
# Date: August 6, 2025

set -e  # Exit on error

echo "🔧 Fixing proposal pages with correct table name (profiles)..."

# Fix 1: Correct the proposals/[id]/page.tsx 
echo "📦 Fixing proposal VIEW page..."
cat > app/proposals/[id]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ViewProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE: 'profiles' with 'id' column
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  console.log('User profile check:', { userId: user.id, role: profile?.role })

  // Allow both admin and boss roles to view proposals
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    console.log('Unauthorized: redirecting to dashboard')
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
    console.error('Proposal not found:', proposalError)
    notFound()
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <ProposalView 
        proposal={proposal}
        userRole={profile?.role || 'boss'}
        userId={user.id}
      />
    </div>
  )
}
EOF

# Fix 2: Correct the edit proposal page
echo "📦 Fixing proposal EDIT page..."
cat > app/proposals/[id]/edit/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import ProposalEditor from './ProposalEditor'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function EditProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE: 'profiles' with 'id' column
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  console.log('Edit page - User profile:', { userId: user.id, role: profile?.role })

  // Allow both admin and boss roles to edit proposals
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    console.log('Edit page - Unauthorized: redirecting to dashboard')
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

# Fix 3: Correct the new proposal page
echo "📦 Fixing NEW proposal page..."
cat > app/proposals/new/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalBuilder from './ProposalBuilder'

export default async function NewProposalPage() {
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE: 'profiles' with 'id' column
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Allow both admin and boss roles to create proposals
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Get customers and pricing items
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
          <h1 className="text-3xl font-bold text-gray-900">Create New Proposal</h1>
          <p className="mt-2 text-gray-600">Build a professional proposal for your customer</p>
        </div>
        
        <ProposalBuilder 
          customers={customersResult.data || []}
          pricingItems={pricingResult.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
EOF

# Fix 4: Also update all other pages that might be checking roles
echo "📦 Fixing proposals list page..."
cat > app/proposals/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalsList from './ProposalsList'

export default async function ProposalsPage() {
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE: 'profiles'
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Allow both admin and boss roles
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Get proposals with customer data
  const { data: proposals, error: proposalsError } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone
      )
    `)
    .order('created_at', { ascending: false })

  if (proposalsError) {
    console.error('Error fetching proposals:', proposalsError)
  }

  return (
    <div className="p-6">
      <ProposalsList 
        initialProposals={proposals || []} 
        userRole={profile?.role || 'boss'}
      />
    </div>
  )
}
EOF

# Fix customers page too
echo "📦 Fixing customers page..."
cat > app/customers/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function CustomersPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Customers</h1>
      <p className="text-gray-600">Customer management coming soon...</p>
    </div>
  )
}
EOF

# Fix jobs page
echo "📦 Fixing jobs page..."
cat > app/jobs/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin' && profile?.role !== 'boss' && profile?.role !== 'tech') {
    redirect('/')
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Jobs</h1>
      <p className="text-gray-600">Job management coming soon...</p>
    </div>
  )
}
EOF

# Fix invoices page
echo "📦 Fixing invoices page..."
cat > app/invoices/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function InvoicesPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Invoices</h1>
      <p className="text-gray-600">Invoice management coming soon...</p>
    </div>
  )
}
EOF

# Commit and push
echo ""
echo "💾 Pushing the fix..."

./express_push.sh "Fix table name to 'profiles' (not 'user_profiles')

- Corrected ALL pages to use 'profiles' table
- Fixed column name to 'id' (not 'user_id')
- Added console logging for debugging
- Both VIEW and EDIT buttons should now work correctly
- Fixed all protected pages (proposals, customers, jobs, invoices)"

echo ""
echo "✅ Fix deployed!"
echo ""
echo "🎯 What was fixed:"
echo "1. Changed table from 'user_profiles' to 'profiles'"
echo "2. Changed column from 'user_id' to 'id'"
echo "3. Added debugging logs to track authorization"
echo ""
echo "The VIEW and EDIT buttons should now work correctly!"
echo ""
echo "If you still have issues, check the Vercel logs for the console output."
EOF

chmod +x fix_correct_table_name.sh

echo "✅ Script created: fix_correct_table_name.sh"
echo "Run it with: ./fix_correct_table_name.sh"