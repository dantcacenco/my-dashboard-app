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
