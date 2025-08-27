#!/bin/bash

echo "Fixing calendar job count and display issues, plus job title from proposals..."

# Fix the dashboard to correctly count today's jobs
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/dashboard/page.tsx << 'EOF'
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

  if (!profile) {
    console.log('No profile found for user, treating as admin')
  } else if (profile.role !== 'boss' && profile.role !== 'admin') {
    redirect('/')
  }

  // Fetch proposals with customer data
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

  // Fetch ALL jobs for the calendar (not just this month)
  const { data: allJobs } = await supabase
    .from('jobs')
    .select(`
      *,
      customers (name, address)
    `)
    .order('scheduled_date', { ascending: true })

  // Count today's jobs correctly
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const todayStr = today.toISOString().split('T')[0]
  
  const todaysJobsCount = allJobs?.filter(j => {
    if (!j.scheduled_date) return false
    const jobDateStr = j.scheduled_date.split('T')[0]
    return jobDateStr === todayStr
  }).length || 0

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
    recentActivities,
    todaysJobsCount,
    allJobs: allJobs || []
  }

  return <DashboardContent data={dashboardData} />
}
EOF

echo "Dashboard page updated to correctly count today's jobs!"

# Update DashboardContent to pass all jobs to calendar
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/DashboardContent.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, BarChart, Bar } from 'recharts'
import CalendarView from '@/components/CalendarView'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface DashboardData {
  metrics: {
    totalProposals: number
    totalRevenue: number
    approvedProposals: number
    conversionRate: number
    paymentRate: number
  }
  monthlyRevenue: Array<{
    month: string
    revenue: number
    proposals: number
  }>
  statusCounts: {
    draft: number
    sent: number
    viewed: number
    approved: number
    rejected: number
    paid: number
  }
  recentProposals: Array<{
    id: string
    proposal_number: string
    title: string
    total: number
    status: string
    created_at: string
    customers: Array<{ name: string; email: string }> | null
  }>
  recentActivities: Array<{
    id: string
    activity_type: string
    description: string
    created_at: string
    proposals: Array<{ proposal_number: string; title: string }> | null
  }>
  todaysJobsCount?: number
  allJobs?: any[]
}

interface DashboardContentProps {
  data: DashboardData
}

export default function DashboardContent({ data }: DashboardContentProps) {
  const [calendarExpanded, setCalendarExpanded] = useState(false)
  const { metrics, monthlyRevenue, statusCounts, recentProposals, recentActivities, todaysJobsCount = 0, allJobs = [] } = data

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getStatusColor = (status: string) => {
    const colors = {
      draft: 'bg-gray-100 text-gray-800',
      sent: 'bg-blue-100 text-blue-800',
      viewed: 'bg-purple-100 text-purple-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      paid: 'bg-emerald-100 text-emerald-800'
    }
    return colors[status as keyof typeof colors] || 'bg-gray-100 text-gray-800'
  }

  const getActivityIcon = (activityType: string) => {
    switch (activityType) {
      case 'created':
        return '➕'
      case 'sent':
        return '📧'
      case 'viewed':
        return '👁️'
      case 'approved':
        return '✅'
      case 'rejected':
        return '❌'
      case 'payment_received':
        return '💰'
      default:
        return '📝'
    }
  }

  const statusData = Object.entries(statusCounts).map(([key, value]) => ({
    name: key.charAt(0).toUpperCase() + key.slice(1),
    value
  }))

  const COLORS = ['#94a3b8', '#3b82f6', '#a855f7', '#10b981', '#ef4444', '#10b981']

  const renderLabel = (entry: any) => {
    const percent = entry.percent || 0
    return `${entry.name} ${(percent * 100).toFixed(0)}%`
  }

  return (
    <div className="space-y-6">
      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Total Proposals</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{metrics.totalProposals}</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Total Revenue</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold text-green-600">{formatCurrency(metrics.totalRevenue)}</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Approved</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{metrics.approvedProposals}</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Conversion Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{metrics.conversionRate.toFixed(1)}%</p>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600">Payment Rate</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{metrics.paymentRate.toFixed(1)}%</p>
          </CardContent>
        </Card>
      </div>

      {/* Calendar View - Pass all jobs */}
      <CalendarView 
        isExpanded={calendarExpanded} 
        onToggle={() => setCalendarExpanded(!calendarExpanded)}
        todaysJobsCount={todaysJobsCount}
        allJobs={allJobs}
      />

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Monthly Revenue Chart */}
        <Card>
          <CardHeader>
            <CardTitle>Monthly Revenue Trend</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={monthlyRevenue}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip formatter={(value) => formatCurrency(Number(value))} />
                <Line type="monotone" dataKey="revenue" stroke="#3b82f6" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Status Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>Proposal Status Distribution</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={statusData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={renderLabel}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {statusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Proposals */}
        <Card>
          <CardHeader>
            <div className="flex justify-between items-center">
              <CardTitle>Recent Proposals</CardTitle>
              <Link href="/proposals" className="text-sm text-blue-600 hover:text-blue-700">
                View all →
              </Link>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {recentProposals.map((proposal) => (
                <div key={proposal.id} className="flex items-center justify-between border-b pb-3 last:border-0">
                  <div className="flex-1">
                    <Link 
                      href={`/proposals/${proposal.id}`}
                      className="font-medium text-blue-600 hover:text-blue-700"
                    >
                      #{proposal.proposal_number}
                    </Link>
                    <p className="text-sm text-gray-600">{proposal.title}</p>
                    <p className="text-xs text-gray-500">
                      {proposal.customers?.[0]?.name || 'No customer'}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">{formatCurrency(proposal.total)}</p>
                    <span className={`inline-block px-2 py-1 text-xs rounded-full ${getStatusColor(proposal.status)}`}>
                      {proposal.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent Activities */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Activities</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {recentActivities.length > 0 ? recentActivities.map((activity) => (
                <div key={activity.id} className="flex items-start space-x-3 border-b pb-3 last:border-0">
                  <span className="text-2xl">{getActivityIcon(activity.activity_type)}</span>
                  <div className="flex-1">
                    <p className="text-sm">{activity.description}</p>
                    {activity.proposals?.[0] && (
                      <p className="text-xs text-gray-500">
                        Proposal #{activity.proposals[0].proposal_number}
                      </p>
                    )}
                    <p className="text-xs text-gray-400">{formatDate(activity.created_at)}</p>
                  </div>
                </div>
              )) : (
                <p className="text-sm text-gray-500">No recent activities</p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
EOF

echo "DashboardContent updated!"
echo "Now building and deploying..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -20

git add -A
git commit -m "Fix calendar job display - pass all jobs to calendar component"
git push origin main

echo "✅ Calendar fixes deployed!"
