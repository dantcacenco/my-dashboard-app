#!/bin/bash
echo "🔧 Fixing dashboard data structure to match DashboardContent interface..."

# Create the complete fixed page.tsx
cat > app/page.tsx << 'EOF'
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

    // Recent proposals - note: customers is an object, not array
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

    // Recent activities - note: proposals is an object, not array
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
  
  // Calculate total revenue including partial payments
  const totalRevenue = proposals.reduce((sum, p) => {
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
  const monthlyRevenue = []
  const currentDate = new Date()
  
  // Initialize last 6 months
  for (let i = 5; i >= 0; i--) {
    const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1)
    const monthKey = date.toISOString().slice(0, 7) // YYYY-MM format
    const monthName = date.toLocaleDateString('en-US', { month: 'short' })
    
    // Find all proposals and payments in this month
    let monthRevenue = 0
    let monthProposals = 0
    
    monthlyData.forEach(proposal => {
      // Count proposals created in this month
      if (proposal.created_at.startsWith(monthKey)) {
        monthProposals++
      }
      
      // Add deposit payments
      if (proposal.deposit_paid_at && proposal.deposit_paid_at.startsWith(monthKey) && proposal.deposit_amount) {
        monthRevenue += proposal.deposit_amount
      }
      
      // Add progress payments
      if (proposal.progress_paid_at && proposal.progress_paid_at.startsWith(monthKey) && proposal.progress_amount) {
        monthRevenue += proposal.progress_amount
      }
      
      // Add final payments
      if (proposal.final_paid_at && proposal.final_paid_at.startsWith(monthKey) && proposal.final_amount) {
        monthRevenue += proposal.final_amount
      }
      
      // For backward compatibility - if status is 'paid' but no staged payments
      if (proposal.status === 'paid' && proposal.created_at.startsWith(monthKey) && 
          !proposal.deposit_paid_at && !proposal.progress_paid_at && !proposal.final_paid_at) {
        monthRevenue += proposal.total || 0
      }
    })
    
    monthlyRevenue.push({
      month: monthName,
      revenue: monthRevenue,
      proposals: monthProposals
    })
  }

  // Status distribution
  const statusCounts = {
    draft: proposals.filter(p => p.status === 'draft').length,
    sent: proposals.filter(p => p.status === 'sent').length,
    viewed: proposals.filter(p => p.status === 'viewed').length,
    approved: proposals.filter(p => p.status === 'approved').length,
    rejected: proposals.filter(p => p.status === 'rejected').length,
    paid: proposals.filter(p => p.status === 'paid').length
  }

  // Transform recent proposals to match expected format
  const transformedRecentProposals = recentProposals.map(p => ({
    ...p,
    customers: p.customers ? [p.customers] : null // Convert object to array
  }))

  // Transform recent activities to match expected format
  const transformedRecentActivities = recentActivities.map(a => ({
    ...a,
    proposals: a.proposals ? [a.proposals] : null // Convert object to array
  }))

  const dashboardData = {
    metrics: {
      totalProposals,
      totalRevenue, // Changed from paidRevenue
      approvedProposals,
      conversionRate,
      paymentRate
    },
    monthlyRevenue,
    statusCounts,
    recentProposals: transformedRecentProposals,
    recentActivities: transformedRecentActivities
  }

  return <DashboardContent data={dashboardData} />
}
EOF

# Check for errors
if [ $? -ne 0 ]; then
    echo "❌ Error writing file"
    exit 1
fi

# Commit and push
git add .
git commit -m "fix: correct dashboard data structure to match DashboardContent interface"
git push origin main

echo "✅ Fixed! Dashboard data structure now matches expected interface"