'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Plus, Grid, List, Calendar as CalendarIcon } from 'lucide-react'
import CalendarView from '@/components/CalendarView'
import { getUnifiedDisplayStatus } from '@/lib/status-sync'

interface TechnicianJobsListProps {
  jobs: any[]
  technicianName: string
}

export default function TechnicianJobsList({ jobs, technicianName }: TechnicianJobsListProps) {
  // Load saved view preference from localStorage or default to calendar
  const [viewMode, setViewMode] = useState<'list' | 'grid' | 'calendar'>('calendar')
  const [calendarExpanded, setCalendarExpanded] = useState(true)

  // Load saved view preference on mount
  useEffect(() => {
    const savedView = localStorage.getItem('technicianViewMode')
    if (savedView === 'list' || savedView === 'grid' || savedView === 'calendar') {
      setViewMode(savedView)
    }
  }, [])

  // Save view preference when it changes
  const handleViewModeChange = (newMode: 'list' | 'grid' | 'calendar') => {
    setViewMode(newMode)
    localStorage.setItem('technicianViewMode', newMode)
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'Not scheduled'
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const getStatusColor = (status: string) => {
    const displayStatus = status.toLowerCase().replace(' ', '_').replace('-', '_')
    
    switch (displayStatus) {
      case 'draft': return 'text-gray-500 bg-gray-100'
      case 'sent': return 'text-blue-600 bg-blue-100'
      case 'approved': return 'text-green-600 bg-green-100'
      case 'rejected': return 'text-red-600 bg-red-100'
      case 'deposit_paid': return 'text-blue-600 bg-blue-100'
      case 'rough_in_paid': return 'text-yellow-600 bg-yellow-100'
      case 'final_paid': return 'text-green-600 bg-green-100'
      case 'completed': return 'text-green-600 bg-green-100'
      case 'not_scheduled': return 'text-gray-500 bg-gray-100'
      case 'scheduled': return 'text-blue-600 bg-blue-100'
      case 'in_progress': return 'text-yellow-600 bg-yellow-100'
      case 'cancelled': return 'text-red-600 bg-red-100'
      default: return 'text-gray-500 bg-gray-100'
    }
  }

  // Format jobs for calendar view (add proposal status info)
  const formattedJobs = jobs.map(job => ({
    ...job,
    proposals: job.proposals || null
  }))

  // Calculate today's jobs count
  const today = new Date()
  const todayStr = today.toISOString().split('T')[0]
  const todaysJobsCount = jobs.filter(job => 
    job.scheduled_date && job.scheduled_date.split('T')[0] === todayStr
  ).length

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">My Jobs</h1>
          <p className="text-muted-foreground">Welcome, {technicianName}</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant={viewMode === 'calendar' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('calendar')}
          >
            <CalendarIcon className="h-4 w-4 mr-1" />
            Calendar
          </Button>
          <Button
            variant={viewMode === 'list' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('list')}
          >
            <List className="h-4 w-4 mr-1" />
            List
          </Button>
          <Button
            variant={viewMode === 'grid' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setViewMode('grid')}
          >
            <Grid className="h-4 w-4 mr-1" />
            Grid
          </Button>
        </div>
      </div>

      {/* Calendar View */}
      {viewMode === 'calendar' && (
        <CalendarView 
          isExpanded={calendarExpanded}
          onToggle={() => setCalendarExpanded(!calendarExpanded)}
          todaysJobsCount={todaysJobsCount}
          monthlyJobs={formattedJobs}
          isTechnician={true}
        />
      )}

      {/* Jobs Table/Grid */}
      {viewMode !== 'calendar' && (
        jobs.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 rounded-lg">
            <p className="text-gray-500">No jobs assigned yet</p>
            <p className="text-sm text-gray-400 mt-2">Jobs will appear here once they are assigned to you</p>
          </div>
        ) : viewMode === 'list' ? (
          <div className="bg-white shadow-sm rounded-lg overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Job #
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Customer
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Title
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Address
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Scheduled
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {jobs.map((job) => (
                  <tr
                    key={job.id}
                    className="hover:bg-gray-50 cursor-pointer"
                    onClick={() => window.location.href = `/technician/jobs/${job.id}`}
                  >
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-blue-600">
                      {job.job_number}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {job.customers?.name || job.customer_name || 'N/A'}
                      </div>
                      <div className="text-sm text-gray-500">
                        {job.customers?.phone || ''}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{job.title || 'No title'}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{job.service_address || job.customers?.address || 'No address'}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(getUnifiedDisplayStatus(job.status, job.proposals?.status))}`}>
                        {getUnifiedDisplayStatus(job.status, job.proposals?.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(job.scheduled_date)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {jobs.map((job) => (
              <Link key={job.id} href={`/technician/jobs/${job.id}`}>
                <div className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-6 cursor-pointer">
                  <div className="flex justify-between items-start mb-3">
                    <h3 className="text-lg font-semibold text-blue-600">
                      {job.job_number}
                    </h3>
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(getUnifiedDisplayStatus(job.status, job.proposals?.status))}`}>
                      {getUnifiedDisplayStatus(job.status, job.proposals?.status)}
                    </span>
                  </div>
                  <p className="text-gray-900 font-medium mb-2">{job.title || 'No title'}</p>
                  <p className="text-sm text-gray-600 mb-1">
                    {job.customers?.name || job.customer_name || 'No customer'}
                  </p>
                  <p className="text-sm text-gray-500 mb-3">
                    {job.service_address || job.customers?.address || 'No address'}
                  </p>
                  <p className="text-sm text-gray-500">
                    {formatDate(job.scheduled_date)}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        )
      )}
    </div>
  )
}