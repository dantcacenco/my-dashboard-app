'use client'

import { useState } from 'react'
import { ChevronLeft, ChevronRight, Calendar, CalendarDays } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import JobEditModal from '@/components/JobEditModal'
import { getUnifiedDisplayStatus } from '@/lib/status-sync'

interface CalendarViewProps {
  isExpanded: boolean
  onToggle: () => void
  todaysJobsCount?: number
  monthlyJobs?: any[]
  isTechnician?: boolean
}

export default function CalendarView({ 
  isExpanded, 
  onToggle, 
  todaysJobsCount = 0,
  monthlyJobs = [],
  isTechnician = false
}: CalendarViewProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [selectedJob, setSelectedJob] = useState<any>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [viewMode, setViewMode] = useState<'month' | 'week'>('month')
  
  // Calculate actual today's jobs from monthlyJobs
  const today = new Date()
  const todayStr = today.toISOString().split('T')[0]
  const actualTodaysJobs = monthlyJobs.filter(job => 
    job.scheduled_date && job.scheduled_date.split('T')[0] === todayStr
  )
  const displayCount = actualTodaysJobs.length

  const getDaysInMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
  }

  const getFirstDayOfMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay()
  }

  const getWeekStart = (date: Date) => {
    const d = new Date(date)
    const day = d.getDay()
    const diff = d.getDate() - day
    return new Date(d.setDate(diff))
  }

  const getWeekDays = (startDate: Date) => {
    const days = []
    for (let i = 0; i < 7; i++) {
      const day = new Date(startDate)
      day.setDate(startDate.getDate() + i)
      days.push(day)
    }
    return days
  }

  const previousPeriod = () => {
    if (viewMode === 'month') {
      setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1))
    } else {
      const newDate = new Date(currentDate)
      newDate.setDate(currentDate.getDate() - 7)
      setCurrentDate(newDate)
    }
  }

  const nextPeriod = () => {
    if (viewMode === 'month') {
      setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1))
    } else {
      const newDate = new Date(currentDate)
      newDate.setDate(currentDate.getDate() + 7)
      setCurrentDate(newDate)
    }
  }

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ]

  const getJobsForDay = (day: number | Date) => {
    let dateStr: string
    if (day instanceof Date) {
      dateStr = day.toISOString().split('T')[0]
    } else {
      dateStr = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    }
    return monthlyJobs.filter(job => 
      job.scheduled_date && job.scheduled_date.split('T')[0] === dateStr
    )
  }

  const getStatusColor = (status: string) => {
    const displayStatus = status.toLowerCase().replace(' ', '_').replace('-', '_')
    
    switch (displayStatus) {
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'deposit_paid': return 'bg-blue-100 text-blue-800'
      case 'rough_in_paid': return 'bg-yellow-100 text-yellow-800'
      case 'final_payment_complete': return 'bg-green-100 text-green-800'
      case 'final_paid': return 'bg-green-100 text-green-800'
      case 'not_scheduled': return 'bg-gray-100 text-gray-800'
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-purple-100 text-purple-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getLegendStatusColor = (status: string) => {
    switch (status) {
      case 'not_scheduled': return 'bg-gray-500'
      case 'scheduled': return 'bg-blue-500'
      case 'approved': return 'bg-green-500'
      case 'deposit_paid': return 'bg-blue-500'
      case 'in_progress': return 'bg-purple-500'
      case 'rough_in_paid': return 'bg-yellow-500'
      case 'completed': return 'bg-green-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const handleJobClick = (job: any) => {
    setSelectedJob(job)
    setIsModalOpen(true)
  }

  const handleModalClose = () => {
    setIsModalOpen(false)
    setSelectedJob(null)
  }

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  }

  if (!isExpanded) {
    return (
      <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={onToggle}>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>📅 Calendar</span>
            <span className="text-sm font-normal text-gray-500">Click to expand</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-lg">
            {displayCount} {displayCount === 1 ? 'job' : 'jobs'} scheduled today
          </p>
        </CardContent>
      </Card>
    )
  }

  const renderWeekView = () => {
    const weekStart = getWeekStart(currentDate)
    const weekDays = getWeekDays(weekStart)
    const weekEnd = weekDays[6]
    
    // Generate hour slots from 7 AM to 7 PM (12 hours)
    const hours = []
    for (let i = 7; i <= 19; i++) {
      hours.push(i)
    }

    const formatHour = (hour: number) => {
      if (hour === 0) return '12 AM'
      if (hour === 12) return '12 PM'
      if (hour < 12) return `${hour} AM`
      return `${hour - 12} PM`
    }

    const getJobsForTimeSlot = (date: Date, hour: number) => {
      const dayJobs = getJobsForDay(date)
      return dayJobs.filter(job => {
        if (!job.scheduled_time) return false
        const [jobHour] = job.scheduled_time.split(':').map(Number)
        return jobHour === hour
      })
    }

    return (
      <>
        <div className="flex justify-between items-center mb-4">
          <button onClick={previousPeriod} className="p-2 hover:bg-gray-100 rounded">
            <ChevronLeft className="h-5 w-5" />
          </button>
          <h3 className="text-lg font-semibold">
            {formatDate(weekStart)} - {formatDate(weekEnd)}, {weekStart.getFullYear()}
          </h3>
          <button onClick={nextPeriod} className="p-2 hover:bg-gray-100 rounded">
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>

        <div className="overflow-x-auto">
          <div className="min-w-[800px]">
            {/* Header row with day names and dates */}
            <div className="grid grid-cols-8 gap-0 sticky top-0 z-10 bg-white">
              <div className="w-16"></div> {/* Empty cell for time column */}
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day, index) => {
                const date = weekDays[index]
                const isToday = date.toDateString() === today.toDateString()
                return (
                  <div key={day} className={`border-l border-gray-200 text-center p-2 ${isToday ? 'bg-blue-50' : 'bg-gray-50'}`}>
                    <div className="font-semibold text-sm">{day}</div>
                    <div className="text-lg font-medium">{date.getDate()}</div>
                  </div>
                )
              })}
            </div>

            {/* Time slots with days */}
            <div className="border-t border-gray-200">
              {hours.map(hour => (
                <div key={hour} className="grid grid-cols-8 gap-0 border-b border-gray-100">
                  <div className="w-16 text-right pr-2 py-2 text-xs text-gray-500 border-r border-gray-200">
                    {formatHour(hour)}
                  </div>
                  {weekDays.map((date, dayIndex) => {
                    const isToday = date.toDateString() === today.toDateString()
                    const timeSlotJobs = getJobsForTimeSlot(date, hour)
                    
                    return (
                      <div 
                        key={`${hour}-${dayIndex}`} 
                        className={`border-l border-gray-200 p-1 min-h-[60px] ${isToday ? 'bg-blue-50/30' : 'bg-white'} hover:bg-gray-50`}
                      >
                        {timeSlotJobs.map(job => {
                          const displayStatus = getUnifiedDisplayStatus(job.status, job.proposals?.status)
                          return (
                            <div 
                              key={job.id} 
                              className={`text-xs p-1 mb-1 rounded cursor-pointer hover:opacity-80 transition-opacity ${getStatusColor(displayStatus)}`}
                              onClick={() => handleJobClick(job)}
                            >
                              <div className="font-medium">{job.job_number}</div>
                              {job.scheduled_time && (
                                <div className="text-[10px] opacity-75">{job.scheduled_time}</div>
                              )}
                            </div>
                          )
                        })}
                      </div>
                    )
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>
      </>
    )
  }

  const renderMonthView = () => {
    const daysInMonth = getDaysInMonth(currentDate)
    const firstDay = getFirstDayOfMonth(currentDate)
    const days = []

    // Add empty cells for days before month starts
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="border border-gray-200 p-2 min-h-[100px] bg-gray-50"></div>)
    }

    // Add days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const dayJobs = getJobsForDay(day)
      const isToday = day === today.getDate() && 
                     currentDate.getMonth() === today.getMonth() && 
                     currentDate.getFullYear() === today.getFullYear()

      days.push(
        <div 
          key={day} 
          className={`border border-gray-200 p-2 min-h-[100px] ${isToday ? 'bg-blue-50' : 'bg-white'}`}
        >
          <div className="font-semibold text-sm mb-1">{day}</div>
          {dayJobs.slice(0, 2).map(job => {
            const displayStatus = getUnifiedDisplayStatus(job.status, job.proposals?.status)
            return (
              <div 
                key={job.id} 
                className={`text-xs p-1 mb-1 rounded cursor-pointer hover:opacity-80 transition-opacity ${getStatusColor(displayStatus)}`}
                onClick={() => handleJobClick(job)}
              >
                {job.job_number}
              </div>
            )
          })}
          {dayJobs.length > 2 && (
            <div className="text-xs text-gray-500">+{dayJobs.length - 2} more</div>
          )}
        </div>
      )
    }

    return (
      <>
        <div className="flex justify-between items-center mb-4">
          <button onClick={previousPeriod} className="p-2 hover:bg-gray-100 rounded">
            <ChevronLeft className="h-5 w-5" />
          </button>
          <h3 className="text-lg font-semibold">
            {monthNames[currentDate.getMonth()]} {currentDate.getFullYear()}
          </h3>
          <button onClick={nextPeriod} className="p-2 hover:bg-gray-100 rounded">
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>

        <div className="grid grid-cols-7 gap-0">
          {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
            <div key={day} className="font-semibold text-center p-2 border border-gray-200 bg-gray-100">
              {day}
            </div>
          ))}
          {days}
        </div>
      </>
    )
  }

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle className="flex justify-between items-center">
            <span>Calendar</span>
            <div className="flex items-center gap-2">
              <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
                <Button
                  size="sm"
                  variant={viewMode === 'week' ? 'default' : 'ghost'}
                  onClick={() => setViewMode('week')}
                  className="h-7 px-2"
                >
                  <CalendarDays className="h-4 w-4 mr-1" />
                  Week
                </Button>
                <Button
                  size="sm"
                  variant={viewMode === 'month' ? 'default' : 'ghost'}
                  onClick={() => setViewMode('month')}
                  className="h-7 px-2"
                >
                  <Calendar className="h-4 w-4 mr-1" />
                  Month
                </Button>
              </div>
              <button onClick={onToggle} className="text-sm font-normal text-blue-500 hover:underline">
                Collapse
              </button>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {viewMode === 'week' ? renderWeekView() : renderMonthView()}

          {/* Updated Status Legend - Unified System */}
          <div className="flex flex-wrap gap-4 mt-4 text-sm">
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('not_scheduled')}`}></div>
              <span>Not Scheduled</span>
            </div>
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('scheduled')}`}></div>
              <span>Scheduled / Approved</span>
            </div>
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('deposit_paid')}`}></div>
              <span>Deposit Paid</span>
            </div>
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('in_progress')}`}></div>
              <span>In Progress</span>
            </div>
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('rough_in_paid')}`}></div>
              <span>Rough-In Paid</span>
            </div>
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('completed')}`}></div>
              <span>Completed / Final Paid</span>
            </div>
            <div className="flex items-center gap-1">
              <div className={`w-3 h-3 rounded-full ${getLegendStatusColor('cancelled')}`}></div>
              <span>Cancelled</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Job Edit Modal */}
      {selectedJob && (
        <JobEditModal 
          job={selectedJob}
          isOpen={isModalOpen}
          onClose={handleModalClose}
          onUpdate={() => {
            // Optionally refresh the calendar data here
            window.location.reload()
          }}
          isTechnician={isTechnician}
        />
      )}
    </>
  )
}
