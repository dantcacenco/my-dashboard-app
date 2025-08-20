'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Clock, Play, Pause, Edit2, Check, X } from 'lucide-react'
import { toast } from 'sonner'

interface TimeTrackingProps {
  jobId: string
  userId: string
  userRole: string
}

interface TimeEntry {
  id: string
  job_id: string
  user_id: string
  clock_in: string
  clock_out: string | null
  duration_minutes: number | null
  created_at: string
  profiles?: {
    full_name: string
    email: string
  }
}

export default function TimeTracking({ jobId, userId, userRole }: TimeTrackingProps) {
  const [timeEntries, setTimeEntries] = useState<TimeEntry[]>([])
  const [currentEntry, setCurrentEntry] = useState<TimeEntry | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editTime, setEditTime] = useState({ in: '', out: '' })
  const supabase = createClient()

  useEffect(() => {
    loadTimeEntries()
    checkCurrentEntry()
  }, [jobId])

  const loadTimeEntries = async () => {
    const { data } = await supabase
      .from('job_time_entries')
      .select('*, profiles!user_id(full_name, email)')
      .eq('job_id', jobId)
      .order('clock_in', { ascending: false })
    
    setTimeEntries(data || [])
  }

  const checkCurrentEntry = async () => {
    const { data } = await supabase
      .from('job_time_entries')
      .select('*')
      .eq('job_id', jobId)
      .eq('user_id', userId)
      .is('clock_out', null)
      .single()
    
    setCurrentEntry(data)
  }

  const handleClockIn = async () => {
    setIsLoading(true)
    const now = new Date().toISOString()
    
    const { data, error } = await supabase
      .from('job_time_entries')
      .insert({
        job_id: jobId,
        user_id: userId,
        clock_in: now
      })
      .select()
      .single()
    
    if (error) {
      toast.error('Failed to clock in')
    } else {
      setCurrentEntry(data)
      toast.success('Clocked in successfully')
      loadTimeEntries()
    }
    setIsLoading(false)
  }

  const handleClockOut = async () => {
    if (!currentEntry) return
    
    setIsLoading(true)
    const now = new Date().toISOString()
    const clockIn = new Date(currentEntry.clock_in)
    const clockOut = new Date(now)
    const durationMinutes = Math.round((clockOut.getTime() - clockIn.getTime()) / 60000)
    
    const { error } = await supabase
      .from('job_time_entries')
      .update({
        clock_out: now,
        duration_minutes: durationMinutes
      })
      .eq('id', currentEntry.id)
    
    if (error) {
      toast.error('Failed to clock out')
    } else {
      setCurrentEntry(null)
      toast.success('Clocked out successfully')
      loadTimeEntries()
    }
    setIsLoading(false)
  }

  const handleEditTime = (entry: TimeEntry) => {
    setEditingId(entry.id)
    setEditTime({
      in: new Date(entry.clock_in).toISOString().slice(0, 16),
      out: entry.clock_out ? new Date(entry.clock_out).toISOString().slice(0, 16) : ''
    })
  }

  const handleSaveEdit = async () => {
    if (!editingId) return
    
    const clockIn = new Date(editTime.in)
    const clockOut = editTime.out ? new Date(editTime.out) : null
    const durationMinutes = clockOut 
      ? Math.round((clockOut.getTime() - clockIn.getTime()) / 60000)
      : null
    
    const { error } = await supabase
      .from('job_time_entries')
      .update({
        clock_in: clockIn.toISOString(),
        clock_out: clockOut?.toISOString() || null,
        durationMinutes
      })
      .eq('id', editingId)
    
    if (error) {
      toast.error('Failed to update time entry')
    } else {
      toast.success('Time entry updated')
      setEditingId(null)
      loadTimeEntries()
    }
  }

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return `${hours}h ${mins}m`
  }

  const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const totalHours = timeEntries
    .reduce((sum, entry) => sum + (entry.duration_minutes || 0), 0) / 60

  return (
    <div className="bg-white rounded-lg border p-4">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-medium flex items-center gap-2">
          <Clock className="h-5 w-5" />
          Time Tracking
        </h3>
        <div className="text-sm text-gray-600">
          Total: <span className="font-semibold">{totalHours.toFixed(1)} hours</span>
        </div>
      </div>

      {/* Clock In/Out Button */}
      <div className="mb-4">
        {currentEntry ? (
          <button
            onClick={handleClockOut}
            disabled={isLoading}
            className="w-full bg-red-600 text-white py-3 rounded-lg hover:bg-red-700 disabled:opacity-50 flex items-center justify-center gap-2"
          >
            <Pause className="h-5 w-5" />
            Clock Out (Started {formatDateTime(currentEntry.clock_in)})
          </button>
        ) : (
          <button
            onClick={handleClockIn}
            disabled={isLoading}
            className="w-full bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 flex items-center justify-center gap-2"
          >
            <Play className="h-5 w-5" />
            Clock In
          </button>
        )}
      </div>

      {/* Time Entries List */}
      <div className="space-y-2 max-h-64 overflow-y-auto">
        {timeEntries.map((entry) => (
          <div key={entry.id} className="border rounded p-3">
            {editingId === entry.id ? (
              <div className="space-y-2">
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="datetime-local"
                    value={editTime.in}
                    onChange={(e) => setEditTime({ ...editTime, in: e.target.value })}
                    className="text-sm border rounded px-2 py-1"
                  />
                  <input
                    type="datetime-local"
                    value={editTime.out}
                    onChange={(e) => setEditTime({ ...editTime, out: e.target.value })}
                    className="text-sm border rounded px-2 py-1"
                  />
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={handleSaveEdit}
                    className="text-green-600 hover:text-green-700"
                  >
                    <Check className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => setEditingId(null)}
                    className="text-red-600 hover:text-red-700"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm font-medium">
                    {entry.profiles?.full_name || 'Unknown'}
                  </p>
                  <p className="text-xs text-gray-600">
                    In: {formatDateTime(entry.clock_in)}
                  </p>
                  {entry.clock_out && (
                    <p className="text-xs text-gray-600">
                      Out: {formatDateTime(entry.clock_out)}
                    </p>
                  )}
                  {entry.duration_minutes && (
                    <p className="text-xs font-medium text-blue-600">
                      Duration: {formatDuration(entry.duration_minutes)}
                    </p>
                  )}
                </div>
                {(userRole === 'boss' || entry.user_id === userId) && (
                  <button
                    onClick={() => handleEditTime(entry)}
                    className="text-gray-500 hover:text-gray-700"
                  >
                    <Edit2 className="h-4 w-4" />
                  </button>
                )}
              </div>
            )}
          </div>
        ))}
        
        {timeEntries.length === 0 && (
          <p className="text-center text-gray-500 py-4">No time entries yet</p>
        )}
      </div>
    </div>
  )
}
