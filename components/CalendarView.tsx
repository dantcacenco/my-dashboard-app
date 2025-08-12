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
  const [tasks, setTasks] = useState<any[]>([])
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    if (isExpanded) {
      loadTasks()
    }
  }, [currentDate, isExpanded])

  const loadTasks = async () => {
    setLoading(true)
    const startOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
    const endOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0)

    const { data } = await supabase
      .from('tasks')
      .select(`
        *,
        task_technicians (
          technician_id,
          profiles (full_name)
        ),
        jobs (job_number, customer_name)
      `)
      .gte('scheduled_date', startOfMonth.toISOString())
      .lte('scheduled_date', endOfMonth.toISOString())
      .order('scheduled_date', { ascending: true })

    setTasks(data || [])
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

  const getTasksForDay = (day: number) => {
    if (!day) return []
    const date = new Date(currentDate.getFullYear(), currentDate.getMonth(), day)
    const dateStr = date.toISOString().split('T')[0]
    return tasks.filter(task => task.scheduled_date === dateStr)
  }

  const getTaskTypeColor = (type: string) => {
    const colors: Record<string, string> = {
      service_call: 'bg-blue-500',
      repair: 'bg-red-500',
      maintenance: 'bg-green-500',
      rough_in: 'bg-yellow-500',
      startup: 'bg-purple-500',
      meeting: 'bg-gray-500',
      office: 'bg-pink-500'
    }
    return colors[type] || 'bg-gray-400'
  }

  const navigateMonth = (direction: number) => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + direction, 1))
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
            {tasks.filter(t => {
              const today = new Date().toISOString().split('T')[0]
              return t.scheduled_date === today
            }).length} tasks scheduled today
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
            Calendar - {currentDate.toLocaleString('default', { month: 'long', year: 'numeric' })}
          </CardTitle>
          <div className="flex items-center gap-2">
            <Button
              size="sm"
              variant="outline"
              onClick={() => navigateMonth(-1)}
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
              onClick={() => navigateMonth(1)}
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
          <div className="text-center py-8">Loading tasks...</div>
        ) : (
          <div>
            {/* Calendar Grid */}
            <div className="grid grid-cols-7 gap-1">
              {/* Day headers */}
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
                <div key={day} className="text-center text-sm font-medium text-gray-700 py-2">
                  {day}
                </div>
              ))}
              
              {/* Calendar days */}
              {getDaysInMonth().map((day, index) => {
                const dayTasks = day ? getTasksForDay(day) : []
                const isToday = day === new Date().getDate() && 
                               currentDate.getMonth() === new Date().getMonth() &&
                               currentDate.getFullYear() === new Date().getFullYear()
                
                return (
                  <div
                    key={index}
                    className={`
                      min-h-[80px] p-1 border rounded
                      ${!day ? 'bg-gray-50' : 'bg-white hover:bg-gray-50'}
                      ${isToday ? 'border-blue-500 border-2' : 'border-gray-200'}
                    `}
                  >
                    {day && (
                      <>
                        <div className="text-sm font-medium mb-1">{day}</div>
                        <div className="space-y-1">
                          {dayTasks.slice(0, 3).map((task, idx) => (
                            <Link
                              key={task.id}
                              href={`/tasks/${task.id}`}
                              className={`
                                block text-xs p-1 rounded truncate
                                ${getTaskTypeColor(task.task_type)} text-white
                                hover:opacity-80
                              `}
                              title={`${task.title} - ${task.jobs?.customer_name}`}
                            >
                              {task.scheduled_start_time?.slice(0, 5)} {task.title}
                            </Link>
                          ))}
                          {dayTasks.length > 3 && (
                            <div className="text-xs text-gray-500 text-center">
                              +{dayTasks.length - 3} more
                            </div>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                )
              })}
            </div>

            {/* Task Legend */}
            <div className="mt-4 flex flex-wrap gap-2 text-xs">
              <div className="flex items-center">
                <div className="w-3 h-3 bg-blue-500 rounded mr-1" />
                Service Call
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-red-500 rounded mr-1" />
                Repair
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-green-500 rounded mr-1" />
                Maintenance
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-yellow-500 rounded mr-1" />
                Rough In
              </div>
              <div className="flex items-center">
                <div className="w-3 h-3 bg-purple-500 rounded mr-1" />
                Startup
              </div>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
