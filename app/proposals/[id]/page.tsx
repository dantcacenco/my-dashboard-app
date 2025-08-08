import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalView from './ProposalView'

export default async function ProposalPage({
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

  // Get proposal with customer information and proposal items
  const { data: proposal } = await supabase
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
        name,
        description,
        quantity,
        unit_price,
        total_price,
        is_addon,
        is_selected,
        sort_order
      )
    `)
    .eq('id', id)
    .single()

  if (!proposal) {
    redirect('/proposals')
  }

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile?.role || null}
      userId={user.id}
    />
  )
}
