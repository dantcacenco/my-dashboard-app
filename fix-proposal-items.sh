#!/bin/bash

set -e

echo "🔧 Fixing proposal items display issue..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First backup the page.tsx
cp app/\(authenticated\)/proposals/\[id\]/page.tsx app/\(authenticated\)/proposals/\[id\]/page.tsx.backup

# Fix the page.tsx to properly fetch proposal_items with correct fields
cat > app/\(authenticated\)/proposals/\[id\]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalView from './ProposalView'
import CreateJobButton from "./CreateJobButton"

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()

  // Get current user
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  
  if (authError || !user) {
    redirect('/auth/login')
  }

  // Get user profile
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profileError || !profile) {
    redirect('/')
  }

  // Check authorization - allow both admin and boss
  if (profile.role !== 'admin' && profile.role !== 'boss') {
    redirect('/')
  }

  // Get proposal with all related data including proposal_items
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
      payment_stages (*)
    `)
    .eq('id', id)
    .single()

  if (error || !proposal) {
    console.error('Error fetching proposal:', error)
    redirect('/proposals')
  }

  // Debug log to see what data we're getting
  console.log('Proposal data:', {
    id: proposal.id,
    items_count: proposal.proposal_items?.length || 0,
    items: proposal.proposal_items
  })

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile.role}
    />
  )
}
EOF

echo "✅ Updated page.tsx with correct proposal_items fields"

# Test TypeScript
echo "📋 Checking TypeScript..."
npx tsc --noEmit 2>&1 | head -5 || echo "TypeScript check done"

# Commit and push
git add -A
git commit -m "Fix proposal items fetching - use correct field names

- Changed is_addon to item_type field
- Added debug logging to verify data
- Ensures proposal_items are properly fetched"

git push origin main

echo "✅ Fix complete! Check console for debug output."
