'use client'

import Link from 'next/link'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, BarChart, Bar } from 'recharts'

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
}

interface DashboardContentProps {
  data: DashboardData
}

export default function DashboardContent({ data }: DashboardContentProps) {
  const { metrics, monthlyRevenue, statusCounts, recentProposals, recentActivities } = data

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
        return '📝'
      case 'sent':
        return '📤'
      case 'viewed':
        return '👁️'
      case 'approved_by_customer':
        return '✅'
      case 'rejected_by_customer':
        return '❌'
      case 'payment_received':
        return '💰'
      default:
        return '🔄'
    }
  }

  // Prepare pie chart data
  const pieData = [
    { name: 'Draft', value: statusCounts.draft, color: '#6B7280' },
    { name: 'Sent', value: statusCounts.sent, color: '#3B82F6' },
    { name: 'Viewed', value: statusCounts.viewed, color: '#8B5CF6' },
    { name: 'Approved', value: statusCounts.approved, color: '#10B981' },
    { name: 'Rejected', value: statusCounts.rejected, color: '#EF4444' },
    { name: 'Paid', value: statusCounts.paid, color: '#059669' }
  ].filter(item => item.value > 0)

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600 mt-2">Welcome back! Here's what's happening with your proposals.</p>
        </div>

        {/* Key Metrics Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6 mb-8">
          
          {/* Total Proposals */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-blue-100 rounded-lg">
                <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Total Proposals</p>
                <p className="text-2xl font-bold text-gray-900">{metrics.totalProposals}</p>
              </div>
            </div>
          </div>

          {/* Total Revenue */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-green-100 rounded-lg">
                <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                </svg>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Total Revenue</p>
                <p className="text-2xl font-bold text-gray-900">{formatCurrency(metrics.totalRevenue)}</p>
              </div>
            </div>
          </div>

          {/* Approved Proposals */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-emerald-100 rounded-lg">
                <svg className="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Approved</p>
                <p className="text-2xl font-bold text-gray-900">{metrics.approvedProposals}</p>
              </div>
            </div>
          </div>

          {/* Conversion Rate */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-purple-100 rounded-lg">
                <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Conversion Rate</p>
                <p className="text-2xl font-bold text-gray-900">{metrics.conversionRate.toFixed(1)}%</p>
              </div>
            </div>
          </div>

          {/* Payment Rate */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className="p-2 bg-orange-100 rounded-lg">
                <svg className="w-6 h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Payment Rate</p>
                <p className="text-2xl font-bold text-gray-900">{metrics.paymentRate.toFixed(1)}%</p>
              </div>
            </div>
          </div>

        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          
          {/* Revenue Trend Chart */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trend (6 Months)</h3>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={monthlyRevenue}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis tickFormatter={(value) => `$${(value / 1000).toFixed(0)}k`} />
                  <Tooltip 
                    formatter={(value: number) => [formatCurrency(value), 'Revenue']}
                    labelFormatter={(label) => `Month: ${label}`}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="revenue" 
                    stroke="#3B82F6" 
                    strokeWidth={3}
                    dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Proposal Status Distribution */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Proposal Status Distribution</h3>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={40}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: number, name: string) => [value, name]} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2">
              {pieData.map((entry, index) => (
                <div key={index} className="flex items-center">
                  <div 
                    className="w-3 h-3 rounded-full mr-2" 
                    style={{ backgroundColor: entry.color }}
                  ></div>
                  <span className="text-sm text-gray-600">{entry.name}: {entry.value}</span>
                </div>
              ))}
            </div>
          </div>

        </div>

        {/* Bottom Row - Recent Activity & Proposals */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          
          {/* Recent Proposals */}
          <div className="bg-white rounded-lg shadow">
            <div className="p-6 border-b border-gray-200">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-gray-900">Recent Proposals</h3>
                <Link
                  href="/proposals"
                  className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                >
                  View All →
                </Link>
              </div>
            </div>
            <div className="p-6">
              {recentProposals.length > 0 ? (
                <div className="space-y-4">
                  {recentProposals.map((proposal) => (
                    <div key={proposal.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-gray-900">{proposal.proposal_number}</span>
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(proposal.status)}`}>
                            {proposal.status}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600 truncate">{proposal.title}</p>
                        <p className="text-xs text-gray-500">
                          {proposal.customers?.[0]?.name} • {formatDate(proposal.created_at)}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-gray-900">{formatCurrency(proposal.total)}</p>
                        <Link
                          href={`/proposals/${proposal.id}`}
                          className="text-xs text-blue-600 hover:text-blue-800"
                        >
                          View →
                        </Link>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500 text-center py-4">No proposals yet</p>
              )}
            </div>
          </div>

          {/* Recent Activity */}
          <div className="bg-white rounded-lg shadow">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Recent Activity</h3>
            </div>
            <div className="p-6">
              {recentActivities.length > 0 ? (
                <div className="space-y-4">
                  {recentActivities.map((activity) => (
                    <div key={activity.id} className="flex items-start gap-3">
                      <div className="text-xl">{getActivityIcon(activity.activity_type)}</div>
                      <div className="flex-1">
                        <p className="text-sm text-gray-900">{activity.description}</p>
                        {activity.proposals && activity.proposals.length > 0 && (
                          <p className="text-xs text-gray-600">
                            {activity.proposals[0].proposal_number} - {activity.proposals[0].title}
                          </p>
                        )}
                        <p className="text-xs text-gray-500">{formatDate(activity.created_at)}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500 text-center py-4">No recent activity</p>
              )}
            </div>
          </div>

        </div>

      </div>
    </div>
  )
}