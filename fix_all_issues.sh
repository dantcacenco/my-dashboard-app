#!/bin/bash

# Service Pro - Fix Photos Display & Add Calendar Modal
# This script fixes all issues before committing once

set -e

echo "============================================"
echo "Service Pro - Complete Fix (Photos + Calendar Modal)"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# Step 1: Add debug logging to TechnicianJobView
echo "Adding debug logging to TechnicianJobView..."
cat > "$PROJECT_DIR/app/(authenticated)/technician/jobs/[id]/TechnicianJobView.tsx" << 'EOF'
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
EOF

echo "TechnicianJobView updated with debug logging"

# Step 2: Create JobDetailModal component
echo "Creating JobDetailModal component..."
cat > "$PROJECT_DIR/components/JobDetailModal.tsx" << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Calendar, Clock, MapPin, User, Phone, Mail, DollarSign, Edit, X, Save } from 'lucide-react'
import { toast } from 'sonner'

interface JobDetailModalProps {
  jobId: string
  isOpen: boolean
  onClose: () => void
  onUpdate?: () => void
}

export default function JobDetailModal({ jobId, isOpen, onClose, onUpdate }: JobDetailModalProps) {
  const [job, setJob] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [editedJob, setEditedJob] = useState<any>(null)
  const [technicians, setTechnicians] = useState<any[]>([])
  const supabase = createClient()

  useEffect(() => {
    if (isOpen && jobId) {
      loadJob()
      loadTechnicians()
    }
  }, [isOpen, jobId])

  const loadJob = async () => {
    setLoading(true)
    const { data, error } = await supabase
      .from('jobs')
      .select(`
        *,
        customers (name, email, phone, address),
        profiles!jobs_technician_id_fkey (full_name, email)
      `)
      .eq('id', jobId)
      .single()

    if (error) {
      console.error('Error loading job:', error)
      toast.error('Failed to load job details')
    } else {
      setJob(data)
      setEditedJob(data)
    }
    setLoading(false)
  }

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    setTechnicians(data || [])
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'draft': 'bg-gray-500',
      'sent': 'bg-blue-500',
      'viewed': 'bg-purple-500',
      'approved': 'bg-green-500',
      'rejected': 'bg-red-500',
      'not_scheduled': 'bg-gray-500',
      'scheduled': 'bg-blue-500',
      'in_progress': 'bg-yellow-500',
      'completed': 'bg-green-500',
      'cancelled': 'bg-red-500'
    }
    return colors[status] || 'bg-gray-500'
  }

  const getStatusLabel = (status: string) => {
    return status.replace(/_/g, ' ').toUpperCase()
  }

  const handleSave = async () => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({
          title: editedJob.title,
          description: editedJob.description,
          job_type: editedJob.job_type,
          status: editedJob.status,
          technician_id: editedJob.technician_id,
          scheduled_date: editedJob.scheduled_date,
          scheduled_time: editedJob.scheduled_time,
          notes: editedJob.notes
        })
        .eq('id', jobId)

      if (error) throw error

      toast.success('Job updated successfully')
      setJob(editedJob)
      setIsEditing(false)
      if (onUpdate) onUpdate()
    } catch (error) {
      console.error('Error updating job:', error)
      toast.error('Failed to update job')
    }
  }

  if (loading) {
    return (
      <Dialog open={isOpen} onOpenChange={onClose}>
        <DialogContent className="max-w-3xl">
          <div className="flex items-center justify-center p-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        </DialogContent>
      </Dialog>
    )
  }

  if (!job) return null

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <div className="flex items-center justify-between">
            <DialogTitle className="text-xl font-bold">
              Job {job.job_number}
            </DialogTitle>
            <div className="flex items-center gap-2">
              <Badge className={`${getStatusColor(job.status)} text-white`}>
                {getStatusLabel(job.status)}
              </Badge>
              {!isEditing ? (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setIsEditing(true)}
                >
                  <Edit className="h-4 w-4 mr-1" />
                  Edit
                </Button>
              ) : (
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      setEditedJob(job)
                      setIsEditing(false)
                    }}
                  >
                    <X className="h-4 w-4 mr-1" />
                    Cancel
                  </Button>
                  <Button
                    size="sm"
                    onClick={handleSave}
                  >
                    <Save className="h-4 w-4 mr-1" />
                    Save
                  </Button>
                </div>
              )}
            </div>
          </div>
        </DialogHeader>

        <div className="space-y-6 mt-4">
          {/* Job Title & Type */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Job Title</Label>
              {isEditing ? (
                <Input
                  value={editedJob.title}
                  onChange={(e) => setEditedJob({...editedJob, title: e.target.value})}
                />
              ) : (
                <p className="font-medium">{job.title}</p>
              )}
            </div>
            <div>
              <Label>Job Type</Label>
              {isEditing ? (
                <Select
                  value={editedJob.job_type}
                  onValueChange={(value) => setEditedJob({...editedJob, job_type: value})}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="installation">Installation</SelectItem>
                    <SelectItem value="maintenance">Maintenance</SelectItem>
                    <SelectItem value="repair">Repair</SelectItem>
                    <SelectItem value="inspection">Inspection</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <p className="font-medium capitalize">{job.job_type}</p>
              )}
            </div>
          </div>

          {/* Customer Info */}
          <div>
            <Label>Customer</Label>
            <div className="bg-gray-50 p-3 rounded-lg space-y-1">
              <p className="font-medium">{job.customers?.name}</p>
              {job.customers?.phone && (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <Phone className="h-3 w-3" />
                  {job.customers.phone}
                </p>
              )}
              {job.customers?.email && (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <Mail className="h-3 w-3" />
                  {job.customers.email}
                </p>
              )}
              {job.customers?.address && (
                <p className="text-sm text-muted-foreground flex items-center gap-1">
                  <MapPin className="h-3 w-3" />
                  {job.customers.address}
                </p>
              )}
            </div>
          </div>

          {/* Scheduling */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Scheduled Date</Label>
              {isEditing ? (
                <Input
                  type="date"
                  value={editedJob.scheduled_date || ''}
                  onChange={(e) => setEditedJob({...editedJob, scheduled_date: e.target.value})}
                />
              ) : (
                <p className="font-medium flex items-center gap-1">
                  <Calendar className="h-4 w-4" />
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              )}
            </div>
            <div>
              <Label>Scheduled Time</Label>
              {isEditing ? (
                <Input
                  type="time"
                  value={editedJob.scheduled_time || ''}
                  onChange={(e) => setEditedJob({...editedJob, scheduled_time: e.target.value})}
                />
              ) : (
                <p className="font-medium flex items-center gap-1">
                  <Clock className="h-4 w-4" />
                  {job.scheduled_time || 'Not set'}
                </p>
              )}
            </div>
          </div>

          {/* Status & Technician */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Status</Label>
              {isEditing ? (
                <Select
                  value={editedJob.status}
                  onValueChange={(value) => setEditedJob({...editedJob, status: value})}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="not_scheduled">Not Scheduled</SelectItem>
                    <SelectItem value="scheduled">Scheduled</SelectItem>
                    <SelectItem value="in_progress">In Progress</SelectItem>
                    <SelectItem value="completed">Completed</SelectItem>
                    <SelectItem value="cancelled">Cancelled</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <Badge className={`${getStatusColor(job.status)} text-white`}>
                  {getStatusLabel(job.status)}
                </Badge>
              )}
            </div>
            <div>
              <Label>Assigned Technician</Label>
              {isEditing ? (
                <Select
                  value={editedJob.technician_id || ''}
                  onValueChange={(value) => setEditedJob({...editedJob, technician_id: value})}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select technician" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">Unassigned</SelectItem>
                    {technicians.map((tech) => (
                      <SelectItem key={tech.id} value={tech.id}>
                        {tech.full_name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <p className="font-medium flex items-center gap-1">
                  <User className="h-4 w-4" />
                  {job.profiles?.full_name || 'Unassigned'}
                </p>
              )}
            </div>
          </div>

          {/* Description */}
          <div>
            <Label>Description</Label>
            {isEditing ? (
              <Textarea
                value={editedJob.description || ''}
                onChange={(e) => setEditedJob({...editedJob, description: e.target.value})}
                rows={3}
              />
            ) : (
              <p className="text-sm text-muted-foreground">
                {job.description || 'No description provided'}
              </p>
            )}
          </div>

          {/* Notes */}
          <div>
            <Label>Notes</Label>
            {isEditing ? (
              <Textarea
                value={editedJob.notes || ''}
                onChange={(e) => setEditedJob({...editedJob, notes: e.target.value})}
                rows={3}
                placeholder="Add notes..."
              />
            ) : (
              <div className="bg-gray-50 p-3 rounded-lg">
                <p className="text-sm whitespace-pre-wrap">
                  {job.notes || 'No notes'}
                </p>
              </div>
            )}
          </div>

          {/* Financial Info */}
          <div>
            <Label>Total Amount</Label>
            <p className="font-medium text-lg flex items-center gap-1">
              <DollarSign className="h-4 w-4" />
              {job.total_amount ? `$${job.total_amount.toFixed(2)}` : 'N/A'}
            </p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
EOF

echo "JobDetailModal component created"

# Step 3: Update CalendarView to use modal and fix status colors
echo "Updating CalendarView with modal and consistent status colors..."
cat > "$PROJECT_DIR/components/CalendarView.tsx" << 'EOF'
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
EOF

echo "CalendarView updated with modal and consistent status colors"

# Step 4: Test the build
echo ""
echo "Testing build..."
npm run build 2>&1 | head -100

# Step 5: If build succeeds, commit all changes
if [ $? -eq 0 ]; then
  echo ""
  echo "Build successful! Committing all changes..."
  git add -A
  git commit -m "Fix photo display debug, add calendar job modal, unify status colors"
  git push origin main
  
  echo ""
  echo "============================================"
  echo "SUCCESS! All changes committed and pushed"
  echo "============================================"
  echo ""
  echo "CHANGES MADE:"
  echo "1. Added debug logging to TechnicianJobView to troubleshoot photo display"
  echo "2. Created JobDetailModal component for viewing/editing jobs from calendar"
  echo "3. Updated CalendarView to use modal instead of navigation"
  echo "4. Unified status colors across proposals, jobs, and calendar"
  echo ""
  echo "TO TEST:"
  echo "1. Open browser console (F12) and go to technician portal"
  echo "2. Check console for photo URL debug messages"
  echo "3. Test calendar - click on jobs to open modal"
  echo "4. Verify status colors are consistent everywhere"
  echo ""
  echo "CONSOLE OUTPUT TO LOOK FOR:"
  echo "- 'Loading job media for job: [id]'"
  echo "- 'Photo X URL: [url]'"
  echo "- 'Photo X loaded successfully' or error messages"
  echo ""
  echo "If photos still don't show, check console for:"
  echo "- CORS errors"
  echo "- 404 errors on image URLs"
  echo "- Network tab to see actual response"
  echo "============================================"
else
  echo ""
  echo "Build failed! Check errors above."
  echo "No changes were committed."
fi
