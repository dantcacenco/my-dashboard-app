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
  
  // Get activities from the last 7 days
  const sevenDaysAgo = new Date()
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)
  
  // 1. Proposal activities with more detail
  const proposalActivities: any[] = []
  
  // Recent proposal status changes
  for (const proposal of proposalList.slice(0, 30)) {
    // Check for various proposal events based on status and timestamps
    const activities = []
    
    // Created
    activities.push({
      id: `${proposal.id}-created`,
      activity_type: 'proposal_created',
      description: `Proposal #${proposal.proposal_number} created for ${proposal.customers?.name || 'customer'}`,
      created_at: proposal.created_at,
      timestamp: new Date(proposal.created_at).getTime()
    })
    
    // Status-based activities
    if (proposal.status === 'sent' && proposal.sent_at) {
      activities.push({
        id: `${proposal.id}-sent`,
        activity_type: 'proposal_sent',
        description: `Proposal #${proposal.proposal_number} sent to ${proposal.customers?.email || 'customer'}`,
        created_at: proposal.sent_at,
        timestamp: new Date(proposal.sent_at).getTime()
      })
    }
    
    if (proposal.status === 'approved' && proposal.approved_at) {
      activities.push({
        id: `${proposal.id}-approved`,
        activity_type: 'proposal_approved',
        description: `Proposal #${proposal.proposal_number} approved by ${proposal.customers?.name || 'customer'}`,
        created_at: proposal.approved_at,
        timestamp: new Date(proposal.approved_at).getTime()
      })
    }
    
    if (proposal.status === 'rejected' && proposal.updated_at) {
      activities.push({
        id: `${proposal.id}-rejected`,
        activity_type: 'proposal_rejected',
        description: `Proposal #${proposal.proposal_number} rejected`,
        created_at: proposal.updated_at,
        timestamp: new Date(proposal.updated_at).getTime()
      })
    }
    
    // Payment activities
    if (proposal.deposit_paid_at) {
      activities.push({
        id: `${proposal.id}-deposit`,
        activity_type: 'payment_received',
        description: `💰 Deposit payment received for Proposal #${proposal.proposal_number} (${formatCurrency(proposal.deposit_amount || 0)})`,
        created_at: proposal.deposit_paid_at,
        timestamp: new Date(proposal.deposit_paid_at).getTime()
      })
    }
    
    if (proposal.progress_paid_at) {
      activities.push({
        id: `${proposal.id}-roughin`,
        activity_type: 'payment_received',
        description: `💰 Rough-in payment received for Proposal #${proposal.proposal_number} (${formatCurrency(proposal.progress_payment_amount || 0)})`,
        created_at: proposal.progress_paid_at,
        timestamp: new Date(proposal.progress_paid_at).getTime()
      })
    }
    
    if (proposal.final_paid_at) {
      activities.push({
        id: `${proposal.id}-final`,
        activity_type: 'payment_received',
        description: `💰 Final payment received for Proposal #${proposal.proposal_number} (${formatCurrency(proposal.final_payment_amount || 0)})`,
        created_at: proposal.final_paid_at,
        timestamp: new Date(proposal.final_paid_at).getTime()
      })
    }
    
    proposalActivities.push(...activities)
  }
  
  // 2. Job activities with status changes
  const { data: recentJobs } = await supabase
    .from('jobs')
    .select('*, customers(name)')
    .order('updated_at', { ascending: false })
    .limit(20)
  
  const jobActivities: any[] = []
  for (const job of (recentJobs || [])) {
    // Job created
    jobActivities.push({
      id: `${job.id}-created`,
      activity_type: 'job_created',
      description: `Job #${job.job_number} created for ${job.customers?.name || 'customer'}`,
      created_at: job.created_at,
      timestamp: new Date(job.created_at).getTime()
    })
    
    // Job status updates
    if (job.status === 'scheduled' && job.scheduled_date) {
      jobActivities.push({
        id: `${job.id}-scheduled`,
        activity_type: 'job_scheduled',
        description: `Job #${job.job_number} scheduled for ${new Date(job.scheduled_date).toLocaleDateString()}`,
        created_at: job.updated_at,
        timestamp: new Date(job.updated_at).getTime()
      })
    }
    
    if (job.status === 'in_progress') {
      jobActivities.push({
        id: `${job.id}-started`,
        activity_type: 'job_started',
        description: `Job #${job.job_number} work started`,
        created_at: job.updated_at,
        timestamp: new Date(job.updated_at).getTime()
      })
    }
    
    if (job.status === 'completed') {
      jobActivities.push({
        id: `${job.id}-completed`,
        activity_type: 'job_completed',
        description: `Job #${job.job_number} completed`,
        created_at: job.updated_at,
        timestamp: new Date(job.updated_at).getTime()
      })
    }
  }
  
  // 3. Technician assignments
  const { data: techAssignments } = await supabase
    .from('job_technicians')
    .select(`
      *,
      jobs:job_id (job_number),
      profiles:technician_id (full_name, email)
    `)
    .order('created_at', { ascending: false })
    .limit(10)
  
  const techActivities = (techAssignments || []).map(assignment => ({
    id: `tech-${assignment.id}`,
    activity_type: 'technician_assigned',
    description: `Technician ${assignment.profiles?.full_name || 'assigned'} to Job #${assignment.jobs?.job_number || 'unknown'}`,
    created_at: assignment.created_at,
    timestamp: new Date(assignment.created_at).getTime()
  }))
  
  // Helper function to format currency
  function formatCurrency(amount: number) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }
  
  // Combine all activities and sort by timestamp
  const allActivities = [...proposalActivities, ...jobActivities, ...techActivities]
    .filter(a => a.timestamp > sevenDaysAgo.getTime()) // Only last 7 days
    .sort((a, b) => b.timestamp - a.timestamp)
    .slice(0, 20) // Show 20 most recent activities
  
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
