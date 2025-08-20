'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  ArrowLeft, Calendar, MapPin, User, 
  FileText, Camera, Save, Clock, Phone, Mail
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'
import MediaViewer from '@/components/MediaViewer'
import TimeTracking from '@/components/TimeTracking'

interface TechnicianJobDetailViewProps {
  jobId: string
  userId: string
}

export default function TechnicianJobDetailView({ jobId, userId }: TechnicianJobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState<any>(null)
  const [isEditingNotes, setIsEditingNotes] = useState(false)
  const [notesText, setNotesText] = useState('')
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [viewerOpen, setViewerOpen] = useState(false)
  const [viewerItems, setViewerItems] = useState<any[]>([])
  const [viewerIndex, setViewerIndex] = useState(0)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadJob()
    loadJobMedia()
    loadJobFiles()
  }, [jobId])

  const loadJob = async () => {
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        customers!customer_id (
          name,
          email,
          phone,
          address
        )
      `)
      .eq('id', jobId)
      .single()
    
    if (data) {
      setJob(data)
      setNotesText(data.notes || '')
    }
    setLoading(false)
  }

  const loadJobMedia = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', jobId)
      .order('created_at', { ascending: false })
    
    setJobPhotos(data || [])
  }

  const loadJobFiles = async () => {
    const { data } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', jobId)
      .order('created_at', { ascending: false })
    
    setJobFiles(data || [])
  }

  const handleSaveNotes = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ notes: notesText })
      .eq('id', jobId)

    if (!error) {
      setJob({ ...job, notes: notesText })
      setIsEditingNotes(false)
      toast.success('Notes updated')
    } else {
      toast.error('Failed to update notes')
    }
  }

  const openPhotoViewer = (index: number) => {
    const items = jobPhotos.map(photo => ({
      id: photo.id,
      url: photo.photo_url,
      name: photo.caption || 'Media',
      caption: photo.caption,
      type: 'photo' as const,
      mime_type: photo.mime_type
    }))
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const openFileViewer = (index: number) => {
    const items = jobFiles.map(file => ({
      id: file.id,
      url: file.file_url,
      name: file.file_name,
      type: 'file' as const,
      mime_type: file.mime_type
    }))
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'not_scheduled': 'bg-gray-100 text-gray-800',
      'scheduled': 'bg-blue-100 text-blue-800',
      'in_progress': 'bg-yellow-100 text-yellow-800',
      'completed': 'bg-green-100 text-green-800',
      'cancelled': 'bg-red-100 text-red-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  const refreshJobMedia = () => {
    loadJobMedia()
    loadJobFiles()
  }

  if (loading) {
    return <div className="p-6">Loading...</div>
  }

  if (!job) {
    return <div className="p-6">Job not found</div>
  }

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-4">
          <Link href="/technician/jobs">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to My Jobs
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Job {job.job_number}</h1>
            <p className="text-muted-foreground">{job.title}</p>
          </div>
          <Badge className={getStatusColor(job.status)}>
            {job.status.replace('_', ' ').toUpperCase()}
          </Badge>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Time Tracking - At the top */}
          <TimeTracking 
            jobId={jobId} 
            userId={userId} 
            userRole="technician"
          />

          {/* Photos & Videos */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Camera className="h-5 w-5" />
                Photos & Videos
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <MediaUpload 
                jobId={jobId} 
                userId={userId} 
                onUploadComplete={refreshJobMedia}
              />
              
              {jobPhotos.length > 0 && (
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {jobPhotos.map((photo, index) => {
                    const isVideo = photo.mime_type?.startsWith('video/')
                    return (
                      <div key={photo.id} className="relative group">
                        <button
                          onClick={() => openPhotoViewer(index)}
                          className="block w-full aspect-square overflow-hidden rounded-lg bg-gray-100 hover:opacity-90 transition-opacity"
                        >
                          {isVideo ? (
                            <div className="w-full h-full flex items-center justify-center bg-gray-200">
                              <Camera className="h-8 w-8 text-gray-500" />
                              <span className="absolute bottom-2 left-2 text-xs bg-black/50 text-white px-2 py-1 rounded">
                                Video
                              </span>
                            </div>
                          ) : (
                            <img 
                              src={photo.photo_url} 
                              alt={photo.caption || 'Job media'}
                              className="w-full h-full object-cover"
                            />
                          )}
                        </button>
                      </div>
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Files */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Job Files
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <FileUpload 
                jobId={jobId} 
                userId={userId} 
                onUploadComplete={refreshJobMedia}
              />
              
              {jobFiles.length > 0 && (
                <div className="space-y-2">
                  {jobFiles.map((file, index) => (
                    <div key={file.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100">
                      <button
                        onClick={() => openFileViewer(index)}
                        className="flex items-center gap-3 flex-1 min-w-0 text-left"
                      >
                        <FileText className="h-5 w-5 text-gray-500 flex-shrink-0" />
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium truncate hover:text-blue-600">
                            {file.file_name}
                          </p>
                          <p className="text-xs text-gray-500">
                            {file.file_size ? `${(file.file_size / 1024 / 1024).toFixed(2)} MB` : 'Unknown size'}
                          </p>
                        </div>
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Notes */}
          <Card>
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Job Notes</CardTitle>
                {!isEditingNotes && (
                  <Button size="sm" variant="outline" onClick={() => setIsEditingNotes(true)}>
                    Edit
                  </Button>
                )}
              </div>
            </CardHeader>
            <CardContent>
              {isEditingNotes ? (
                <div className="space-y-4">
                  <textarea
                    value={notesText}
                    onChange={(e) => setNotesText(e.target.value)}
                    className="w-full h-32 p-3 border rounded-md"
                    placeholder="Enter job notes..."
                  />
                  <div className="flex gap-2">
                    <Button size="sm" onClick={handleSaveNotes}>
                      <Save className="h-4 w-4 mr-2" />
                      Save
                    </Button>
                    <Button 
                      size="sm" 
                      variant="outline" 
                      onClick={() => {
                        setIsEditingNotes(false)
                        setNotesText(job.notes || '')
                      }}
                    >
                      Cancel
                    </Button>
                  </div>
                </div>
              ) : (
                <p className="text-gray-700">
                  {job.notes || 'No notes available. Click edit to add notes.'}
                </p>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Sidebar - Job Details (No financial info) */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground">Customer</p>
                <p className="font-medium">{job.customers?.name || job.customer_name || 'N/A'}</p>
              </div>
              
              {job.customer_phone && (
                <div>
                  <p className="text-sm text-muted-foreground">Phone</p>
                  <a href={`tel:${job.customer_phone}`} className="font-medium text-blue-600 hover:underline flex items-center gap-1">
                    <Phone className="h-4 w-4" />
                    {job.customer_phone}
                  </a>
                </div>
              )}
              
              {job.customer_email && (
                <div>
                  <p className="text-sm text-muted-foreground">Email</p>
                  <a href={`mailto:${job.customer_email}`} className="font-medium text-blue-600 hover:underline flex items-center gap-1">
                    <Mail className="h-4 w-4" />
                    {job.customer_email}
                  </a>
                </div>
              )}
              
              <div>
                <p className="text-sm text-muted-foreground">Job Type</p>
                <p className="font-medium">{job.job_type}</p>
              </div>
              
              <div>
                <p className="text-sm text-muted-foreground">Job Overview</p>
                <p className="font-medium">
                  {job.description || 'No overview available'}
                </p>
              </div>
              
              <div>
                <p className="text-sm text-muted-foreground">Scheduled Date</p>
                <p className="font-medium flex items-center gap-1">
                  <Calendar className="h-4 w-4" />
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              </div>
              
              {job.scheduled_time && (
                <div>
                  <p className="text-sm text-muted-foreground">Scheduled Time</p>
                  <p className="font-medium flex items-center gap-1">
                    <Clock className="h-4 w-4" />
                    {job.scheduled_time}
                  </p>
                </div>
              )}
              
              <div>
                <p className="text-sm text-muted-foreground">Service Address</p>
                <p className="font-medium flex items-center gap-1">
                  <MapPin className="h-4 w-4" />
                  {job.service_address || 'No address specified'}
                </p>
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
