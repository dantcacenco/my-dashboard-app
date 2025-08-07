import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ViewProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()
  
  console.log('[ViewProposalPage] Starting with proposal ID:', id)
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    console.log('[ViewProposalPage] No user found, redirecting to sign-in')
    redirect('/sign-in')
  }
  
  console.log('[ViewProposalPage] User authenticated:', user.id)

  // Get user profile with error handling
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .maybeSingle()

  console.log('[ViewProposalPage] Profile query result:', { profile, profileError })

  // If no profile found or error, try to handle gracefully
  if (!profile && !profileError) {
    console.log('[ViewProposalPage] No profile found for user')
    // Create a default profile or redirect
    redirect('/')
  }
  
  if (profileError) {
    console.error('[ViewProposalPage] Error fetching profile:', profileError)
    // Check if it's an RLS error
    if (profileError.message?.includes('row-level security')) {
      console.error('[ViewProposalPage] RLS policy blocking profile access')
    }
    redirect('/')
  }

  // Check role authorization
  const userRole = profile?.role
  console.log('[ViewProposalPage] User role:', userRole)
  
  if (userRole !== 'admin' && userRole !== 'boss') {
    console.log('[ViewProposalPage] Unauthorized role, redirecting to dashboard')
    redirect('/')
  }

  console.log('[ViewProposalPage] Authorization passed, fetching proposal')

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
    console.error('[ViewProposalPage] Proposal not found:', proposalError)
    notFound()
  }

  console.log('[ViewProposalPage] Proposal found, rendering view')

  return (
    <div className="min-h-screen bg-gray-50">
      <ProposalView 
        proposal={proposal}
        userRole={userRole}
        userId={user.id}
      />
    </div>
  )
}
