import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalEditForm from './ProposalEditForm'

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

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss/admin can edit proposals
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/unauthorized')
  }

  // Get proposal data
  const { data: proposal } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (*),
      proposal_items (*)
    `)
    .eq('id', id)
    .single()

  if (!proposal) {
    redirect('/proposals')
  }

  // Get customers and pricing items for the form
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
        <ProposalEditForm 
          proposal={proposal}
          customers={customersResult.data || []}
          pricingItems={pricingResult.data || []}
          userId={user.id}
        />
      </div>
    </div>
  )
}
