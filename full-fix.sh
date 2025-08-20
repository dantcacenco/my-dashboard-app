#!/bin/bash

set -e

echo "🔧 Fixing multiple issues: bucket name, video support, layout, and proposal linking..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Update FileUpload to use correct bucket name 'job-files'
cat > components/uploads/FileUpload.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { FileText, Upload, X, Loader2, Music, Image, FileVideo, File } from 'lucide-react'
import { toast } from 'sonner'

interface FileUploadProps {
  jobId: string
  userId: string
  onUploadComplete?: () => void
}

export default function FileUpload({ jobId, userId, onUploadComplete }: FileUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const supabase = createClient()

  const getFileIcon = (mimeType: string) => {
    if (mimeType.startsWith('image/')) return Image
    if (mimeType.startsWith('audio/')) return Music
    if (mimeType.startsWith('video/')) return FileVideo
    if (mimeType === 'application/pdf') return FileText
    return File
  }

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    
    const validFiles = files.filter(file => {
      if (file.size > 50 * 1024 * 1024) { // 50MB limit
        toast.error(`${file.name} is too large (${(file.size / 1024 / 1024).toFixed(1)}MB). Max size is 50MB.`)
        return false
      }
      return true
    })

    setSelectedFiles(validFiles)
  }

  const uploadFile = async (file: File) => {
    try {
      const fileExt = file.name.split('.').pop()
      const fileName = `${jobId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`

      // Upload to correct bucket name: 'job-files' (with hyphen)
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('job-files')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('job-files')
        .getPublicUrl(fileName)

      const { error: dbError } = await supabase
        .from('job_files')
        .insert({
          job_id: jobId,
          uploaded_by: userId,
          file_name: file.name,
          file_url: publicUrl,
          file_size: file.size,
          mime_type: file.type || 'application/octet-stream'
        })

      if (dbError) throw dbError

      return { success: true, url: publicUrl }
    } catch (error) {
      console.error('Upload error:', error)
      return { success: false, error }
    }
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast.error('Please select files to upload')
      return
    }

    setIsUploading(true)
    let successCount = 0
    let errorCount = 0

    for (const file of selectedFiles) {
      const result = await uploadFile(file)
      if (result.success) {
        successCount++
      } else {
        errorCount++
      }
    }

    setIsUploading(false)
    setSelectedFiles([])

    if (successCount > 0) {
      toast.success(`${successCount} file(s) uploaded successfully`)
      onUploadComplete?.()
    }
    
    if (errorCount > 0) {
      toast.error(`${errorCount} file(s) failed to upload`)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
  }

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    const files = Array.from(e.dataTransfer.files)
    const input = { target: { files } } as any
    handleFileSelect(input)
  }

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  return (
    <div className="bg-white rounded-lg border p-4">
      <h3 className="font-medium mb-3 flex items-center gap-2">
        <FileText className="h-5 w-5" />
        Upload Files
      </h3>

      <div className="mb-4">
        <label className="block w-full cursor-pointer">
          <div 
            className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 transition-colors"
            onDrop={handleDrop}
            onDragOver={handleDragOver}
          >
            <Upload className="h-8 w-8 mx-auto mb-2 text-gray-400" />
            <p className="text-sm text-gray-600">
              Click to select files or drag and drop
            </p>
            <p className="text-xs text-gray-500 mt-1">
              PDFs, documents, audio files, etc. (max 50MB each)
            </p>
          </div>
          <input
            type="file"
            multiple
            onChange={handleFileSelect}
            className="hidden"
            disabled={isUploading}
            accept="*/*"
          />
        </label>
      </div>

      {selectedFiles.length > 0 && (
        <div className="mb-4">
          <div className="space-y-2">
            {selectedFiles.map((file, index) => {
              const Icon = getFileIcon(file.type)
              return (
                <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                  <div className="flex items-center gap-2 flex-1 min-w-0">
                    <Icon className="h-4 w-4 text-gray-500 flex-shrink-0" />
                    <span className="text-sm truncate">{file.name}</span>
                    <span className="text-xs text-gray-500">
                      ({formatFileSize(file.size)})
                    </span>
                  </div>
                  <button
                    onClick={() => removeFile(index)}
                    className="text-red-500 hover:text-red-700 p-1"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              )
            })}
          </div>
          <p className="text-sm text-gray-600 mt-2">
            {selectedFiles.length} file(s) selected
          </p>
        </div>
      )}

      {selectedFiles.length > 0 && (
        <button
          onClick={handleUpload}
          disabled={isUploading}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center justify-center gap-2"
        >
          {isUploading ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" />
              Uploading...
            </>
          ) : (
            <>
              <Upload className="h-4 w-4" />
              Upload {selectedFiles.length} File(s)
            </>
          )}
        </button>
      )}
    </div>
  )
}
EOF

