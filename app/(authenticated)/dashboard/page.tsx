import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Debug logging
  console.log('Dashboard: User ID:', user.id)
  console.log('Dashboard: Profile:', profile)

  // If no profile exists, create one with admin role for now
  if (!profile) {
    console.log('No profile found, creating admin profile...')
    await supabase
      .from('profiles')
      .insert({
        id: user.id,
        email: user.email,
        role: 'admin'
      })
    
    // Redirect to dashboard again to reload with profile
    redirect('/dashboard')
  }

  // Only allow admin to view dashboard
  if (profile.role !== 'admin') {
    console.log('Not admin, redirecting to home. Role:', profile.role)
    redirect('/')
  }

  // Fetch dashboard data
  const [proposalsResult, activitiesResult] = await Promise.all([
    supabase
      .from('proposals')
      .select(`
        *,
        customers (
          name,
          email
        )
      `)
      .order('created_at', { ascending: false }),
    
    supabase
      .from('proposal_activities')
      .select(`
        *,
        proposals (
          proposal_number,
          title
        )
      `)
      .order('created_at', { ascending: false })
      .limit(10)
  ])

  const proposals = proposalsResult.data || []
  const activities = activitiesResult.data || []

  // Calculate revenue from paid amounts
  const revenue = proposals.reduce((total, proposal) => {
    let proposalRevenue = 0
    
    if (proposal.deposit_paid_at && proposal.deposit_amount) {
      proposalRevenue += Number(proposal.deposit_amount)
    }
    
    if (proposal.progress_paid_at && proposal.progress_payment_amount) {
      proposalRevenue += Number(proposal.progress_payment_amount)
    }
    
    if (proposal.final_paid_at && proposal.final_payment_amount) {
      proposalRevenue += Number(proposal.final_payment_amount)
    }
    
    return total + proposalRevenue
  }, 0)

  const activeProposals = proposals.filter(p => p.status === 'sent' || p.status === 'viewed').length
  const completedJobs = proposals.filter(p => p.status === 'completed').length

  return <DashboardContent 
    revenue={Math.round(revenue)}
    activeProposals={activeProposals}
    completedJobs={completedJobs}
    proposals={proposals}
    activities={activities}
  />
}
