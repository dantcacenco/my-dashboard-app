import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalView from './ProposalView'

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
        is_selected,
        sort_order
      )
    `)
    .eq('id', id)
    .single()

  if (error || !proposal) {
    console.error('Error fetching proposal:', error)
    redirect('/proposals')
  }

  return (
    <ProposalView 
      proposal={proposal} 
      userRole={profile.role}
    />
  )
}
