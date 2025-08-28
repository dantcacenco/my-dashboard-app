'use client'

import { useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import JobEditModal from '@/components/JobEditModal'
import { getUnifiedDisplayStatus } from '@/lib/status-sync'

interface CalendarViewProps {
  isExpanded: boolean
  onToggle: () => void
  todaysJobsCount?: number
  monthlyJobs?: any[]
}

export default function CalendarView({ 
  isExpanded, 
  onToggle, 
  todaysJobsCount = 0,
  monthlyJobs = []
}: CalendarViewProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [selectedJob, setSelectedJob] = useState<any>(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  
  // DEBUG: Log what we're receiving
  console.log('CalendarView DEBUG - monthlyJobs:', monthlyJobs)
  console.log('CalendarView DEBUG - monthlyJobs length:', monthlyJobs?.length)
  console.log('CalendarView DEBUG - First job:', monthlyJobs?.[0])
  
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

  const previousMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1))
  }

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1))
  }

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ]

  const getJobsForDay = (day: number) => {
    const dateStr = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    console.log('CalendarView DEBUG - Looking for jobs on:', dateStr)
    const dayJobs = monthlyJobs.filter(job => {
      const jobDate = job.scheduled_date && job.scheduled_date.split('T')[0]
      console.log('CalendarView DEBUG - Job date comparison:', jobDate, '===', dateStr, jobDate === dateStr)
      return jobDate === dateStr
    })
    console.log('CalendarView DEBUG - Found jobs for', dateStr, ':', dayJobs)
    return dayJobs
  }

  const getStatusColor = (status: string) => {
    // Get unified display status if proposal exists
    const displayStatus = status.toLowerCase().replace(' ', '_').replace('-', '_')
    
    switch (displayStatus) {
      // Proposal statuses
      case 'draft': return 'bg-gray-100 text-gray-800'
      case 'sent': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'deposit_paid': return 'bg-blue-100 text-blue-800'
      case 'rough_in_paid': return 'bg-yellow-100 text-yellow-800'
      case 'final_payment_complete': return 'bg-green-100 text-green-800'
      case 'final_paid': return 'bg-green-100 text-green-800'
      // Job statuses
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
          const displayStatus = getUnifiedDisplayStatus(job.status, job.proposal_id?.status)
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
      <Card>
        <CardHeader>
          <CardTitle className="flex justify-between items-center">
            <span>Calendar</span>
            <button onClick={onToggle} className="text-sm font-normal text-blue-500 hover:underline">
              Collapse
            </button>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex justify-between items-center mb-4">
            <button onClick={previousMonth} className="p-2 hover:bg-gray-100 rounded">
              <ChevronLeft className="h-5 w-5" />
            </button>
            <h3 className="text-lg font-semibold">
              {monthNames[currentDate.getMonth()]} {currentDate.getFullYear()}
            </h3>
            <button onClick={nextMonth} className="p-2 hover:bg-gray-100 rounded">
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
        />
      )}
    </>
  )
}
