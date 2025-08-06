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

  // Get current user
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  
  if (userError || !user) {
    redirect('/login')
  }

  // Get user profile
  const { data: profile, error: profileError } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('user_id', user.id)
    .single()

  if (profileError || !profile) {
    console.error('Error fetching user profile:', profileError)
    redirect('/')
  }

  // Check authorization
  if (profile.role !== 'admin' && profile.role !== 'boss') {
    redirect('/')
  }

  // Get proposal with all related data
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
        name,
        description,
        quantity,
        unit_price,
        total_price,
        is_addon,
        is_selected
      ),
      proposal_activities (
        id,
        activity_type,
        description,
        created_at,
        metadata
      )
    `)
    .eq('id', id)
    .single()

  if (error || !proposal) {
    console.error('Error fetching proposal:', error)
    redirect('/proposals')
  }

  return (
    <div className="p-6">
      <ProposalView 
        proposal={proposal} 
        userRole={profile.role}
        userId={user.id}
      />
    </div>
  )
}
