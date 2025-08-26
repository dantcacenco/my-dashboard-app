#!/bin/bash

# Add debug logging to technician dashboard
echo "Adding debug logging to technician dashboard..."

# Update the technician page with debug logging
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import TechnicianDashboard from './TechnicianDashboard'

export default async function TechnicianPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile
  const { data: profile } = await supabase
    .from('profiles')
    .select('role, full_name')
    .eq('id', user.id)
    .single()

  // Check if user is a technician
  if (!profile || profile.role !== 'technician') {
    redirect('/')
  }

  // Debug: Get ALL job_technicians entries for this user
  const { data: allAssignments, error: assignError } = await supabase
    .from('job_technicians')
    .select('*')
    .eq('technician_id', user.id)

  console.log('Debug - All assignments for technician:', user.id, allAssignments)
  console.log('Debug - Assignment error:', assignError)

  // Get jobs assigned to this technician with full details
  const { data: jobAssignments, error: jobError } = await supabase
    .from('job_technicians')
    .select(`
      job_id,
      jobs (
        id,
        job_number,
        title,
        description,
        job_type,
        status,
        scheduled_date,
        scheduled_time,
        service_address,
        notes,
        created_at,
        customer_id,
        customers (
          name,
          email,
          phone,
          address
        )
      )
    `)
    .eq('technician_id', user.id)
    .order('created_at', { ascending: false })

  console.log('Debug - Job assignments query result:', jobAssignments)
  console.log('Debug - Job assignments error:', jobError)

  // Extract jobs from assignments (handle the nested structure)
  const jobs = jobAssignments?.map(assignment => assignment.jobs).filter(Boolean).flat() || []

  console.log('Debug - Extracted jobs:', jobs)

  // Calculate metrics for technician
  const totalJobs = jobs.length
  const completedJobs = jobs.filter((j: any) => j.status === 'completed').length
  const inProgressJobs = jobs.filter((j: any) => j.status === 'in_progress').length
  const scheduledJobs = jobs.filter((j: any) => j.status === 'scheduled').length
  const todaysJobs = jobs.filter((j: any) => {
    const today = new Date().toISOString().split('T')[0]
    return j.scheduled_date?.split('T')[0] === today
  }).length

  const technicianData = {
    profile: {
      name: profile.full_name || user.email || 'Technician',
      email: user.email || '',
      role: profile.role
    },
    metrics: {
      totalJobs,
      completedJobs,
      inProgressJobs,
      scheduledJobs,
      todaysJobs
    },
    jobs,
    // Add debug info to be displayed
    debug: {
      userId: user.id,
      userEmail: user.email,
      role: profile?.role,
      allAssignments: allAssignments || [],
      jobAssignments: jobAssignments || [],
      assignmentError: assignError?.message,
      jobError: jobError?.message,
      extractedJobsCount: jobs.length
    }
  }

  return <TechnicianDashboard data={technicianData} />
}
EOF

# Update TechnicianDashboard to show debug info
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/TechnicianDashboard.tsx << 'EOF'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  Calendar, CheckCircle, Clock, Wrench, AlertCircle,
  ChevronRight, MapPin, Phone, Mail, User, Bug
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
    debug?: any
  }
}

export default function TechnicianDashboard({ data }: TechnicianDashboardProps) {
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list')
  const [showDebug, setShowDebug] = useState(true) // Show debug by default
  const { profile, metrics, jobs, debug } = data

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
      {/* Debug Info Card - ALWAYS VISIBLE DURING TROUBLESHOOTING */}
      {debug && (
        <Card className="border-yellow-500 bg-yellow-50">
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span className="flex items-center">
                <Bug className="h-5 w-5 mr-2" />
                Debug Information
              </span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowDebug(!showDebug)}
              >
                {showDebug ? 'Hide' : 'Show'}
              </Button>
            </CardTitle>
          </CardHeader>
          {showDebug && (
            <CardContent>
              <div className="space-y-2 text-sm font-mono">
                <p><strong>User ID:</strong> {debug.userId}</p>
                <p><strong>User Email:</strong> {debug.userEmail}</p>
                <p><strong>Role:</strong> {debug.role}</p>
                <p><strong>Total Assignments Found:</strong> {debug.allAssignments.length}</p>
                <p><strong>Job Assignments with Details:</strong> {debug.jobAssignments.length}</p>
                <p><strong>Extracted Jobs Count:</strong> {debug.extractedJobsCount}</p>
                
                {debug.assignmentError && (
                  <p className="text-red-600"><strong>Assignment Error:</strong> {debug.assignmentError}</p>
                )}
                {debug.jobError && (
                  <p className="text-red-600"><strong>Job Query Error:</strong> {debug.jobError}</p>
                )}
                
                <div className="mt-4">
                  <p><strong>Raw Assignments:</strong></p>
                  <pre className="bg-white p-2 rounded overflow-auto max-h-40">
                    {JSON.stringify(debug.allAssignments, null, 2)}
                  </pre>
                </div>
                
                <div className="mt-4">
                  <p><strong>Job Assignments with Jobs:</strong></p>
                  <pre className="bg-white p-2 rounded overflow-auto max-h-40">
                    {JSON.stringify(debug.jobAssignments, null, 2)}
                  </pre>
                </div>
              </div>
            </CardContent>
          )}
        </Card>
      )}

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
          <CardTitle>All Assigned Jobs ({jobs.length} total)</CardTitle>
        </CardHeader>
        <CardContent>
          {jobs.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <p className="text-lg mb-4">No jobs assigned yet</p>
              <p className="text-sm">Jobs will appear here once they are assigned to you by an administrator.</p>
            </div>
          ) : viewMode === 'list' ? (
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
        </CardContent>
      </Card>
    </div>
  )
}
EOF

# Build and commit
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -20

git add -A
git commit -m "Add debug logging to technician dashboard to troubleshoot missing jobs"
git push origin main

echo "✅ Debug logging added to technician dashboard"
echo "The dashboard will now show:"
echo "- User ID and email"
echo "- Role information"
echo "- Raw assignment data from database"
echo "- Any errors from queries"
echo "- Count of jobs found"
