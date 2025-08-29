import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardContent from '@/app/DashboardContent'

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Check user role - handle missing profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // If no profile exists, create a default admin profile for this user
  if (!profile) {
    console.log('No profile found for user, treating as admin')
  } else if (profile.role !== 'boss' && profile.role !== 'admin') {
    // Not an admin or boss
    redirect('/')
  }

  // Fetch proposals with customer data (continue even without profile)
  const { data: proposals } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        name,
        email
      )
    `)
    .order('created_at', { ascending: false })

  const proposalList = proposals || []

  // Fetch jobs for the calendar
  const today = new Date()
  const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
  const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0)
  
  const { data: jobs } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (name, address),
      proposals:proposal_id (
        id,
        status,
        total,
        deposit_amount,
        progress_payment_amount,
        final_payment_amount,
        deposit_paid_at,
        progress_paid_at,
        final_paid_at
      )
    `)
    .gte('scheduled_date', startOfMonth.toISOString())
    .lte('scheduled_date', endOfMonth.toISOString())
    .order('scheduled_date', { ascending: true })

  // Count today's jobs
  const todayStr = today.toISOString().split('T')[0]
  const todaysJobsCount = jobs?.filter(j => 
    j.scheduled_date && j.scheduled_date.split('T')[0] === todayStr
  ).length || 0

  // Calculate metrics
  const totalRevenue = proposalList.reduce((total, proposal) => {
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

  const approvedProposals = proposalList.filter(p => 
    p.status === 'approved' || p.status === 'accepted'
  ).length
  
  const paidProposals = proposalList.filter(p => 
    p.deposit_paid_at || p.progress_paid_at || p.final_paid_at
  ).length
  
  const conversionRate = proposalList.length > 0 
    ? (approvedProposals / proposalList.length) * 100 
    : 0
    
  const paymentRate = approvedProposals > 0 
    ? (paidProposals / approvedProposals) * 100 
    : 0

  // Calculate status counts
  const statusCounts = {
    draft: proposalList.filter(p => p.status === 'draft').length,
    sent: proposalList.filter(p => p.status === 'sent').length,
    viewed: proposalList.filter(p => p.status === 'viewed').length,
    approved: proposalList.filter(p => p.status === 'approved' || p.status === 'accepted').length,
    rejected: proposalList.filter(p => p.status === 'rejected').length,
    paid: paidProposals
  }

  // Calculate monthly revenue
  const monthlyRevenue = []
  const now = new Date()
  for (let i = 5; i >= 0; i--) {
    const date = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const monthStr = date.toLocaleDateString('en-US', { month: 'short' })
    
    const monthProposals = proposalList.filter(p => {
      const created = new Date(p.created_at)
      return created.getMonth() === date.getMonth() && 
             created.getFullYear() === date.getFullYear()
    })
    
    const revenue = monthProposals.reduce((total, proposal) => {
      let rev = 0
      if (proposal.deposit_paid_at) rev += Number(proposal.deposit_amount || 0)
      if (proposal.progress_paid_at) rev += Number(proposal.progress_payment_amount || 0)
      if (proposal.final_paid_at) rev += Number(proposal.final_payment_amount || 0)
      return total + rev
    }, 0)
    
    monthlyRevenue.push({
      month: monthStr,
      revenue: Math.round(revenue),
      proposals: monthProposals.length
    })
  }

  // Format recent proposals
  const recentProposals = proposalList.slice(0, 10).map(p => ({
    id: p.id,
    proposal_number: p.proposal_number,
    title: p.title || `Proposal #${p.proposal_number}`,
    total: p.total || 0,
    status: p.status,
    created_at: p.created_at,
    customers: p.customers ? [p.customers] : null
  }))

  // Fetch recent activities from multiple sources
  const recentActivities: any[] = []
  
  // Get recent proposal activities (created, approved, rejected)
  const recentProposalEvents = proposalList.slice(0, 20).map(p => {
    let activity_type = 'proposal_created'
    let description = `Proposal #${p.proposal_number} created`
    
    if (p.status === 'approved') {
      activity_type = 'proposal_approved'
      description = `Proposal #${p.proposal_number} approved by ${p.customers?.name || 'customer'}`
    } else if (p.status === 'rejected') {
      activity_type = 'proposal_rejected'
      description = `Proposal #${p.proposal_number} rejected`
    } else if (p.status === 'sent') {
      activity_type = 'proposal_sent'
      description = `Proposal #${p.proposal_number} sent to ${p.customers?.name || 'customer'}`
    } else if (p.status === 'deposit paid') {
      activity_type = 'payment_received'
      description = `Deposit payment received for #${p.proposal_number}`
    } else if (p.status === 'rough-in paid') {
      activity_type = 'payment_received'
      description = `Rough-in payment received for #${p.proposal_number}`
    } else if (p.status === 'completed') {
      activity_type = 'payment_received'
      description = `Final payment received for #${p.proposal_number}`
    }
    
    return {
      id: p.id,
      activity_type,
      description,
      created_at: p.created_at,
      proposals: [{
        proposal_number: p.proposal_number,
        title: p.title || `Proposal #${p.proposal_number}`
      }]
    }
  })

  // Get recent job activities
  const { data: recentJobs } = await supabase
    .from('jobs')
    .select('*, customers(name)')
    .order('created_at', { ascending: false })
    .limit(10)
  
  const jobActivities = (recentJobs || []).map(job => ({
    id: job.id,
    activity_type: 'job_created',
    description: `Job #${job.job_number} created for ${job.customers?.name || 'customer'}`,
    created_at: job.created_at,
    proposals: null
  }))

  // Combine and sort all activities by date
  const allActivities = [...recentProposalEvents, ...jobActivities]
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 15) // Show 15 most recent activities

  recentActivities.push(...allActivities)

  const dashboardData = {
    metrics: {
      totalProposals: proposalList.length,
      totalRevenue: Math.round(totalRevenue),
      approvedProposals,
      conversionRate: Math.round(conversionRate),
      paymentRate: Math.round(paymentRate)
    },
    monthlyRevenue,
    statusCounts,
    recentProposals,
    recentActivities,
    todaysJobsCount,
    monthlyJobs: jobs || []
  }

  return <DashboardContent data={dashboardData} />
}
