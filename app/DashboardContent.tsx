'use client'

import { useState } from 'react'
import Link from 'next/link'
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
  const [calendarExpanded, setCalendarExpanded] = useState(true) // Default to expanded
  const { recentProposals, recentActivities, todaysJobsCount = 0, monthlyJobs = [] } = data

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffInMs = now.getTime() - date.getTime()
    const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
    
    if (diffInHours < 1) {
      const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
      if (diffInMinutes < 1) return 'just now'
      return `${diffInMinutes} minute${diffInMinutes === 1 ? '' : 's'} ago`
    } else if (diffInHours < 24) {
      return `${diffInHours} hour${diffInHours === 1 ? '' : 's'} ago`
    } else if (diffInDays < 7) {
      return `${diffInDays} day${diffInDays === 1 ? '' : 's'} ago`
    } else {
      return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
  }

  const getStatusColor = (status: string) => {
    const colors = {
      draft: 'bg-gray-100 text-gray-800',
      sent: 'bg-blue-100 text-blue-800',
      viewed: 'bg-purple-100 text-purple-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      'deposit paid': 'bg-blue-100 text-blue-800',
      'rough-in paid': 'bg-yellow-100 text-yellow-800',
      'completed': 'bg-emerald-100 text-emerald-800',
      paid: 'bg-emerald-100 text-emerald-800'
    }
    return colors[status as keyof typeof colors] || 'bg-gray-100 text-gray-800'
  }

  const getActivityIcon = (activityType: string) => {
    switch (activityType) {
      case 'proposal_created':
        return '📄'
      case 'proposal_sent':
        return '📧'
      case 'proposal_approved':
        return '✅'
      case 'proposal_rejected':
        return '❌'
      case 'payment_received':
        return '💰'
      case 'job_created':
        return '🔧'
      case 'job_scheduled':
        return '📅'
      case 'job_started':
        return '🚀'
      case 'job_completed':
        return '✨'
      case 'technician_assigned':
        return '👷'
      case 'job_updated':
        return '📝'
      default:
        return '📋'
    }
  }

  return (
    <div className="space-y-6">
      {/* Calendar View - Now the primary focus */}
      <CalendarView 
        isExpanded={calendarExpanded} 
        onToggle={() => setCalendarExpanded(!calendarExpanded)}
        todaysJobsCount={todaysJobsCount}
        monthlyJobs={monthlyJobs}
      />

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
            <div className="space-y-3 max-h-[400px] overflow-y-auto pr-2">
              {recentProposals.length > 0 ? (
                recentProposals.map((proposal) => (
                  <div key={proposal.id} className="flex items-center justify-between pb-3 border-b last:border-0">
                    <div className="flex-1 min-w-0">
                      <Link 
                        href={`/proposals/${proposal.id}`}
                        className="font-medium text-blue-600 hover:text-blue-700"
                      >
                        #{proposal.proposal_number}
                      </Link>
                      <p className="text-sm text-gray-600 truncate">{proposal.title}</p>
                      <p className="text-xs text-gray-500">
                        {proposal.customers?.[0]?.name || 'No customer'}
                      </p>
                    </div>
                    <div className="text-right flex-shrink-0 ml-4">
                      <p className="font-medium">{formatCurrency(proposal.total)}</p>
                      <span className={`inline-block px-2 py-1 text-xs rounded-full ${getStatusColor(proposal.status)}`}>
                        {proposal.status}
                      </span>
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-sm text-gray-500">No proposals yet</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Recent Activities */}
        <Card>
          <CardHeader>
            <div className="flex justify-between items-center">
              <CardTitle>Recent Activities</CardTitle>
              <span className="text-xs text-gray-500">Last 7 days</span>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-[400px] overflow-y-auto pr-2">
              {recentActivities.length > 0 ? (
                recentActivities.slice(0, 20).map((activity, index) => (
                  <div 
                    key={`${activity.activity_type}-${activity.id}-${index}`} 
                    className="flex items-start space-x-3 pb-3 border-b last:border-0 hover:bg-gray-50 p-2 rounded transition-colors"
                  >
                    <span className="text-xl mt-0.5 flex-shrink-0">{getActivityIcon(activity.activity_type)}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-gray-900 break-words">{activity.description}</p>
                      <p className="text-xs text-gray-500 mt-1">{formatDate(activity.created_at)}</p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-8">
                  <p className="text-sm text-gray-500">No recent activities</p>
                  <p className="text-xs text-gray-400 mt-2">Activities will appear here as you create proposals, receive payments, and manage jobs.</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}