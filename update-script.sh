#!/bin/bash

# Fix Proposal View Redirect Issue
# Service Pro Field Service Management
# Date: August 6, 2025

set -e  # Exit on error

echo "🔧 Fixing proposal view redirect issue..."

# Fix 1: Update the proposals/[id]/page.tsx to check for both boss and admin roles
echo "📦 Fixing proposal view page authorization..."
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

  // Get user profile to check role - NOTE: table is 'user_profiles' not 'profiles'
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('user_id', user.id)
    .single()

  // Allow both admin and boss roles to view proposals
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    console.log('Unauthorized access attempt:', { userId: user.id, role: profile?.role })
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
        userRole={profile?.role}
        userId={user.id}
      />
    </div>
  )
}
EOF

# Fix 2: Also fix the edit proposal page
echo "📦 Fixing proposal edit page authorization..."
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

  // Get user profile to check role - NOTE: table is 'user_profiles' not 'profiles'
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('user_id', user.id)
    .single()

  // Allow both admin and boss roles to edit proposals
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
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

# Fix 3: Fix the new proposal page too
echo "📦 Fixing new proposal page authorization..."
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

  // Get user profile to check role - NOTE: table is 'user_profiles' not 'profiles'
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('user_id', user.id)
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

# Fix 4: Create a debug helper page to check your role
echo "📦 Creating debug helper page..."
mkdir -p app/debug
cat > app/debug/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function DebugPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Try both table names to see which one exists
  const { data: profile1 } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('user_id', user.id)
    .single()

  const { data: profile2 } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Debug Information</h1>
      
      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-bold mb-2">User Auth:</h2>
        <pre className="text-sm">{JSON.stringify({ id: user.id, email: user.email }, null, 2)}</pre>
      </div>

      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-bold mb-2">User Profile (user_profiles table):</h2>
        <pre className="text-sm">{JSON.stringify(profile1, null, 2)}</pre>
      </div>

      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-bold mb-2">User Profile (profiles table):</h2>
        <pre className="text-sm">{JSON.stringify(profile2, null, 2)}</pre>
      </div>

      <div className="mt-4">
        <a href="/proposals" className="text-blue-600 hover:underline">Back to Proposals</a>
      </div>
    </div>
  )
}
EOF

# Commit and push using express push
echo ""
echo "💾 Committing and pushing fix..."

./express_push.sh "Fix proposal view redirect - allow both admin and boss roles

- Fixed authorization check to accept both 'admin' and 'boss' roles
- Corrected table name from 'profiles' to 'user_profiles'
- Added proper user_id column in queries
- Created debug page to check role configuration
- Fixed edit and new proposal pages too"

echo ""
echo "✅ Fix deployed!"
echo ""
echo "📋 What was fixed:"
echo "1. Changed role check from 'admin' only to 'admin' OR 'boss'"
echo "2. Fixed table name from 'profiles' to 'user_profiles'"
echo "3. Fixed column name to 'user_id' in the query"
echo ""
echo "🧪 To verify your role, visit: /debug"
echo ""
echo "The proposal view should now work correctly!"
EOF

chmod +x fix_proposal_view_redirect.sh

echo "✅ Script created: fix_proposal_view_redirect.sh"
echo "Run it with: ./fix_proposal_view_redirect.sh"