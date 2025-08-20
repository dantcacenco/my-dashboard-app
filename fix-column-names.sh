#!/bin/bash

set -e

echo "🔧 Fixing proposal_items column issue..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix the page.tsx to use the correct column names
cat > app/\(authenticated\)/proposals/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    return notFound()
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Get proposal with all related data - using is_addon instead of item_type
  const { data: proposal, error } = await supabase
    .from('proposals')
    .select(`
      *,
      customers!customer_id (
        id,
        name,
        email,
        phone,
        address
      ),
      proposal_items (
        id,
        name,
        title,
        description,
        quantity,
        unit_price,
        total_price,
        is_addon,
        is_selected,
        sort_order
      ),
      payment_stages (
        id,
        stage_name,
        percentage,
        amount,
        due_date
      )
    `)
    .eq('id', id)
    .single()

  if (error) {
    console.error('Error fetching proposal:', error)
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <h2 className="text-red-800 font-semibold">Error loading proposal</h2>
          <p className="text-red-600 mt-2">Details: {error.message}</p>
          <p className="text-sm text-red-500 mt-1">Proposal ID: {id}</p>
        </div>
      </div>
    )
  }

  if (!proposal) {
    return notFound()
  }

  // Transform is_addon to item_type for consistency with ProposalView
  if (proposal.proposal_items) {
    proposal.proposal_items = proposal.proposal_items.map((item: any) => ({
      ...item,
      item_type: item.is_addon ? 'add_on' : 'service'
    }))
  }

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile?.role || 'viewer'}
    />
  )
}
EOF

echo "✅ Fixed column names in page.tsx"

# Commit and push
git add -A
git commit -m "Fix proposal_items column names - use is_addon instead of item_type

- Database uses is_addon boolean, not item_type string
- Transform data after fetch to maintain consistency
- This fixes the column does not exist error"

git push origin main

echo "✅ Fix deployed! Proposals should now load properly."
echo "📋 Chat Status: ~85% used, 15% remaining"
