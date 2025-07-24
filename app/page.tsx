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
      .select('id, status, total, created_at'),

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
      .select('created_at, total, status')
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
  const totalRevenue = proposals.reduce((sum, p) => sum + (p.total || 0), 0)
  const approvedProposals = proposals.filter(p => p.status === 'approved').length
  const paidProposals = proposals.filter(p => p.status === 'paid').length
  
  // Calculate conversion rates
  const conversionRate = totalProposals > 0 ? (approvedProposals / totalProposals) * 100 : 0
  const paymentRate = approvedProposals > 0 ? (paidProposals / approvedProposals) * 100 : 0

  // Monthly revenue data for chart
  const monthlyRevenue = Array.from({ length: 6 }, (_, i) => {
    const date = new Date()
    date.setMonth(date.getMonth() - (5 - i))
    const monthKey = date.toISOString().slice(0, 7) // YYYY-MM format
    
    const monthData = monthlyData.filter(p => 
      p.created_at.startsWith(monthKey)
    )
    
    return {
      month: date.toLocaleDateString('en-US', { month: 'short' }),
      revenue: monthData.reduce((sum, p) => sum + (p.total || 0), 0),
      proposals: monthData.length
    }
  })

  // Status distribution
  const statusCounts = {
    draft: proposals.filter(p => p.status === 'draft').length,
    sent: proposals.filter(p => p.status === 'sent').length,
    viewed: proposals.filter(p => p.status === 'viewed').length,
    approved: proposals.filter(p => p.status === 'approved').length,
    rejected: proposals.filter(p => p.status === 'rejected').length,
    paid: proposals.filter(p => p.status === 'paid').length
  }

  const dashboardData = {
    metrics: {
      totalProposals,
      totalRevenue,
      approvedProposals,
      conversionRate,
      paymentRate
    },
    monthlyRevenue,
    statusCounts,
    recentProposals,
    recentActivities
  }

  return <DashboardContent data={dashboardData} />
}