'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight, Calendar } from 'lucide-react'
import { cn } from '@/lib/utils'
import JobDetailModal from '@/components/JobDetailModal'

interface Job {
  id: string
  job_number: string
  title: string
  scheduled_date: string
  scheduled_time: string | null
  status: string
  customers?: {
    name: string
  }
}

interface CalendarViewProps {
  jobs: Job[]
  onRefresh?: () => void
}

export default function CalendarView({ jobs, onRefresh }: CalendarViewProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [view, setView] = useState<'week' | 'month'>('week')
  const [selectedJob, setSelectedJob] = useState<string | null>(null)
  const [modalOpen, setModalOpen] = useState(false)

  const getStatusColor = (status: string) => {
    // Unified status colors for both proposals and jobs
    const colors: Record<string, string> = {
      // Proposal statuses
      'draft': 'bg-gray-500',
      'sent': 'bg-blue-500',
      'viewed': 'bg-purple-500',
      'approved': 'bg-green-500',
      'rejected': 'bg-red-500',
      // Job statuses
      'not_scheduled': 'bg-gray-500',
      'scheduled': 'bg-blue-500',
      'in_progress': 'bg-yellow-500',
      'completed': 'bg-green-500',
      'cancelled': 'bg-red-500'
    }
    return colors[status] || 'bg-gray-500'
  }

  const getWeekDates = (date: Date) => {
    const week = []
    const startOfWeek = new Date(date)
    const day = startOfWeek.getDay()
    const diff = startOfWeek.getDate() - day
    startOfWeek.setDate(diff)

    for (let i = 0; i < 7; i++) {
      const day = new Date(startOfWeek)
      day.setDate(startOfWeek.getDate() + i)
      week.push(day)
    }
    return week
  }

  const getMonthDates = (date: Date) => {
    const year = date.getFullYear()
    const month = date.getMonth()
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const startDate = new Date(firstDay)
    startDate.setDate(startDate.getDate() - startDate.getDay())
    
    const dates = []
    const current = new Date(startDate)
    
    while (current <= lastDay || current.getDay() !== 0) {
      dates.push(new Date(current))
      current.setDate(current.getDate() + 1)
    }
    
    return dates
  }

  const getJobsForDate = (date: Date) => {
    return jobs.filter(job => {
      if (!job.scheduled_date) return false
      const jobDate = new Date(job.scheduled_date)
      return (
        jobDate.getDate() === date.getDate() &&
        jobDate.getMonth() === date.getMonth() &&
        jobDate.getFullYear() === date.getFullYear()
      )
    })
  }

  const handleJobClick = (jobId: string) => {
    setSelectedJob(jobId)
    setModalOpen(true)
  }

  const handleModalClose = () => {
    setModalOpen(false)
    setSelectedJob(null)
  }

  const handleJobUpdate = () => {
    if (onRefresh) onRefresh()
  }

  const navigatePrevious = () => {
    const newDate = new Date(currentDate)
    if (view === 'week') {
      newDate.setDate(newDate.getDate() - 7)
    } else {
      newDate.setMonth(newDate.getMonth() - 1)
    }
    setCurrentDate(newDate)
  }

  const navigateNext = () => {
    const newDate = new Date(currentDate)
    if (view === 'week') {
      newDate.setDate(newDate.getDate() + 7)
    } else {
      newDate.setMonth(newDate.getMonth() + 1)
    }
    setCurrentDate(newDate)
  }

  const formatTimeRange = (job: Job) => {
    if (!job.scheduled_time) return ''
    const [hours, minutes] = job.scheduled_time.split(':')
    const hour = parseInt(hours)
    const ampm = hour >= 12 ? 'PM' : 'AM'
    const displayHour = hour > 12 ? hour - 12 : hour === 0 ? 12 : hour
    return `${displayHour}:${minutes} ${ampm}`
  }

  const renderWeekView = () => {
    const weekDates = getWeekDates(currentDate)
    const timeSlots = Array.from({ length: 14 }, (_, i) => i + 6) // 6 AM to 7 PM

    return (
      <div className="overflow-x-auto">
        <div className="min-w-[800px]">
          <div className="grid grid-cols-8 border-b">
            <div className="p-2 font-semibold text-sm">Time</div>
            {weekDates.map((date, index) => (
              <div key={index} className="p-2 text-center border-l">
                <div className="font-semibold text-sm">
                  {date.toLocaleDateString('en-US', { weekday: 'short' })}
                </div>
                <div className={cn(
                  "text-lg",
                  date.toDateString() === new Date().toDateString() && "font-bold text-primary"
                )}>
                  {date.getDate()}
                </div>
              </div>
            ))}
          </div>
          
          {timeSlots.map((hour) => (
            <div key={hour} className="grid grid-cols-8 border-b min-h-[60px]">
              <div className="p-2 text-sm text-muted-foreground">
                {hour > 12 ? `${hour - 12} PM` : hour === 12 ? '12 PM' : `${hour} AM`}
              </div>
              {weekDates.map((date, index) => {
                const dayJobs = getJobsForDate(date)
                const hourJobs = dayJobs.filter(job => {
                  if (!job.scheduled_time) return hour === 12 // Show unscheduled at noon
                  const [jobHour] = job.scheduled_time.split(':')
                  return parseInt(jobHour) === hour
                })
                
                return (
                  <div key={index} className="border-l p-1">
                    {hourJobs.map((job) => (
                      <button
                        key={job.id}
                        onClick={() => handleJobClick(job.id)}
                        className={cn(
                          "w-full text-left p-1 rounded text-xs text-white mb-1 hover:opacity-90 transition-opacity",
                          getStatusColor(job.status)
                        )}
                      >
                        <div className="font-semibold truncate">{job.job_number}</div>
                        <div className="truncate">{job.customers?.name}</div>
                      </button>
                    ))}
                  </div>
                )
              })}
            </div>
          ))}
        </div>
      </div>
    )
  }

  const renderMonthView = () => {
    const monthDates = getMonthDates(currentDate)
    const weeks = []
    for (let i = 0; i < monthDates.length; i += 7) {
      weeks.push(monthDates.slice(i, i + 7))
    }

    return (
      <div>
        <div className="grid grid-cols-7 gap-px bg-muted">
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
            <div key={day} className="bg-background p-2 text-center font-semibold text-sm">
              {day}
            </div>
          ))}
        </div>
        <div className="grid grid-cols-7 gap-px bg-muted">
          {monthDates.map((date, index) => {
            const dayJobs = getJobsForDate(date)
            const isToday = date.toDateString() === new Date().toDateString()
            const isCurrentMonth = date.getMonth() === currentDate.getMonth()
            
            return (
              <div
                key={index}
                className={cn(
                  "bg-background p-2 min-h-[100px]",
                  !isCurrentMonth && "text-muted-foreground"
                )}
              >
                <div className={cn(
                  "font-semibold text-sm mb-1",
                  isToday && "text-primary"
                )}>
                  {date.getDate()}
                </div>
                <div className="space-y-1">
                  {dayJobs.slice(0, 3).map((job) => (
                    <button
                      key={job.id}
                      onClick={() => handleJobClick(job.id)}
                      className={cn(
                        "w-full text-left p-1 rounded text-xs text-white hover:opacity-90 transition-opacity",
                        getStatusColor(job.status)
                      )}
                    >
                      <div className="truncate">
                        {formatTimeRange(job)} {job.job_number}
                      </div>
                    </button>
                  ))}
                  {dayJobs.length > 3 && (
                    <div className="text-xs text-muted-foreground">
                      +{dayJobs.length - 3} more
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Job Calendar
          </CardTitle>
          <div className="flex items-center gap-2">
            <div className="flex gap-1">
              <Button
                variant={view === 'week' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setView('week')}
              >
                Week
              </Button>
              <Button
                variant={view === 'month' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setView('month')}
              >
                Month
              </Button>
            </div>
            <div className="flex gap-1">
              <Button variant="outline" size="icon" onClick={navigatePrevious}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button variant="outline" size="icon" onClick={navigateNext}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentDate(new Date())}
            >
              Today
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        {view === 'week' ? renderWeekView() : renderMonthView()}
        
        {/* Status Legend */}
        <div className="mt-4 flex flex-wrap gap-2">
          <div className="flex items-center gap-1">
            <div className={cn("w-3 h-3 rounded", getStatusColor('not_scheduled'))} />
            <span className="text-xs">Not Scheduled</span>
          </div>
          <div className="flex items-center gap-1">
            <div className={cn("w-3 h-3 rounded", getStatusColor('scheduled'))} />
            <span className="text-xs">Scheduled</span>
          </div>
          <div className="flex items-center gap-1">
            <div className={cn("w-3 h-3 rounded", getStatusColor('in_progress'))} />
            <span className="text-xs">In Progress</span>
          </div>
          <div className="flex items-center gap-1">
            <div className={cn("w-3 h-3 rounded", getStatusColor('completed'))} />
            <span className="text-xs">Completed</span>
          </div>
          <div className="flex items-center gap-1">
            <div className={cn("w-3 h-3 rounded", getStatusColor('cancelled'))} />
            <span className="text-xs">Cancelled</span>
          </div>
        </div>

        {/* Job Detail Modal */}
        {selectedJob && (
          <JobDetailModal
            jobId={selectedJob}
            isOpen={modalOpen}
            onClose={handleModalClose}
            onUpdate={handleJobUpdate}
          />
        )}
      </CardContent>
    </Card>
  )
}
