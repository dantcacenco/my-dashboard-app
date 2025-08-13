import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/auth/login')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only allow boss/admin to view dashboard
  if (profile?.role !== 'admin' && profile?.role !== 'boss') {
    redirect('/technician')
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

  // Calculate metrics
  const totalProposals = proposals.length
  const approvedProposals = proposals.filter(p => p.status === 'approved').length
  const conversionRate = totalProposals > 0 ? (approvedProposals / totalProposals) * 100 : 0
  
  // Calculate revenue from paid amounts
  const totalRevenue = proposals.reduce((sum, p) => {
    const depositPaid = p.deposit_paid_at ? (p.deposit_amount || 0) : 0
    const progressPaid = p.progress_paid_at ? (p.progress_payment_amount || 0) : 0
    const finalPaid = p.final_paid_at ? (p.final_payment_amount || 0) : 0
    return sum + depositPaid + progressPaid + finalPaid
  }, 0)

  const paidProposals = proposals.filter(p => 
    p.deposit_paid_at || p.progress_paid_at || p.final_paid_at
  ).length
  const paymentRate = approvedProposals > 0 ? (paidProposals / approvedProposals) * 100 : 0

  // Calculate monthly revenue
  const monthlyRevenue = []
  const now = new Date()
  for (let i = 5; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const month = date.toLocaleString('default', { month: 'short' })
    const monthProposals = proposals.filter(p => {
      const created = new Date(p.created_at)
      return created.getMonth() === date.getMonth() && 
             created.getFullYear() === date.getFullYear()
    })
    
    const revenue = monthProposals.reduce((sum, p) => {
      const depositPaid = p.deposit_paid_at ? (p.deposit_amount || 0) : 0
      const progressPaid = p.progress_paid_at ? (p.progress_payment_amount || 0) : 0
      const finalPaid = p.final_paid_at ? (p.final_payment_amount || 0) : 0
      return sum + depositPaid + progressPaid + finalPaid
    }, 0)
    
    monthlyRevenue.push({ month, revenue, proposals: monthProposals.length })
  }

  // Count by status
  const statusCounts = {
    draft: proposals.filter(p => p.status === 'draft').length,
    sent: proposals.filter(p => p.status === 'sent').length,
    viewed: proposals.filter(p => p.status === 'viewed').length,
    approved: proposals.filter(p => p.status === 'approved').length,
    rejected: proposals.filter(p => p.status === 'rejected').length,
    paid: proposals.filter(p => p.deposit_paid_at || p.progress_paid_at || p.final_paid_at).length,
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
    recentProposals: proposals.slice(0, 5),
    recentActivities: activities
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-gray-600">Welcome back!</p>
      </div>
      
      <DashboardContent data={dashboardData} />
    </div>
  )
}
