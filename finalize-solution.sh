#!/bin/bash

set -e

echo "🔧 Finalizing the working solution..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Keep the working solution but remove excessive debug output
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

  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return notFound()

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Get basic proposal first
  const { data: proposal, error: proposalError } = await supabase
    .from('proposals')
    .select('*')
    .eq('id', id)
    .single()

  if (proposalError || !proposal) {
    console.error('Error fetching proposal:', proposalError)
    return notFound()
  }

  // Get items separately (this works reliably)
  const { data: items } = await supabase
    .from('proposal_items')
    .select('*')
    .eq('proposal_id', id)
    .order('sort_order')

  // Get customer if exists
  let customer = null
  if (proposal.customer_id) {
    const { data: customerData } = await supabase
      .from('customers')
      .select('*')
      .eq('id', proposal.customer_id)
      .single()
    customer = customerData
  }

  // Get payment stages
  const { data: paymentStages } = await supabase
    .from('payment_stages')
    .select('*')
    .eq('proposal_id', id)
    .order('sort_order')

  // Combine everything with data transformation
  const fullProposal = {
    ...proposal,
    customers: customer,
    payment_stages: paymentStages || [],
    proposal_items: items?.map(item => ({
      ...item,
      title: item.name, // Map name to title for display
      item_type: item.is_addon ? 'add_on' : 'service' // Create item_type
    })) || []
  }

  return <ProposalView proposal={fullProposal} userRole={profile?.role || 'viewer'} />
}
EOF

echo "✅ Finalized working page.tsx"

# Clean up old files
rm -f comprehensive-debug.sh check-schema.sql

git add -A
git commit -m "Finalize working proposal display solution

- Using separate queries that work reliably
- Removed debug clutter
- Kept data transformation for compatibility
- Items now display with proper formatting"

git push origin main

echo "✅ WORKING SOLUTION DEPLOYED!"
echo ""
echo "📊 Summary:"
echo "• Proposals load and display correctly"
echo "• Services show in gray boxes"
echo "• Add-ons show in orange boxes with badges"
echo "• Totals calculate properly"
echo ""
echo "📋 Chat Status: ~95% used, 5% remaining"
echo ""
echo "Note: You have duplicate add-on items in that proposal"
echo "(4x Refrigerant R-410A) - might want to check the edit flow"
