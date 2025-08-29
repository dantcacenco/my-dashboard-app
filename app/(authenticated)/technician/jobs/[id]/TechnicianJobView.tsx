'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { 
  ArrowLeft, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Save, CheckCircle,
  AlertCircle, Phone, Mail, Play, Pause, Timer
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'
import MediaViewer from '@/components/MediaViewer'
import VideoThumbnail from '@/components/VideoThumbnail'
import { getUnifiedDisplayStatus } from '@/lib/status-sync'

interface TechnicianJobViewProps {
  job: any
  userId: string
}

interface TimeEntry {
  id: string
  job_id: string
  technician_id: string
  start_time: string
  end_time: string | null
  created_at: string
}

export default function TechnicianJobView({ job: initialJob, userId }: TechnicianJobViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [viewerOpen, setViewerOpen] = useState(false)
  const [viewerItems, setViewerItems] = useState<any[]>([])
  const [viewerIndex, setViewerIndex] = useState(0)
  const [notes, setNotes] = useState(job.notes || '')
  const [isSavingNotes, setIsSavingNotes] = useState(false)
  const [photosExpanded, setPhotosExpanded] = useState(false)
  const [filesExpanded, setFilesExpanded] = useState(false)  
  // Time tracking states
  const [isTimerRunning, setIsTimerRunning] = useState(false)
  const [timeEntries, setTimeEntries] = useState<TimeEntry[]>([])
  const [currentTimeEntry, setCurrentTimeEntry] = useState<TimeEntry | null>(null)
  const [elapsedTime, setElapsedTime] = useState(0)

  useEffect(() => {
    loadJobMedia()
    loadJobFiles()
    loadTimeEntries()
    checkActiveTimer()
  }, [job.id])

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout
    if (isTimerRunning && currentTimeEntry) {
      interval = setInterval(() => {
        const start = new Date(currentTimeEntry.start_time).getTime()
        const now = new Date().getTime()
        setElapsedTime(Math.floor((now - start) / 1000))
      }, 1000)
    }
    return () => clearInterval(interval)
  }, [isTimerRunning, currentTimeEntry])

  const loadJobMedia = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: true })

    setJobPhotos(data || [])
  }

  const loadJobFiles = async () => {
    const { data } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })

    setJobFiles(data || [])
  }

  const loadTimeEntries = async () => {
    try {
      const { data, error } = await supabase
        .from('time_entries')
        .select('*')
        .eq('job_id', job.id)
        .eq('technician_id', userId)
        .order('start_time', { ascending: false })

      if (error) {
        console.error('Error loading time entries:', error)
        // If table doesn't exist, show a message
        if (error.message?.includes('relation "time_entries" does not exist')) {
          toast.error('Time tracking not set up. Please contact your administrator.')
        }
      } else {
        setTimeEntries(data || [])
      }
    } catch (err) {
      console.error('Error in loadTimeEntries:', err)
    }
  }
  const checkActiveTimer = async () => {
    try {
      // Check if there's an active timer (no end_time)
      const { data, error } = await supabase
        .from('time_entries')
        .select('*')
        .eq('job_id', job.id)
        .eq('technician_id', userId)
        .is('end_time', null)
        .single()

      if (error && !error.message?.includes('No rows')) {
        console.error('Error checking active timer:', error)
        return
      }

      if (data) {
        setCurrentTimeEntry(data)
        setIsTimerRunning(true)
        const start = new Date(data.start_time).getTime()
        const now = new Date().getTime()
        setElapsedTime(Math.floor((now - start) / 1000))
      }
    } catch (err) {
      console.error('Error in checkActiveTimer:', err)
    }
  }

  const startTimer = async () => {
    try {
      const { data, error } = await supabase
        .from('time_entries')
        .insert({
          job_id: job.id,
          technician_id: userId,
          start_time: new Date().toISOString()
        })
        .select()
        .single()

      if (error) {
        console.error('Error starting timer:', error)
        if (error.message?.includes('relation "time_entries" does not exist')) {
          toast.error('Time tracking not set up. Please contact your administrator to run the database migration.')
        } else {
          toast.error('Failed to start timer: ' + error.message)
        }
        return
      }

      setCurrentTimeEntry(data)
      setIsTimerRunning(true)
      setElapsedTime(0)
      toast.success('Timer started')
    } catch (error) {
      console.error('Error starting timer:', error)
      toast.error('Failed to start timer')
    }
  }

  const stopTimer = async () => {
    if (!currentTimeEntry) return

    try {
      const { error } = await supabase
        .from('time_entries')
        .update({ end_time: new Date().toISOString() })
        .eq('id', currentTimeEntry.id)

      if (error) throw error

      setIsTimerRunning(false)
      setCurrentTimeEntry(null)
      setElapsedTime(0)
      loadTimeEntries()
      toast.success('Timer stopped')
    } catch (error) {
      console.error('Error stopping timer:', error)
      toast.error('Failed to stop timer')
    }
  }
  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  const calculateTotalHours = () => {
    let total = 0
    timeEntries.forEach(entry => {
      if (entry.end_time) {
        const start = new Date(entry.start_time).getTime()
        const end = new Date(entry.end_time).getTime()
        total += (end - start) / 1000 / 3600 // Convert to hours
      }
    })
    return total.toFixed(2)
  }

  const getStatusColor = (status: string) => {
    const displayStatus = status.toLowerCase().replace(' ', '_').replace('-', '_')
    
    switch (displayStatus) {
      case 'draft': return 'bg-gray-500'
      case 'sent': return 'bg-blue-500'
      case 'approved': return 'bg-green-500'
      case 'rejected': return 'bg-red-500'
      case 'deposit_paid': return 'bg-blue-500'
      case 'rough_in_paid': return 'bg-yellow-500'
      case 'final_paid': return 'bg-green-500'
      case 'completed': return 'bg-green-500'
      case 'not_scheduled': return 'bg-gray-500'
      case 'scheduled': return 'bg-blue-500'
      case 'in_progress': return 'bg-yellow-500'
      case 'cancelled': return 'bg-red-500'
      default: return 'bg-gray-500'
    }
  }

  const updateJobStatus = async (newStatus: string, proposalStatus?: string) => {
    try {
      // If there's a proposal and we're setting specific statuses, update proposal instead
      if (job.proposals && proposalStatus) {
        const { error } = await supabase
          .from('proposals')
          .update({ status: proposalStatus })
          .eq('id', job.proposals.id)

        if (error) throw error

        setJob({ 
          ...job, 
          proposals: { ...job.proposals, status: proposalStatus }
        })
        toast.success(`Status updated to ${proposalStatus.replace('_', ' ')}`)
      } else {
        // Update job status directly
        const { error } = await supabase
          .from('jobs')
          .update({ status: newStatus })
          .eq('id', job.id)

        if (error) throw error

        setJob({ ...job, status: newStatus })
        toast.success(`Job status updated to ${newStatus.replace('_', ' ')}`)
      }
    } catch (error) {
      console.error('Error updating status:', error)
      toast.error('Failed to update status')
    }
  }

  const updateJobWorkStatus = async (statusField: 'work_started' | 'roughin_done' | 'final_done') => {
    try {
      const currentValue = job[statusField] || false
      const newValue = !currentValue
      
      // Prepare update object
      const updateData: any = { [statusField]: newValue }
      
      // Add timestamp field if toggling on
      if (newValue) {
        const timestampField = statusField + '_at'
        updateData[timestampField] = new Date().toISOString()
      }
      
      // Update job status
      const { error } = await supabase
        .from('jobs')
        .update(updateData)
        .eq('id', job.id)

      if (error) throw error

      // Update local state
      const updatedJob = { ...job, ...updateData }
      setJob(updatedJob)
      
      // Show success message
      const statusLabels = {
        work_started: 'Work Started',
        roughin_done: 'Rough-In Done',
        final_done: 'Final Done'
      }
      
      toast.success(`${statusLabels[statusField]} ${newValue ? 'marked complete' : 'unmarked'}`)
    } catch (error) {
      console.error('Error updating work status:', error)
      toast.error('Failed to update status')
    }
  }

  const saveNotes = async () => {
    setIsSavingNotes(true)
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ notes })
        .eq('id', job.id)

      if (error) throw error

      setJob({ ...job, notes })
      toast.success('Notes saved successfully')
    } catch (error) {
      console.error('Error saving notes:', error)
      toast.error('Failed to save notes')
    } finally {
      setIsSavingNotes(false)
    }
  }
  const openMediaViewer = (items: any[], index: number) => {
    console.log('Opening media viewer with items:', items, 'at index:', index)
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const openFileViewer = (files: any[], index: number) => {
    console.log('Opening file viewer with files:', files, 'at index:', index)
    setViewerItems(files.map(f => ({
      ...f,
      photo_url: f.file_url,
      caption: f.file_name
    })))
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const formatJobOverview = (description: string | null | undefined) => {
    if (!description) return 'No overview available'
    
    return description.split('\n').map((line, index) => {
      if (line.includes('SERVICES:') || line.includes('ADD-ONS:')) {
        return (
          <div key={index} className="font-semibold mt-2 mb-1">
            {line}
          </div>
        )
      }
      if (line.trim()) {
        return (
          <div key={index} className="ml-2">
            {line}
          </div>
        )
      }
      return <div key={index} className="h-2" />
    })
  }

  return (
    <div className="max-w-7xl mx-auto p-4 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div className="flex items-start gap-4">
          <Link href="/technician">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4" />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Job {job.job_number}</h1>
            <p className="text-muted-foreground">{job.title}</p>
          </div>
          <Badge className={getStatusColor(getUnifiedDisplayStatus(job.status, job.proposals?.status))}>
            {getUnifiedDisplayStatus(job.status, job.proposals?.status).toUpperCase()}
          </Badge>
        </div>
      </div>
      {/* Time Sheet Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Timer className="h-5 w-5" />
            Time Sheet
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {/* Timer Controls */}
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-4">
                {isTimerRunning ? (
                  <>
                    <Button
                      onClick={stopTimer}
                      variant="destructive"
                      size="lg"
                    >
                      <Pause className="h-5 w-5 mr-2" />
                      Stop
                    </Button>
                    <div className="text-2xl font-mono font-bold text-blue-600">
                      {formatTime(elapsedTime)}
                    </div>
                  </>
                ) : (
                  <Button
                    onClick={startTimer}
                    variant="default"
                    size="lg"
                    className="bg-green-600 hover:bg-green-700"
                  >
                    <Play className="h-5 w-5 mr-2" />
                    Start
                  </Button>
                )}
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-500">Total Hours</p>
                <p className="text-xl font-bold">{calculateTotalHours()}</p>
              </div>
            </div>
            {/* Time Entries Table */}
            {timeEntries.length > 0 && (
              <div>
                <h4 className="font-medium mb-2">Time Log</h4>
                <div className="border rounded-lg overflow-hidden">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-4 py-2 text-left">Date</th>
                        <th className="px-4 py-2 text-left">Start Time</th>
                        <th className="px-4 py-2 text-left">End Time</th>
                        <th className="px-4 py-2 text-left">Duration</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {timeEntries.map((entry) => {
                        const start = new Date(entry.start_time)
                        const end = entry.end_time ? new Date(entry.end_time) : null
                        const duration = end ? (end.getTime() - start.getTime()) / 1000 / 3600 : 0
                        
                        return (
                          <tr key={entry.id}>
                            <td className="px-4 py-2">{start.toLocaleDateString()}</td>
                            <td className="px-4 py-2">{start.toLocaleTimeString()}</td>
                            <td className="px-4 py-2">
                              {end ? end.toLocaleTimeString() : 'In Progress'}
                            </td>
                            <td className="px-4 py-2">
                              {end ? `${duration.toFixed(2)} hrs` : '-'}
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
      {/* Status Update Card */}
      <Card>
        <CardHeader>
          <CardTitle>Update Job Status</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            <Button
              onClick={() => updateJobWorkStatus('work_started')}
              variant={job.work_started ? 'default' : 'outline'}
              size="sm"
            >
              Work Started
            </Button>
            <Button
              onClick={() => updateJobWorkStatus('roughin_done')}
              variant={job.roughin_done ? 'default' : 'outline'}
              size="sm"
            >
              Rough-In Done
            </Button>
            <Button
              onClick={() => updateJobWorkStatus('final_done')}
              variant={job.final_done ? 'default' : 'outline'}
              size="sm"
              className={job.final_done ? 'bg-green-600 hover:bg-green-700' : ''}
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Final Done
            </Button>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content - Left Side */}
        <div className="lg:col-span-2 space-y-6">          {/* Photos & Videos */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Camera className="h-5 w-5" />
                Photos & Videos
              </CardTitle>
            </CardHeader>
            <CardContent>
              <MediaUpload
                jobId={job.id}
                userId={userId}
                onUploadComplete={loadJobMedia}
              />

              {jobPhotos.length > 0 && (
                <div>
                  <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
                    {(photosExpanded ? jobPhotos : jobPhotos.slice(0, 3)).map((photo, index) => (
                      <div
                        key={photo.id}
                        className="relative group cursor-pointer"
                        onClick={() => openMediaViewer(jobPhotos, index)}
                      >
                        {photo.mime_type?.startsWith('video/') ? (
                          <VideoThumbnail 
                            videoUrl={photo.photo_url} 
                            onClick={() => openMediaViewer(jobPhotos, index)} 
                          />
                        ) : (
                          <img
                            src={photo.photo_url}
                            alt={photo.caption || 'Job photo'}
                            className="w-full h-32 object-cover rounded hover:opacity-90 transition"
                          />
                        )}
                        {photo.caption && (
                          <div className="absolute bottom-0 left-0 right-0 bg-black/50 text-white text-xs p-2 rounded-b">
                            {photo.caption}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                  {jobPhotos.length > 3 && (
                    <div className="flex justify-center mt-4">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPhotosExpanded(!photosExpanded)}
                      >
                        {photosExpanded ? 'Collapse' : `Expand (${jobPhotos.length - 3} more)`}
                      </Button>
                    </div>
                  )}
                </div>
              )}

              {jobPhotos.length === 0 && (
                <p className="text-muted-foreground mt-4">No photos or videos uploaded yet</p>
              )}
            </CardContent>
          </Card>
          {/* Documents & Files */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Documents & Files
              </CardTitle>
            </CardHeader>
            <CardContent>
              <FileUpload
                jobId={job.id}
                userId={userId}
                onUploadComplete={loadJobFiles}
              />

              {jobFiles.length > 0 && (
                <div>
                  <div className="space-y-2 mt-4">
                    {(filesExpanded ? jobFiles : jobFiles.slice(0, 3)).map((file, index) => (
                      <div key={file.id} className="flex items-center justify-between p-3 border rounded hover:bg-gray-50">
                        <div 
                          className="flex items-center gap-3 flex-1 cursor-pointer"
                          onClick={() => openFileViewer(jobFiles, index)}
                        >
                          <FileText className="h-5 w-5 text-muted-foreground" />
                          <div>
                            <p className="font-medium text-blue-600 hover:text-blue-800">
                              {file.file_name}
                            </p>
                            <p className="text-sm text-muted-foreground">
                              {new Date(file.created_at).toLocaleDateString()}
                            </p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                  {jobFiles.length > 3 && (
                    <div className="flex justify-center mt-4">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setFilesExpanded(!filesExpanded)}
                      >
                        {filesExpanded ? 'Collapse' : `Expand (${jobFiles.length - 3} more)`}
                      </Button>
                    </div>
                  )}
                </div>
              )}

              {jobFiles.length === 0 && (
                <p className="text-muted-foreground mt-4">No files uploaded yet</p>
              )}
            </CardContent>
          </Card>
          {/* Notes */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Add notes about this job..."
                rows={6}
                className="w-full"
              />
              <Button
                onClick={saveNotes}
                disabled={isSavingNotes}
                className="mt-3"
              >
                <Save className="h-4 w-4 mr-2" />
                {isSavingNotes ? 'Saving...' : 'Save Notes'}
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Right Sidebar */}
        <div className="space-y-6">
          {/* Customer Info */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Customer Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="font-medium">{job.customers?.name || 'N/A'}</p>
              </div>
              {job.customers?.email && (
                <div className="flex items-center gap-2 text-sm">
                  <Mail className="h-4 w-4 text-muted-foreground" />
                  <span>{job.customers.email}</span>
                </div>
              )}
              {job.customers?.phone && (
                <div className="flex items-center gap-2 text-sm">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  <span>{job.customers.phone}</span>
                </div>
              )}
              {(job.service_address || job.customers?.address) && (
                <div className="flex items-start gap-2 text-sm">
                  <MapPin className="h-4 w-4 text-muted-foreground mt-0.5" />
                  <span>{job.service_address || job.customers.address}</span>
                </div>
              )}
            </CardContent>
          </Card>
          {/* Job Details */}
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <h3 className="font-medium text-sm text-muted-foreground">Job Type</h3>
                <p>{job.job_type || 'N/A'}</p>
              </div>

              <div>
                <h3 className="font-medium text-sm text-muted-foreground">Scheduled Date</h3>
                <div className="flex items-center gap-2">
                  <Calendar className="h-4 w-4 text-muted-foreground" />
                  <span>
                    {job.scheduled_date 
                      ? new Date(job.scheduled_date).toLocaleDateString('en-US', {
                          weekday: 'long',
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        })
                      : 'Not scheduled'}
                  </span>
                </div>
              </div>

              {job.scheduled_time && (
                <div>
                  <h3 className="font-medium text-sm text-muted-foreground">Scheduled Time</h3>
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4 text-muted-foreground" />
                    <span>{job.scheduled_time}</span>
                  </div>
                </div>
              )}

              <div>
                <h3 className="font-medium text-sm text-muted-foreground">Job Overview</h3>
                <div className="text-sm mt-2">
                  {formatJobOverview(job.description)}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Media Viewer Modal */}
      {viewerOpen && (
        <MediaViewer
          items={viewerItems}
          initialIndex={viewerIndex}
          onClose={() => setViewerOpen(false)}
        />
      )}
    </div>
  )
}