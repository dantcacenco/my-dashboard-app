'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  ArrowLeft, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Save, CheckCircle,
  AlertCircle, Phone, Mail
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'
import MediaViewer from '@/components/MediaViewer'
import VideoThumbnail from '@/components/VideoThumbnail'

interface TechnicianJobViewProps {
  job: any
  userId: string
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
  const [notes, setNotes] = useState('')
  const [isSavingNotes, setIsSavingNotes] = useState(false)

  useEffect(() => {
    loadJobMedia()
    loadJobFiles()
  }, [job.id])

  const loadJobMedia = async () => {
    console.log('Loading job media for job:', job.id)
    const { data, error } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: true })

    if (error) {
      console.error('Error loading job photos:', error)
    } else {
      console.log('Loaded job photos:', data)
      // Log each photo URL to debug
      data?.forEach((photo, index) => {
        console.log(`Photo ${index + 1} URL:`, photo.url)
        console.log(`Photo ${index + 1} type:`, photo.media_type)
        
        // Test if URL is accessible
        if (photo.media_type === 'photo' || !photo.media_type) {
          const img = new Image()
          img.onload = () => console.log(`Photo ${index + 1} loaded successfully`)
          img.onerror = (e) => console.error(`Photo ${index + 1} failed to load:`, e)
          img.src = photo.url
        }
      })
    }
    
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

  const updateJobStatus = async (newStatus: string) => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ status: newStatus })
        .eq('id', job.id)

      if (error) throw error

      setJob({ ...job, status: newStatus })
      toast.success(`Job status updated to ${newStatus.replace('_', ' ')}`)
    } catch (error) {
      console.error('Error updating job status:', error)
      toast.error('Failed to update job status')
    }
  }

  const saveNotes = async () => {
    if (!notes.trim()) return
    
    setIsSavingNotes(true)
    try {
      // Add note to job_notes table or append to job notes
      const currentNotes = job.notes || ''
      const timestamp = new Date().toLocaleString()
      const newNote = `[${timestamp}] Technician Note:\n${notes}\n\n${currentNotes}`
      
      const { error } = await supabase
        .from('jobs')
        .update({ notes: newNote })
        .eq('id', job.id)
      
      if (error) throw error
      
      setJob({ ...job, notes: newNote })
      setNotes('')
      toast.success('Notes saved successfully')
    } catch (error) {
      console.error('Error saving notes:', error)
      toast.error('Failed to save notes')
    }
    setIsSavingNotes(false)
  }

  const openMediaViewer = (items: any[], index: number) => {
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  return (
    <div className="max-w-7xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Link href="/technician">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Dashboard
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Job {job.job_number}</h1>
            <p className="text-muted-foreground">{job.title}</p>
          </div>
        </div>
        <Badge className={`${getStatusColor(job.status)} text-white`}>
          {job.status?.toUpperCase().replace('_', ' ')}
        </Badge>
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          
          {/* Update Job Status Card */}
          <Card>
            <CardHeader>
              <CardTitle>Update Job Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {job.status === 'scheduled' && (
                <Button
                  onClick={() => updateJobStatus('in_progress')}
                  className="w-full"
                  variant="default"
                >
                  <Clock className="h-4 w-4 mr-2" />
                  Start Job
                </Button>
              )}
              {job.status === 'in_progress' && (
                <Button
                  onClick={() => updateJobStatus('completed')}
                  className="w-full"
                  variant="default"
                >
                  <CheckCircle className="h-4 w-4 mr-2" />
                  Complete Job
                </Button>
              )}
              {job.status === 'completed' && (
                <div className="flex items-center justify-center text-green-600">
                  <CheckCircle className="h-5 w-5 mr-2" />
                  Job Completed
                </div>
              )}
            </CardContent>
          </Card>
          
          {/* Photos & Videos Card */}
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
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mt-4">
                  {jobPhotos.map((photo, index) => {
                    // Debug log for each photo
                    console.log(`Rendering photo ${index}:`, photo.url, 'Type:', photo.media_type)
                    
                    return (
                      <div
                        key={photo.id}
                        className="relative group cursor-pointer"
                        onClick={() => openMediaViewer(jobPhotos, index)}
                      >
                        {photo.media_type === 'video' ? (
                          <VideoThumbnail 
                            videoUrl={photo.url} 
                            onClick={() => openMediaViewer(jobPhotos, index)}
                          />
                        ) : (
                          <img
                            src={photo.url}
                            alt={photo.caption || 'Job photo'}
                            className="w-full h-32 object-cover rounded hover:opacity-90 transition"
                            onError={(e) => {
                              console.error('Image failed to load:', photo.url)
                              // Fallback to placeholder
                              const target = e.target as HTMLImageElement
                              target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZTVlN2ViIi8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIyMCIgZmlsbD0iIzZiNzI4MCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZG9taW5hbnQtYmFzZWxpbmU9Im1pZGRsZSI+SW1hZ2UgTm90IEZvdW5kPC90ZXh0Pgo8L3N2Zz4='
                            }}
                          />
                        )}
                        {photo.caption && (
                          <p className="text-xs mt-1 text-muted-foreground truncate">
                            {photo.caption}
                          </p>
                        )}
                      </div>
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Files Card */}
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
                <div className="space-y-2 mt-4">
                  {jobFiles.map((file) => (
                    <div key={file.id} className="flex items-center justify-between p-2 border rounded">
                      <div className="flex items-center gap-2">
                        <FileText className="h-4 w-4" />
                        <div>
                          <p className="text-sm font-medium">{file.file_name}</p>
                          <p className="text-xs text-muted-foreground">
                            {new Date(file.created_at).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      <a
                        href={file.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-500 hover:underline text-sm"
                      >
                        View
                      </a>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Add Notes Card */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Add Notes
              </CardTitle>
            </CardHeader>
            <CardContent>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Add notes about this job..."
                className="w-full p-3 border rounded-md min-h-[100px]"
              />
              <Button
                onClick={saveNotes}
                disabled={!notes.trim() || isSavingNotes}
                className="mt-2 w-full"
              >
                <Save className="h-4 w-4 mr-2" />
                {isSavingNotes ? 'Saving...' : 'Save Notes'}
              </Button>
              
              {job.notes && (
                <div className="mt-4 p-3 bg-gray-50 rounded-md">
                  <h4 className="font-semibold mb-2">Previous Notes:</h4>
                  <pre className="whitespace-pre-wrap text-sm">{job.notes}</pre>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right Sidebar - Job Details */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Customer</p>
                <p className="font-medium">{job.customers?.name || 'N/A'}</p>
                {job.customers?.phone && (
                  <a href={`tel:${job.customers.phone}`} className="text-blue-500 text-sm flex items-center gap-1 mt-1">
                    <Phone className="h-3 w-3" />
                    {job.customers.phone}
                  </a>
                )}
                {job.customers?.email && (
                  <a href={`mailto:${job.customers.email}`} className="text-blue-500 text-sm flex items-center gap-1 mt-1">
                    <Mail className="h-3 w-3" />
                    {job.customers.email}
                  </a>
                )}
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Job Type</p>
                <p className="font-medium">{job.job_type || 'N/A'}</p>
              </div>
              
              <div>
                <p className="text-sm font-medium text-muted-foreground">Job Overview</p>
                <p className="text-sm">{job.description || 'No description provided'}</p>
              </div>
              
              {job.scheduled_date && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Scheduled Date</p>
                  <p className="font-medium">
                    {new Date(job.scheduled_date).toLocaleDateString()}
                  </p>
                </div>
              )}
              
              {job.scheduled_time && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Scheduled Time</p>
                  <p className="font-medium">{job.scheduled_time}</p>
                </div>
              )}
              
              {job.address && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Location</p>
                  <p className="text-sm">{job.address}</p>
                </div>
              )}
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
