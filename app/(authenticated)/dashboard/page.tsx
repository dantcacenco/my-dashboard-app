import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Check user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only allow admin to view dashboard
  if (!profile || profile.role !== 'admin') {
    // Don't redirect to technician if not admin, redirect to home
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
      .from('recent_activities')
      .select('*')
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

  const dashboardData = {
    revenue: Math.round(revenue),
    activeProposals,
    completedJobs,
    proposals,
    activities
  }

  // Pass as initialData prop
  return <DashboardContent initialData={dashboardData} />
}
