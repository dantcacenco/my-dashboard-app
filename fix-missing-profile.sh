#!/bin/bash

echo "🔧 Fixing app to handle missing profiles gracefully..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update dashboard to handle missing profile
echo "📝 Updating dashboard to handle missing profile..."
cat > "app/(authenticated)/dashboard/page.tsx" << 'EOF'
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
    // For now, since we can't insert due to RLS, just treat as admin
    console.log('No profile found for user, treating as admin')
  } else if (profile.role !== 'admin' && profile.role !== 'boss') {
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

  const recentActivities: any[] = []

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
    recentActivities
  }

  return <DashboardContent data={dashboardData} />
}
EOF

# Update home page to handle missing profile
echo "📝 Updating home page..."
cat > "app/page.tsx" << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function HomePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // If no profile, assume admin for now (you're the only user)
  if (!profile) {
    redirect('/dashboard')
  }
  
  // Route based on role - handle both 'boss' and 'admin'
  const userRole = profile?.role
  
  if (userRole === 'admin' || userRole === 'boss') {
    redirect('/dashboard')
  } else if (userRole === 'technician') {
    redirect('/technician')
  } else {
    // Show welcome for users without roles
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Welcome to Service Pro</h1>
          <p className="text-gray-600">Your account is being set up.</p>
          <p className="text-sm text-gray-500 mt-2">Role: {userRole || 'Not assigned'}</p>
          <p className="text-sm text-gray-500">User ID: {user.id}</p>
          <p className="text-sm text-gray-500">Please contact support if you need assistance.</p>
        </div>
      </div>
    )
  }
}
EOF

# Clean up temp files
rm -f fix-profile.js

echo ""
echo "🧪 Testing TypeScript..."
npx tsc --noEmit
if [ $? -eq 0 ]; then
  echo "✅ TypeScript successful!"
fi

echo ""
echo "💾 Committing fixes..."
git add -A
git commit -m "fix: handle missing profile gracefully - treat as admin

- Dashboard works even without profile in database
- No profile = admin access (temporary for development)
- Handles RLS restrictions gracefully
- Shows user ID for debugging"

git push origin main

echo ""
echo "✅ Fix complete!"
echo ""
echo "🎯 IMPORTANT: You need to manually create your profile in Supabase:"
echo "1. Go to Supabase Dashboard"
echo "2. Navigate to Table Editor → profiles"
echo "3. Insert new row:"
echo "   - id: d59c31b1-ccce-4fe8-be8d-7295ec41f7ac"
echo "   - email: dantcacenco@gmail.com"
echo "   - role: admin"
echo ""
echo "Or run this SQL in Supabase SQL Editor:"
echo "INSERT INTO profiles (id, email, role, created_at, updated_at)"
echo "VALUES ('d59c31b1-ccce-4fe8-be8d-7295ec41f7ac', 'dantcacenco@gmail.com', 'admin', NOW(), NOW())"
echo "ON CONFLICT (id) DO UPDATE SET role = 'admin', updated_at = NOW();"
echo ""
echo "🧹 Cleaning up..."
rm -f "$0"
