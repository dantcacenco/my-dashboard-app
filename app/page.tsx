import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from './DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()

  // Check authentication
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  
  if (userError || !user) {
    redirect('/auth/signin')
  }

  // Fetch dashboard data
  const [
    proposalsResult,
    recentProposalsResult,
    monthlyStatsResult,
    recentActivitiesResult
  ] = await Promise.all([
    // All proposals for stats
    supabase
      .from('proposals')
      .select('id, status, total, created_at, deposit_amount, progress_amount, final_amount, deposit_paid_at, progress_paid_at, final_paid_at'),

    // Recent proposals
    supabase
      .from('proposals')
      .select(`
        id,
        proposal_number,
        title,
        total,
        status,
        created_at,
        customers (name, email)
      `)
      .order('created_at', { ascending: false })
      .limit(5),

    // Monthly stats (last 6 months)
    supabase
      .from('proposals')
      .select('created_at, total, status, deposit_amount, progress_amount, final_amount, deposit_paid_at, progress_paid_at, final_paid_at')
      .gte('created_at', new Date(Date.now() - 6 * 30 * 24 * 60 * 60 * 1000).toISOString()),

    // Recent activities
    supabase
      .from('proposal_activities')
      .select(`
        id,
        activity_type,
        description,
        created_at,
        proposals (proposal_number, title)
      `)
      .order('created_at', { ascending: false })
      .limit(10)
  ])

  const proposals = proposalsResult.data || []
  const recentProposals = recentProposalsResult.data || []
  const monthlyData = monthlyStatsResult.data || []
  const recentActivities = recentActivitiesResult.data || []

  // Calculate key metrics
  const totalProposals = proposals.length
  
  // Calculate paid revenue including partial payments
  const paidRevenue = proposals.reduce((sum, p) => {
    let proposalRevenue = 0
    if (p.deposit_paid_at && p.deposit_amount) proposalRevenue += p.deposit_amount
    if (p.progress_paid_at && p.progress_amount) proposalRevenue += p.progress_amount
    if (p.final_paid_at && p.final_amount) proposalRevenue += p.final_amount
    // If no staged payments, check if it's fully paid
    if (proposalRevenue === 0 && p.status === 'paid') proposalRevenue = p.total || 0
    return sum + proposalRevenue
  }, 0)
  
  const approvedProposals = proposals.filter(p => p.status === 'approved').length
  const paidProposals = proposals.filter(p => {
    // Count as paid if any payment has been made
    return p.status === 'paid' || p.deposit_paid_at || p.progress_paid_at || p.final_paid_at
  }).length
  
  // Calculate conversion rates
  const conversionRate = totalProposals > 0 ? (approvedProposals / totalProposals) * 100 : 0
  const paymentRate = approvedProposals > 0 ? (paidProposals / approvedProposals) * 100 : 0

  // Process monthly data for charts
  const monthlyRevenue = new Map()
  const currentDate = new Date()
  
  // Initialize last 6 months
  for (let i = 5; i >= 0; i--) {
    const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1)
    const key = date.toISOString().slice(0, 7) // YYYY-MM format
    monthlyRevenue.set(key, 0)
  }

  // Add revenue from all payments
  monthlyData.forEach(proposal => {
    // Add deposit payments
    if (proposal.deposit_paid_at && proposal.deposit_amount) {
      const month = proposal.deposit_paid_at.slice(0, 7)
      if (monthlyRevenue.has(month)) {
        monthlyRevenue.set(month, monthlyRevenue.get(month) + proposal.deposit_amount)
      }
    }
    
    // Add progress payments
    if (proposal.progress_paid_at && proposal.progress_amount) {
      const month = proposal.progress_paid_at.slice(0, 7)
      if (monthlyRevenue.has(month)) {
        monthlyRevenue.set(month, monthlyRevenue.get(month) + proposal.progress_amount)
      }
    }
    
    // Add final payments
    if (proposal.final_paid_at && proposal.final_amount) {
      const month = proposal.final_paid_at.slice(0, 7)
      if (monthlyRevenue.has(month)) {
        monthlyRevenue.set(month, monthlyRevenue.get(month) + proposal.final_amount)
      }
    }
    
    // For backward compatibility - if status is 'paid' but no staged payments
    if (proposal.status === 'paid' && !proposal.deposit_paid_at && !proposal.progress_paid_at && !proposal.final_paid_at) {
      const month = proposal.created_at.slice(0, 7)
      if (monthlyRevenue.has(month)) {
        monthlyRevenue.set(month, monthlyRevenue.get(month) + (proposal.total || 0))
      }
    }
  })

  const revenueData = Array.from(monthlyRevenue.entries()).map(([month, revenue]) => ({
    month,
    revenue
  }))

  // Status distribution
  const statusCounts = proposals.reduce((acc: Record<string, number>, proposal) => {
    acc[proposal.status] = (acc[proposal.status] || 0) + 1
    return acc
  }, {})

  const dashboardData = {
    totalProposals,
    paidRevenue,
    approvedProposals,
    conversionRate,
    paymentRate,
    recentProposals,
    recentActivities,
    revenueData,
    statusCounts
  }

  return <DashboardContent data={dashboardData} />
}
