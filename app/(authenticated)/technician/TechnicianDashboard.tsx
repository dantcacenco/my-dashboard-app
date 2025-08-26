'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  Calendar, CheckCircle, Clock, Wrench, AlertCircle,
  ChevronRight, MapPin, Phone, Mail, User
} from 'lucide-react'

interface TechnicianDashboardProps {
  data: {
    profile: {
      name: string
      email: string
      role: string
    }
    metrics: {
      totalJobs: number
      completedJobs: number
      inProgressJobs: number
      scheduledJobs: number
      todaysJobs: number
    }
    jobs: any[]
  }
}

export default function TechnicianDashboard({ data }: TechnicianDashboardProps) {
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list')
  const { profile, metrics, jobs } = data

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'not_scheduled': return 'bg-gray-500'
      case 'scheduled': return 'bg-blue-500'
      case 'in_progress': return 'bg-yellow-500'
      case 'completed': return 'bg-green-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const getJobTypeIcon = (type: string) => {
    switch (type) {
      case 'installation': return '🔧'
      case 'repair': return '🔨'
      case 'maintenance': return '🛠️'
      case 'inspection': return '🔍'
      default: return '📋'
    }
  }

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'Not scheduled'
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  const formatTime = (time: string | null) => {
    if (!time) return ''
    const [hours, minutes] = time.split(':')
    const hour = parseInt(hours)
    const ampm = hour >= 12 ? 'PM' : 'AM'
    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour
    return `${displayHour}:${minutes} ${ampm}`
  }

  // Group jobs by status
  const jobsByStatus = {
    today: jobs.filter(j => {
      const today = new Date().toISOString().split('T')[0]
      return j.scheduled_date?.split('T')[0] === today
    }),
    scheduled: jobs.filter(j => j.status === 'scheduled'),
    inProgress: jobs.filter(j => j.status === 'in_progress'),
    completed: jobs.filter(j => j.status === 'completed')
  }

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold">Welcome, {profile.name}!</h1>
          <p className="text-gray-600">Here's your job overview</p>
        </div>
        <div className="flex gap-2">
          <Button
            variant={viewMode === 'list' ? 'default' : 'outline'}
            onClick={() => setViewMode('list')}
            size="sm"
          >
            List View
          </Button>
          <Button
            variant={viewMode === 'grid' ? 'default' : 'outline'}
            onClick={() => setViewMode('grid')}
            size="sm"
          >
            Grid View
          </Button>
        </div>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600 flex items-center">
              <Calendar className="h-4 w-4 mr-2" />
              Today's Jobs
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{metrics.todaysJobs}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600 flex items-center">
              <Clock className="h-4 w-4 mr-2" />
              Scheduled
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold text-blue-600">{metrics.scheduledJobs}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600 flex items-center">
              <Wrench className="h-4 w-4 mr-2" />
              In Progress
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold text-yellow-600">{metrics.inProgressJobs}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600 flex items-center">
              <CheckCircle className="h-4 w-4 mr-2" />
              Completed
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold text-green-600">{metrics.completedJobs}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-600 flex items-center">
              <AlertCircle className="h-4 w-4 mr-2" />
              Total Jobs
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-bold">{metrics.totalJobs}</p>
          </CardContent>
        </Card>
      </div>

      {/* Today's Jobs Section */}
      {jobsByStatus.today.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600">⚡ Today's Jobs</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {jobsByStatus.today.map((job) => (
                <Link key={job.id} href={`/technician/jobs/${job.id}`}>
                  <div className="flex items-center justify-between p-3 border rounded hover:bg-gray-50 cursor-pointer">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-lg">{getJobTypeIcon(job.job_type)}</span>
                        <h3 className="font-medium">
                          Job #{job.job_number} - {job.title || 'No title'}
                        </h3>
                        <Badge className={getStatusColor(job.status) + ' text-white'}>
                          {job.status.replace('_', ' ')}
                        </Badge>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">
                        <User className="h-3 w-3 inline mr-1" />
                        {job.customers?.name || 'No customer'}
                        {job.scheduled_time && (
                          <span className="ml-3">
                            <Clock className="h-3 w-3 inline mr-1" />
                            {formatTime(job.scheduled_time)}
                          </span>
                        )}
                      </p>
                      {job.service_address && (
                        <p className="text-sm text-gray-500 mt-1">
                          <MapPin className="h-3 w-3 inline mr-1" />
                          {job.service_address}
                        </p>
                      )}
                    </div>
                    <ChevronRight className="h-5 w-5 text-gray-400" />
                  </div>
                </Link>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Jobs List/Grid */}
      <Card>
        <CardHeader>
          <CardTitle>All Assigned Jobs</CardTitle>
        </CardHeader>
        <CardContent>
          {viewMode === 'list' ? (
            <div className="space-y-3">
              {jobs.map((job) => (
                <Link key={job.id} href={`/technician/jobs/${job.id}`}>
                  <div className="flex items-center justify-between p-4 border rounded hover:bg-gray-50 cursor-pointer">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-lg">{getJobTypeIcon(job.job_type)}</span>
                        <h3 className="font-medium">
                          Job #{job.job_number} - {job.title || 'No title'}
                        </h3>
                        <Badge className={getStatusColor(job.status) + ' text-white'}>
                          {job.status.replace('_', ' ')}
                        </Badge>
                      </div>
                      <div className="grid grid-cols-2 gap-4 mt-2">
                        <p className="text-sm text-gray-600">
                          <User className="h-3 w-3 inline mr-1" />
                          {job.customers?.name || 'No customer'}
                        </p>
                        <p className="text-sm text-gray-600">
                          <Calendar className="h-3 w-3 inline mr-1" />
                          {formatDate(job.scheduled_date)}
                          {job.scheduled_time && ` at ${formatTime(job.scheduled_time)}`}
                        </p>
                      </div>
                      {job.service_address && (
                        <p className="text-sm text-gray-500 mt-1">
                          <MapPin className="h-3 w-3 inline mr-1" />
                          {job.service_address}
                        </p>
                      )}
                    </div>
                    <ChevronRight className="h-5 w-5 text-gray-400" />
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {jobs.map((job) => (
                <Link key={job.id} href={`/technician/jobs/${job.id}`}>
                  <Card className="hover:shadow-lg transition-shadow cursor-pointer">
                    <CardHeader className="pb-3">
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="text-sm text-gray-500">#{job.job_number}</p>
                          <h3 className="font-medium">{job.title || 'No title'}</h3>
                        </div>
                        <span className="text-2xl">{getJobTypeIcon(job.job_type)}</span>
                      </div>
                      <Badge className={getStatusColor(job.status) + ' text-white'}>
                        {job.status.replace('_', ' ')}
                      </Badge>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <p className="text-sm">
                        <User className="h-3 w-3 inline mr-1" />
                        {job.customers?.name || 'No customer'}
                      </p>
                      <p className="text-sm">
                        <Calendar className="h-3 w-3 inline mr-1" />
                        {formatDate(job.scheduled_date)}
                      </p>
                      {job.scheduled_time && (
                        <p className="text-sm">
                          <Clock className="h-3 w-3 inline mr-1" />
                          {formatTime(job.scheduled_time)}
                        </p>
                      )}
                      {job.service_address && (
                        <p className="text-sm text-gray-500">
                          <MapPin className="h-3 w-3 inline mr-1" />
                          {job.service_address}
                        </p>
                      )}
                    </CardContent>
                  </Card>
                </Link>
              ))}
            </div>
          )}
          
          {jobs.length === 0 && (
            <div className="text-center py-8 text-gray-500">
              No jobs assigned yet
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
