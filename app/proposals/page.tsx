import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import ProposalsList from './ProposalsList'

export default async function ProposalsPage() {
  const supabase = await createClient()
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE: 'profiles'
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Allow both admin and boss roles
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/')
  }

  // Get proposals with customer data
  const { data: proposals, error: proposalsError } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone
      )
    `)
    .order('created_at', { ascending: false })

  if (proposalsError) {
    console.error('Error fetching proposals:', proposalsError)
  }

  return (
    <div className="p-6">
      <ProposalsList 
        initialProposals={proposals || []} 
        userRole={profile?.role || 'boss'}
      />
    </div>
  )
}
