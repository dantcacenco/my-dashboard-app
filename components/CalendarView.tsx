'use client'

import { useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

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
    return monthlyJobs.filter(job => 
      job.scheduled_date && job.scheduled_date.split('T')[0] === dateStr
    )
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'not_scheduled': return 'bg-gray-100 text-gray-800'
      case 'scheduled': return 'bg-blue-100 text-blue-800'
      case 'in_progress': return 'bg-yellow-100 text-yellow-800'
      case 'completed': return 'bg-green-100 text-green-800'
      case 'cancelled': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
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
        {dayJobs.slice(0, 2).map(job => (
          <div 
            key={job.id} 
            className={`text-xs p-1 mb-1 rounded ${getStatusColor(job.status)}`}
          >
            {job.job_number}
          </div>
        ))}
        {dayJobs.length > 2 && (
          <div className="text-xs text-gray-500">+{dayJobs.length - 2} more</div>
        )}
      </div>
    )
  }

  return (
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

        {/* Status Legend */}
        <div className="flex gap-4 mt-4 text-sm">
          <div className="flex items-center gap-1">
            <div className="w-3 h-3 rounded-full bg-gray-500"></div>
            <span>Not Scheduled</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-3 h-3 rounded-full bg-blue-500"></div>
            <span>Scheduled</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
            <span>In Progress</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-3 h-3 rounded-full bg-green-500"></div>
            <span>Completed</span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-3 h-3 rounded-full bg-red-500"></div>
            <span>Cancelled</span>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
