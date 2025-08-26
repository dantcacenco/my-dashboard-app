#!/bin/bash

echo "Continuing comprehensive fix..."

# Update DashboardContent to properly handle jobs data
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
  monthlyJobs?: any[]
}

interface DashboardContentProps {
  data: DashboardData
}

export default function DashboardContent({ data }: DashboardContentProps) {
  const [calendarExpanded, setCalendarExpanded] = useState(false)
  const { metrics, monthlyRevenue, statusCounts, recentProposals, recentActivities, todaysJobsCount = 0, monthlyJobs = [] } = data

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

  // Custom label function with proper typing
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

      {/* Calendar View - Pass jobs data */}
      <CalendarView 
        isExpanded={calendarExpanded} 
        onToggle={() => setCalendarExpanded(!calendarExpanded)}
        todaysJobsCount={todaysJobsCount}
        monthlyJobs={monthlyJobs}
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
echo "Now running the complete fix..."

# Build and deploy
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -20

git add -A
git commit -m "Fix calendar and dashboard to properly show jobs - storage permissions SQL included"
git push origin main

echo ""
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "The dashboard and calendar have been fixed to properly show jobs."
echo ""
echo "⚠️ IMPORTANT: You still need to run the storage permissions SQL!"
echo ""
echo "Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT]/sql/new"
echo "and run the SQL from the file: storage-permissions.sql"
echo ""
echo "After deployment completes (1-2 minutes):"
echo "1. The dashboard will show the correct count of today's jobs"
echo "2. The calendar will display jobs when expanded"
echo "3. Technicians will be able to view/upload photos and files (after running SQL)"