echo "✅ Fixed FileUpload with correct bucket name"

# 2. Create MediaUpload component that handles both photos and videos
cat > components/uploads/MediaUpload.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Camera, Upload, X, Loader2, Video, AlertCircle } from 'lucide-react'
import { toast } from 'sonner'

interface MediaUploadProps {
  jobId: string
  userId: string
  onUploadComplete?: () => void
}

export default function MediaUpload({ jobId, userId, onUploadComplete }: MediaUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [previews, setPreviews] = useState<string[]>([])
  const supabase = createClient()

  const MAX_SIZE = 50 * 1024 * 1024 // 50MB

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    
    const validFiles = files.filter(file => {
      const isImage = file.type.startsWith('image/')
      const isVideo = file.type.startsWith('video/')
      
      if (!isImage && !isVideo) {
        toast.error(`${file.name} is not a valid media file (images or videos only)`)
        return false
      }
      
      if (file.size > MAX_SIZE) {
        const sizeMB = (file.size / 1024 / 1024).toFixed(1)
        toast.error(
          `${file.name} is ${sizeMB}MB (max 50MB). ${
            isVideo ? 'Try reducing video quality or duration.' : ''
          }`
        )
        return false
      }
      
      return true
    })

    setSelectedFiles(validFiles)
    
    // Create previews for images only
    const newPreviews: string[] = []
    validFiles.forEach(file => {
      if (file.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onloadend = () => {
          newPreviews.push(reader.result as string)
          if (newPreviews.length === validFiles.filter(f => f.type.startsWith('image/')).length) {
            setPreviews(newPreviews)
          }
        }
        reader.readAsDataURL(file)
      }
    })
  }

  const uploadMedia = async (file: File) => {
    try {
      const fileExt = file.name.split('.').pop()
      const fileName = `${jobId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('job-photos')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('job-photos')
        .getPublicUrl(fileName)

      const { error: dbError } = await supabase
        .from('job_photos')
        .insert({
          job_id: jobId,
          uploaded_by: userId,
          photo_url: publicUrl,
          caption: file.name,
          file_size_bytes: file.size,
          mime_type: file.type
        })

      if (dbError) throw dbError

      return { success: true, url: publicUrl }
    } catch (error) {
      console.error('Upload error:', error)
      return { success: false, error }
    }
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast.error('Please select photos or videos to upload')
      return
    }

    setIsUploading(true)
    let successCount = 0
    let errorCount = 0

    for (const file of selectedFiles) {
      const result = await uploadMedia(file)
      if (result.success) {
        successCount++
      } else {
        errorCount++
      }
    }

    setIsUploading(false)
    setSelectedFiles([])
    setPreviews([])

    if (successCount > 0) {
      toast.success(`${successCount} media file(s) uploaded successfully`)
      onUploadComplete?.()
    }
    
    if (errorCount > 0) {
      toast.error(`${errorCount} media file(s) failed to upload`)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
    setPreviews(prev => prev.filter((_, i) => i !== index))
  }

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    const files = Array.from(e.dataTransfer.files)
    const input = { target: { files } } as any
    handleFileSelect(input)
  }

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault()
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  return (
    <div className="bg-white rounded-lg border p-4">
      <h3 className="font-medium mb-3 flex items-center gap-2">
        <Camera className="h-5 w-5" />
        Upload Photos & Videos
      </h3>

      <div className="mb-4">
        <label className="block w-full cursor-pointer">
          <div 
            className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 transition-colors"
            onDrop={handleDrop}
            onDragOver={handleDragOver}
          >
            <div className="flex justify-center gap-2 mb-2">
              <Camera className="h-8 w-8 text-gray-400" />
              <Video className="h-8 w-8 text-gray-400" />
            </div>
            <p className="text-sm text-gray-600">
              Click to select photos/videos or drag and drop
            </p>
            <p className="text-xs text-gray-500 mt-1">
              JPG, PNG, GIF, WebP, MP4, MOV (max 50MB each)
            </p>
          </div>
          <input
            type="file"
            multiple
            accept="image/*,video/*"
            onChange={handleFileSelect}
            className="hidden"
            disabled={isUploading}
          />
        </label>
      </div>

      {selectedFiles.length > 0 && (
        <div className="mb-4">
          <div className="grid grid-cols-3 gap-2">
            {selectedFiles.map((file, index) => {
              const isVideo = file.type.startsWith('video/')
              const preview = !isVideo && previews[index]
              
              return (
                <div key={index} className="relative group">
                  {preview ? (
                    <img
                      src={preview}
                      alt={`Preview ${index + 1}`}
                      className="w-full h-24 object-cover rounded"
                    />
                  ) : (
                    <div className="w-full h-24 bg-gray-100 rounded flex flex-col items-center justify-center">
                      <Video className="h-8 w-8 text-gray-400" />
                      <span className="text-xs text-gray-500 mt-1 px-1 truncate w-full text-center">
                        {file.name}
                      </span>
                    </div>
                  )}
                  <span className="absolute bottom-1 left-1 text-xs bg-black/50 text-white px-1 rounded">
                    {formatFileSize(file.size)}
                  </span>
                  <button
                    onClick={() => removeFile(index)}
                    className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </div>
              )
            })}
          </div>
          <p className="text-sm text-gray-600 mt-2">
            {selectedFiles.length} file(s) selected
          </p>
        </div>
      )}

      <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 mb-4">
        <div className="flex gap-2">
          <AlertCircle className="h-5 w-5 text-blue-600 flex-shrink-0" />
          <div className="text-xs text-blue-800">
            <p className="font-semibold">Size Limits:</p>
            <p>• Maximum file size: 50MB per file</p>
            <p>• For large videos, consider recording at 1080p or lower</p>
            <p>• Shorter videos upload faster and use less storage</p>
          </div>
        </div>
      </div>

      {selectedFiles.length > 0 && (
        <button
          onClick={handleUpload}
          disabled={isUploading}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center justify-center gap-2"
        >
          {isUploading ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" />
              Uploading...
            </>
          ) : (
            <>
              <Upload className="h-4 w-4" />
              Upload {selectedFiles.length} Media File(s)
            </>
          )}
        </button>
      )}
    </div>
  )
}
EOF

echo "✅ Created MediaUpload component with video support"
EOF
#!/bin/bash

set -e

echo "🔧 Part 2: Redesigning JobDetailView layout and fixing proposal linking..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 3. Create new JobDetailView with no tabs, everything in one page
cat > app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  ArrowLeft, Edit, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Plus, X, Save, Trash2,
  DollarSign, Link as LinkIcon, FileCheck
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import MediaUpload from '@/components/uploads/MediaUpload'
import FileUpload from '@/components/uploads/FileUpload'
import MediaViewer from '@/components/MediaViewer'

interface JobDetailViewProps {
  job: any
  userRole: string
  userId?: string
}

export default function JobDetailView({ job: initialJob, userRole, userId }: JobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [isEditingNotes, setIsEditingNotes] = useState(false)
  const [notesText, setNotesText] = useState(job.notes || '')
  const [showEditModal, setShowEditModal] = useState(false)
  const [technicians, setTechnicians] = useState<any[]>([])
  const [assignedTechnicians, setAssignedTechnicians] = useState<any[]>([])
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [currentUserId, setCurrentUserId] = useState(userId)
  const [viewerOpen, setViewerOpen] = useState(false)
  const [viewerItems, setViewerItems] = useState<any[]>([])
  const [viewerIndex, setViewerIndex] = useState(0)
  const [proposal, setProposal] = useState<any>(null)

  useEffect(() => {
    loadTechnicians()
    loadAssignedTechnicians()
    loadJobMedia()
    loadJobFiles()
    loadProposal()
    if (!userId) {
      getCurrentUser()
    }
  }, [job.id])

  const getCurrentUser = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      setCurrentUserId(user.id)
    }
  }

  const loadProposal = async () => {
    if (job.proposal_id) {
      const { data } = await supabase
        .from('proposals')
        .select('*')
        .eq('id', job.proposal_id)
        .single()
      
      if (data) {
        setProposal(data)
        // Update job with proposal amounts if not set
        if (!job.total_amount && data.total) {
          setJob(prev => ({ ...prev, total_amount: data.total }))
        }
      }
    }
  }

  const loadTechnicians = async () => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
      .eq('is_active', true)
    
    setTechnicians(data || [])
  }

  const loadAssignedTechnicians = async () => {
    const { data } = await supabase
      .from('job_technicians')
      .select('*, profiles!technician_id(*)')
      .eq('job_id', job.id)
    
    setAssignedTechnicians(data || [])
  }

  const loadJobMedia = async () => {
    const { data } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
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

  const handleSaveNotes = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ notes: notesText })
      .eq('id', job.id)

    if (!error) {
      setJob({ ...job, notes: notesText })
      setIsEditingNotes(false)
      toast.success('Notes updated')
    } else {
      toast.error('Failed to update notes')
    }
  }

  const handleAddTechnician = async (technicianId: string) => {
    const { error } = await supabase
      .from('job_technicians')
      .insert({
        job_id: job.id,
        technician_id: technicianId
      })

    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician added')
    } else {
      toast.error('Failed to add technician')
    }
  }

  const handleRemoveTechnician = async (assignmentId: string) => {
    const { error } = await supabase
      .from('job_technicians')
      .delete()
      .eq('id', assignmentId)

    if (!error) {
      loadAssignedTechnicians()
      toast.success('Technician removed')
    } else {
      toast.error('Failed to remove technician')
    }
  }

  const deletePhoto = async (photoId: string) => {
    if (!confirm('Are you sure you want to delete this photo?')) return

    const { error } = await supabase
      .from('job_photos')
      .delete()
      .eq('id', photoId)

    if (!error) {
      setJobPhotos(prev => prev.filter(p => p.id !== photoId))
      toast.success('Photo deleted')
    } else {
      toast.error('Failed to delete photo')
    }
  }

  const deleteFile = async (fileId: string) => {
    if (!confirm('Are you sure you want to delete this file?')) return

    const { error } = await supabase
      .from('job_files')
      .delete()
      .eq('id', fileId)

    if (!error) {
      setJobFiles(prev => prev.filter(f => f.id !== fileId))
      toast.success('File deleted')
    } else {
      toast.error('Failed to delete file')
    }
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

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-4">
          <Link href="/jobs">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Jobs
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
        <Button onClick={() => setShowEditModal(true)}>
          <Edit className="h-4 w-4 mr-2" />
          Edit Job
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content - Left Side */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Technicians Card */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Assigned Technicians
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <select
                  onChange={(e) => e.target.value && handleAddTechnician(e.target.value)}
                  className="w-full p-2 border rounded-md"
                  defaultValue=""
                >
                  <option value="">Add a technician...</option>
                  {technicians
                    .filter(t => !assignedTechnicians.find(at => at.technician_id === t.id))
                    .map(tech => (
                      <option key={tech.id} value={tech.id}>
                        {tech.full_name || tech.email}
                      </option>
                    ))}
                </select>
              </div>
              
              <div className="space-y-2">
                {assignedTechnicians.map((assignment) => (
                  <div key={assignment.id} className="flex items-center justify-between p-3 border rounded-md">
                    <div className="flex items-center gap-2">
                      <User className="h-4 w-4 text-gray-500" />
                      <span>{assignment.profiles?.full_name || assignment.profiles?.email}</span>
                    </div>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => handleRemoveTechnician(assignment.id)}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
                {assignedTechnicians.length === 0 && (
                  <p className="text-gray-500 text-center py-4">
                    No technicians assigned
                  </p>
                )}
              </div>
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
            <CardContent className="space-y-4">
              {currentUserId && (
                <MediaUpload 
                  jobId={job.id} 
                  userId={currentUserId} 
                  onUploadComplete={refreshJobMedia}
                />
              )}
              
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
                        <button
                          onClick={() => deletePhoto(photo.id)}
                          className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </div>
                    )
                  })}
                </div>
              )}
              
              {jobPhotos.length === 0 && (
                <p className="text-gray-500 text-center py-8">
                  No photos or videos uploaded yet
                </p>
              )}
            </CardContent>
          </Card>

          {/* Files Card */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Job Files
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {currentUserId && (
                <FileUpload 
                  jobId={job.id} 
                  userId={currentUserId} 
                  onUploadComplete={refreshJobMedia}
                />
              )}
              
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
                      <button
                        onClick={() => deleteFile(file.id)}
                        className="text-red-500 hover:text-red-700 p-2"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
              
              {jobFiles.length === 0 && (
                <p className="text-gray-500 text-center py-8">
                  No files uploaded yet
                </p>
              )}
            </CardContent>
          </Card>

          {/* Notes Card */}
          <Card>
            <CardHeader>
              <div className="flex justify-between items-center">
                <CardTitle>Job Notes</CardTitle>
                {!isEditingNotes && (
                  <Button size="sm" variant="outline" onClick={() => setIsEditingNotes(true)}>
                    <Edit className="h-4 w-4" />
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

        {/* Sidebar - Right Side */}
        <div className="space-y-6">
          {/* Job Details Card */}
          <Card>
            <CardHeader>
              <CardTitle>Job Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted-foreground">Customer</p>
                <p className="font-medium">{job.customers?.name || job.customer_name || 'N/A'}</p>
              </div>
              
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
                <p className="font-medium">
                  {job.scheduled_date ? new Date(job.scheduled_date).toLocaleDateString() : 'Not scheduled'}
                </p>
              </div>
              
              <div>
                <p className="text-sm text-muted-foreground">Service Address</p>
                <p className="font-medium">
                  {job.service_address || 'No address specified'}
                </p>
              </div>

              {/* Financial Information */}
              {userRole === 'boss' && (
                <>
                  <div className="pt-4 border-t">
                    <p className="text-sm text-muted-foreground flex items-center gap-1">
                      <DollarSign className="h-4 w-4" />
                      Total Amount
                    </p>
                    <p className="font-medium text-lg">
                      ${job.total_amount ? job.total_amount.toFixed(2) : proposal?.total?.toFixed(2) || '0.00'}
                    </p>
                  </div>
                  
                  <div>
                    <p className="text-sm text-muted-foreground flex items-center gap-1">
                      <DollarSign className="h-4 w-4" />
                      Amount Paid
                    </p>
                    <p className="font-medium text-lg text-green-600">
                      ${job.amount_paid ? job.amount_paid.toFixed(2) : '0.00'}
                    </p>
                  </div>
                  
                  <div>
                    <p className="text-sm text-muted-foreground">Balance Due</p>
                    <p className="font-medium text-lg text-orange-600">
                      ${((job.total_amount || proposal?.total || 0) - (job.amount_paid || 0)).toFixed(2)}
                    </p>
                  </div>

                  {/* Linked Proposal */}
                  {proposal && (
                    <div className="pt-4 border-t">
                      <p className="text-sm text-muted-foreground flex items-center gap-1">
                        <LinkIcon className="h-4 w-4" />
                        Linked Proposal
                      </p>
                      <Link href={`/proposals/${proposal.id}`}>
                        <p className="font-medium text-blue-600 hover:underline">
                          {proposal.proposal_number} - {proposal.title}
                        </p>
                      </Link>
                    </div>
                  )}
                </>
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

      {/* Edit Job Modal */}
      {showEditModal && (
        <EditJobModal 
          job={job}
          isOpen={showEditModal}
          onClose={() => setShowEditModal(false)}
          onJobUpdated={() => {
            setShowEditModal(false)
            router.refresh()
          }}
        />
      )}
    </div>
  )
}

// Import EditJobModal component
import { EditJobModal } from './EditJobModal'
EOF

echo "✅ Redesigned JobDetailView layout"

# Clean up
rm -f fix-file-bucket.sh
rm -f add-media-viewer.sh

# Commit all changes
git add -A
git commit -m "Major fixes: bucket name, video support, layout redesign, proposal linking

- Fixed file upload to use correct bucket 'job-files'
- Created MediaUpload component supporting photos AND videos
- Redesigned JobDetailView: removed tabs, all content in one page
- Job overview now inside Job Details card
- Fixed proposal linking and amount display
- Shows linked proposal and calculates balance due
- Added file size warnings and tips for videos
- All media types now supported with appropriate icons"

git push origin main

echo ""
echo "✅ ALL FIXES COMPLETE!"
echo ""
echo "Changes made:"
echo "• File uploads now use correct bucket 'job-files'"
echo "• Photos section now accepts videos too (renamed to Photos & Videos)"
echo "• Removed tabs - everything displays in cards on one page"
echo "• Job overview moved inside Job Details card"
echo "• Fixed proposal linking and amount display"
echo "• Shows balance due calculation"
echo "• File size warnings for large uploads"
echo ""
echo "📋 Note about file sizes:"
echo "• 50MB limit is set by Supabase free tier"
echo "• To increase: upgrade Supabase plan for larger limits"
echo "• For videos: users should record at 1080p or lower for smaller files"
EOF
