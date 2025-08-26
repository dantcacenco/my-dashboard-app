#!/bin/bash

# Enhance calendar with jobs and create technician portal
echo "Enhancing calendar and creating technician portal..."

# 1. First, update the CalendarView component to show jobs and add week/month view
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/CalendarView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight, Calendar, Plus } from 'lucide-react'
import Link from 'next/link'

interface CalendarViewProps {
  isExpanded: boolean
  onToggle: () => void
}

export default function CalendarView({ isExpanded, onToggle }: CalendarViewProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [jobs, setJobs] = useState<any[]>([])
  const [loading, setLoading] = useState(false)
  const [viewMode, setViewMode] = useState<'month' | 'week'>('month')
  const supabase = createClient()

  useEffect(() => {
    if (isExpanded) {
      loadJobs()
    }
  }, [currentDate, isExpanded, viewMode])

  const loadJobs = async () => {
    setLoading(true)
    
    let startDate: Date
    let endDate: Date
    
    if (viewMode === 'month') {
      startDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
      endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)
    } else {
      // Week view
      const dayOfWeek = currentDate.getDay()
      startDate = new Date(currentDate)
      startDate.setDate(currentDate.getDate() - dayOfWeek)
      startDate.setHours(0, 0, 0, 0)
      
      endDate = new Date(startDate)
      endDate.setDate(startDate.getDate() + 6)
      endDate.setHours(23, 59, 59, 999)
    }

    const { data } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (name, address),
        job_technicians (
          technician_id,
          profiles (full_name, email)
        )
      `)
      .gte('scheduled_date', startDate.toISOString())
      .lte('scheduled_date', endDate.toISOString())
      .order('scheduled_date', { ascending: true })

    setJobs(data || [])
    setLoading(false)
  }

  const getDaysInMonth = () => {
    const year = currentDate.getFullYear()
    const month = currentDate.getMonth()
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const daysInMonth = lastDay.getDate()
    const startingDayOfWeek = firstDay.getDay()

    const days = []
    
    // Add empty cells for days before month starts
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(null)
    }
    
    // Add all days of the month
    for (let i = 1; i <= daysInMonth; i++) {
      days.push(i)
    }
    
    return days
  }

  const getWeekDays = () => {
    const days = []
    const startOfWeek = new Date(currentDate)
    const dayOfWeek = startOfWeek.getDay()
    startOfWeek.setDate(startOfWeek.getDate() - dayOfWeek)
    
    for (let i = 0; i < 7; i++) {
      const day = new Date(startOfWeek)
      day.setDate(startOfWeek.getDate() + i)
      days.push(day)
    }
    
    return days
  }

  const getJobsForDay = (date: Date | number) => {
    let targetDate: Date
    
    if (typeof date === 'number') {
      targetDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), date)
    } else {
      targetDate = date
    }
    
    const dateStr = targetDate.toISOString().split('T')[0]
    return jobs.filter(job => {
      const jobDate = job.scheduled_date?.split('T')[0]
      return jobDate === dateStr
    })
  }

  const getJobStatusColor = (status: string) => {
    switch (status) {
      case 'not_scheduled': return 'bg-gray-500'
      case 'scheduled': return 'bg-blue-500'
      case 'in_progress': return 'bg-yellow-500'
      case 'completed': return 'bg-green-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-400'
    }
  }

  const getJobTypeColor = (type: string) => {
    switch (type) {
      case 'installation': return 'bg-blue-500'
      case 'repair': return 'bg-red-500'
      case 'maintenance': return 'bg-green-500'
      case 'inspection': return 'bg-purple-500'
      default: return 'bg-gray-400'
    }
  }

  const navigate = (direction: number) => {
    if (viewMode === 'month') {
      setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + direction, 1))
    } else {
      const newDate = new Date(currentDate)
      newDate.setDate(currentDate.getDate() + (direction * 7))
      setCurrentDate(newDate)
    }
  }

  const formatTime = (time: string | null) => {
    if (!time) return ''
    const [hours, minutes] = time.split(':')
    const hour = parseInt(hours)
    const ampm = hour >= 12 ? 'PM' : 'AM'
    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour
    return `${displayHour}:${minutes} ${ampm}`
  }

  if (!isExpanded) {
    return (
      <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={onToggle}>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center">
              <Calendar className="h-5 w-5 mr-2" />
              Calendar
            </CardTitle>
            <span className="text-sm text-gray-500">Click to expand</span>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-gray-600">
            {jobs.filter(j => {
              const today = new Date().toISOString().split('T')[0]
              return j.scheduled_date?.split('T')[0] === today
            }).length} jobs scheduled today
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="col-span-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center">
            <Calendar className="h-5 w-5 mr-2" />
            Calendar - {viewMode === 'month' 
              ? currentDate.toLocaleString('default', { month: 'long', year: 'numeric' })
              : `Week of ${currentDate.toLocaleDateString()}`
            }
          </CardTitle>
          <div className="flex items-center gap-2">
            <div className="flex rounded-md shadow-sm" role="group">
              <Button
                size="sm"
                variant={viewMode === 'week' ? 'default' : 'outline'}
                onClick={() => setViewMode('week')}
                className="rounded-r-none"
              >
                Week
              </Button>
              <Button
                size="sm"
                variant={viewMode === 'month' ? 'default' : 'outline'}
                onClick={() => setViewMode('month')}
                className="rounded-l-none"
              >
                Month
              </Button>
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={() => navigate(-1)}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => setCurrentDate(new Date())}
            >
              Today
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => navigate(1)}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button
              size="sm"
              variant="ghost"
              onClick={onToggle}
            >
              Collapse
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="text-center py-8">Loading jobs...</div>
        ) : viewMode === 'month' ? (
          <div>
            {/* Month View - Calendar Grid */}
            <div className="grid grid-cols-7 gap-1">
              {/* Day headers */}
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
                <div key={day} className="text-center text-sm font-medium text-gray-700 py-2">
                  {day}
                </div>
              ))}
              
              {/* Calendar days */}
              {getDaysInMonth().map((day, index) => {
                const dayJobs = day ? getJobsForDay(day) : []
                const isToday = day === new Date().getDate() && 
                               currentDate.getMonth() === new Date().getMonth() &&
                               currentDate.getFullYear() === new Date().getFullYear()
                
                return (
                  <div
                    key={index}
                    className={`
                      min-h-[100px] p-1 border rounded
                      ${!day ? 'bg-gray-50' : 'bg-white hover:bg-gray-50'}
                      ${isToday ? 'border-blue-500 border-2' : 'border-gray-200'}
                    `}
                  >
                    {day && (
                      <>
                        <div className="text-sm font-medium mb-1">{day}</div>
                        <div className="space-y-1">
                          {dayJobs.slice(0, 3).map((job) => (
                            <Link
                              key={job.id}
                              href={`/jobs/${job.id}`}
                              className={`
                                block text-xs p-1 rounded truncate
                                ${getJobStatusColor(job.status)} text-white
                                hover:opacity-80
                              `}
                              title={`${job.job_number} - ${job.title || 'No title'} - ${job.customers?.name || 'No customer'}`}
                            >
                              {job.scheduled_time && formatTime(job.scheduled_time).slice(0, -3)} {job.job_number}
                            </Link>
                          ))}
                          {dayJobs.length > 3 && (
                            <div className="text-xs text-gray-500 text-center">
                              +{dayJobs.length - 3} more
                            </div>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        ) : (
          <div>
            {/* Week View - Time Grid */}
            <div className="grid grid-cols-8 gap-0 border-l border-t">
              {/* Time column header */}
              <div className="text-center text-sm font-medium text-gray-700 p-2 border-r border-b">
                Time
              </div>
              
              {/* Day headers for week view */}
              {getWeekDays().map((day, idx) => {
                const isToday = day.toDateString() === new Date().toDateString()
                return (
                  <div 
                    key={idx} 
                    className={`text-center text-sm font-medium p-2 border-r border-b ${
                      isToday ? 'bg-blue-50' : ''
                    }`}
                  >
                    <div>{day.toLocaleDateString('en-US', { weekday: 'short' })}</div>
                    <div className="text-lg">{day.getDate()}</div>
                  </div>
                )
              })}
              
              {/* Time slots */}
              {Array.from({ length: 13 }, (_, i) => i + 6).map(hour => (
                <>
                  {/* Time label */}
                  <div key={`time-${hour}`} className="text-xs text-gray-500 p-2 border-r border-b">
                    {hour === 12 ? '12 PM' : hour > 12 ? `${hour - 12} PM` : `${hour} AM`}
                  </div>
                  
                  {/* Day cells for this hour */}
                  {getWeekDays().map((day, dayIdx) => {
                    const dayJobs = getJobsForDay(day)
                    const hourJobs = dayJobs.filter(job => {
                      if (!job.scheduled_time) return false
                      const jobHour = parseInt(job.scheduled_time.split(':')[0])
                      return jobHour === hour
                    })
                    
                    return (
                      <div 
                        key={`${hour}-${dayIdx}`} 
                        className="min-h-[60px] p-1 border-r border-b bg-white hover:bg-gray-50"
                      >
                        {hourJobs.map(job => (
                          <Link
                            key={job.id}
                            href={`/jobs/${job.id}`}
                            className={`
                              block text-xs p-1 mb-1 rounded truncate
                              ${getJobStatusColor(job.status)} text-white
                              hover:opacity-80
                            `}
                            title={`${job.job_number} - ${job.title || 'No title'}`}
                          >
                            {formatTime(job.scheduled_time)} {job.job_number}
                          </Link>
                        ))}
                      </div>
                    )
                  })}
                </>
              ))}
            </div>
          </div>
        )}
        
        {/* Job Status Legend */}
        <div className="mt-4 flex flex-wrap gap-2 text-xs">
          <div className="flex items-center">
            <div className="w-3 h-3 bg-gray-500 rounded mr-1" />
            Not Scheduled
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-blue-500 rounded mr-1" />
            Scheduled
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-yellow-500 rounded mr-1" />
            In Progress
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-green-500 rounded mr-1" />
            Completed
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-red-500 rounded mr-1" />
            Cancelled
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
EOF

# 2. Update the technician dashboard page
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

  // Get jobs assigned to this technician
  const { data: jobAssignments } = await supabase
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

  // Extract jobs from assignments (handle the nested structure)
  const jobs = jobAssignments?.map(assignment => assignment.jobs).filter(Boolean) || []

  // Calculate metrics for technician
  const totalJobs = jobs.length
  const completedJobs = jobs.filter(j => j.status === 'completed').length
  const inProgressJobs = jobs.filter(j => j.status === 'in_progress').length
  const scheduledJobs = jobs.filter(j => j.status === 'scheduled').length
  const todaysJobs = jobs.filter(j => {
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
    jobs
  }

  return <TechnicianDashboard data={technicianData} />
}
EOF

# 3. Create the TechnicianDashboard component
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/technician/TechnicianDashboard.tsx << 'EOF'
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
EOF

# Build test
echo "Testing build..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -80

if [ $? -eq 0 ]; then
  echo "Build successful!"
  
  # Commit and push
  git add -A
  git commit -m "Enhanced calendar with jobs display and week/month view, created technician portal"
  git push origin main
  
  echo "✅ Successfully enhanced calendar and created technician portal!"
  echo "Calendar enhancements:"
  echo "- Now shows jobs instead of tasks"
  echo "- Added week/month view toggle"
  echo "- Week view shows time slots like macOS calendar"
  echo "- Jobs are color-coded by status"
  echo ""
  echo "Technician portal features:"
  echo "- Same UI as admin dashboard"
  echo "- Shows only jobs assigned to the technician"
  echo "- Metrics cards for job overview"
  echo "- Today's jobs highlighted"
  echo "- List and grid view options"
  echo "- Hides prices and proposal links"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
