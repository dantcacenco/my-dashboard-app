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
  todaysJobsCount?: number
  monthlyJobs?: any[]
}

export default function CalendarView({ isExpanded, onToggle, todaysJobsCount = 0, monthlyJobs = [] }: CalendarViewProps) {
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
            {todaysJobsCount} job{todaysJobsCount !== 1 ? 's' : ''} scheduled today
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
