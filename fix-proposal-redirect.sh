#!/bin/bash

set -e

echo "🔧 Fixing proposal redirect issue..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update page.tsx to handle errors better and not redirect immediately
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

  // Get proposal with all related data
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
        item_type,
        title,
        description,
        quantity,
        unit_price,
        total_price,
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

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile?.role || 'viewer'}
    />
  )
}
EOF

echo "✅ Fixed page.tsx with better error handling"

# Commit and push
git add -A
git commit -m "Fix proposal redirect issue - show errors instead of redirecting

- Remove immediate redirect on error
- Show error details to help debug
- Use notFound() for proper 404 handling
- Keep user on proposal page even if there's an error"

git push origin main

echo "✅ Fix deployed! Proposals should now display properly."
echo "📋 Chat Status: ~80% used, 20% remaining"
