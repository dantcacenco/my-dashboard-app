#!/bin/bash

set -e

echo "🔧 Fixing PhotoUpload title and creating FileUpload debug mode..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First, fix PhotoUpload to remove debug references in title
echo "Fixing PhotoUpload component title..."
sed -i '' 's/Upload Photos (Debug Mode)/Upload Photos/g' app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx

# Create FileUploadDebug component
cat > components/uploads/FileUploadDebug.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { FileText, Upload, X, Loader2 } from 'lucide-react'
import { toast } from 'sonner'

interface FileUploadProps {
  jobId: string
  userId: string
  onUploadComplete?: () => void
}

export default function FileUploadDebug({ jobId, userId, onUploadComplete }: FileUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [debugLog, setDebugLog] = useState<string[]>([])
  const supabase = createClient()

  const addLog = (message: string) => {
    console.log(`[FileUpload] ${message}`)
    setDebugLog(prev => [...prev, `${new Date().toLocaleTimeString()}: ${message}`])
  }

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    addLog(`Selected ${files.length} file(s)`)
    
    // Validate file sizes
    const validFiles = files.filter(file => {
      if (file.size > 50 * 1024 * 1024) { // 50MB limit
        const msg = `${file.name} is too large (${(file.size / 1024 / 1024).toFixed(2)}MB, max 50MB)`
        addLog(msg)
        toast.error(msg)
        return false
      }
      addLog(`${file.name} is valid (${(file.size / 1024).toFixed(0)}KB, ${file.type || 'no type'})`)
      return true
    })

    setSelectedFiles(validFiles)
  }

  const uploadFile = async (file: File) => {
    try {
      addLog(`Starting upload for ${file.name}`)
      
      // Check auth
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        addLog('ERROR: No authenticated user')
        throw new Error('Not authenticated')
      }
      addLog(`User authenticated: ${user.id}`)
      
      // Generate unique filename
      const fileExt = file.name.split('.').pop()
      const fileName = `${jobId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`
      addLog(`Generated filename: ${fileName}`)

      // Upload to Supabase Storage
      addLog('Uploading to storage bucket: job-files')
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('job-files')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) {
        addLog(`Storage upload error: ${JSON.stringify(uploadError)}`)
        throw uploadError
      }
      addLog(`File uploaded successfully to storage`)

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('job-files')
        .getPublicUrl(fileName)
      addLog(`Public URL: ${publicUrl}`)

      // Save to database
      addLog('Saving to database table: job_files')
      const insertData = {
        job_id: jobId,
        uploaded_by: userId,
        file_name: file.name,
        file_url: publicUrl,
        file_size: file.size,
        mime_type: file.type || 'application/octet-stream'
      }
      addLog(`Insert data: ${JSON.stringify(insertData)}`)
      
      const { data: dbData, error: dbError } = await supabase
        .from('job_files')
        .insert(insertData)
        .select()

      if (dbError) {
        addLog(`Database error: ${JSON.stringify(dbError)}`)
        throw dbError
      }
      
      addLog(`Database insert successful: ${JSON.stringify(dbData)}`)
      return { success: true, url: publicUrl }
    } catch (error: any) {
      addLog(`UPLOAD FAILED: ${error.message || JSON.stringify(error)}`)
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
    addLog(`Starting upload of ${selectedFiles.length} file(s)`)
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
      const msg = `${successCount} file(s) uploaded successfully`
      addLog(msg)
      toast.success(msg)
      onUploadComplete?.()
    }
    
    if (errorCount > 0) {
      const msg = `${errorCount} file(s) failed to upload`
      addLog(msg)
      toast.error(msg)
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

  return (
    <div className="bg-white rounded-lg border p-4">
      <h3 className="font-medium mb-3 flex items-center gap-2">
        <FileText className="h-5 w-5" />
        Upload Files (Debug Mode)
      </h3>

      {/* Debug Info */}
      <div className="mb-4 p-2 bg-gray-100 rounded text-xs">
        <div>Job ID: {jobId}</div>
        <div>User ID: {userId}</div>
      </div>

      {/* File Input */}
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
              Any file type (max 50MB each)
            </p>
          </div>
          <input
            type="file"
            multiple
            onChange={handleFileSelect}
            className="hidden"
            disabled={isUploading}
          />
        </label>
      </div>

      {/* Selected Files */}
      {selectedFiles.length > 0 && (
        <div className="mb-4">
          <div className="space-y-2">
            {selectedFiles.map((file, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                <div className="flex items-center gap-2 flex-1 min-w-0">
                  <FileText className="h-4 w-4 text-gray-500 flex-shrink-0" />
                  <span className="text-sm truncate">{file.name}</span>
                  <span className="text-xs text-gray-500">
                    ({(file.size / 1024).toFixed(0)} KB)
                  </span>
                </div>
                <button
                  onClick={() => removeFile(index)}
                  className="text-red-500 hover:text-red-700 p-1"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>
          <p className="text-sm text-gray-600 mt-2">
            {selectedFiles.length} file(s) selected
          </p>
        </div>
      )}

      {/* Upload Button */}
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

      {/* Debug Log */}
      {debugLog.length > 0 && (
        <div className="mt-4 p-2 bg-black text-green-400 rounded text-xs font-mono max-h-40 overflow-y-auto">
          {debugLog.map((log, i) => (
            <div key={i}>{log}</div>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

echo "✅ Created FileUploadDebug component"

# Update JobDetailView to use FileUploadDebug
cat > app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  ArrowLeft, Edit, Calendar, Clock, MapPin, User, 
  FileText, Camera, Upload, Plus, X, Save, Trash2 
} from 'lucide-react'
import Link from 'next/link'
import { toast } from 'sonner'
import PhotoUpload from '@/components/uploads/PhotoUpload'
import FileUploadDebug from '@/components/uploads/FileUploadDebug'

interface JobDetailViewProps {
  job: any
  userRole: string
  userId?: string
}

export default function JobDetailView({ job: initialJob, userRole, userId }: JobDetailViewProps) {
  const router = useRouter()
  const supabase = createClient()
  const [job, setJob] = useState(initialJob)
  const [isEditingOverview, setIsEditingOverview] = useState(false)
  const [overviewText, setOverviewText] = useState(job.description || '')
  const [isEditingNotes, setIsEditingNotes] = useState(false)
  const [notesText, setNotesText] = useState(job.notes || '')
  const [showEditModal, setShowEditModal] = useState(false)
  const [technicians, setTechnicians] = useState<any[]>([])
  const [assignedTechnicians, setAssignedTechnicians] = useState<any[]>([])
  const [jobPhotos, setJobPhotos] = useState<any[]>([])
  const [jobFiles, setJobFiles] = useState<any[]>([])
  const [currentUserId, setCurrentUserId] = useState(userId)

  useEffect(() => {
    loadTechnicians()
    loadAssignedTechnicians()
    loadJobPhotos()
    loadJobFiles()
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

  const loadJobPhotos = async () => {
    const { data, error } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    if (error) {
      console.error('[JobDetailView] Error loading photos:', error)
    }
    
    setJobPhotos(data || [])
  }

  const loadJobFiles = async () => {
    const { data, error } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', job.id)
      .order('created_at', { ascending: false })
    
    if (error) {
      console.error('[JobDetailView] Error loading files:', error)
    }
    
    setJobFiles(data || [])
  }

  const handleSaveOverview = async () => {
    const { error } = await supabase
      .from('jobs')
      .update({ description: overviewText })
      .eq('id', job.id)

    if (!error) {
      setJob({ ...job, description: overviewText })
      setIsEditingOverview(false)
      toast.success('Overview updated')
    } else {
      toast.error('Failed to update overview')
    }
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
    loadJobPhotos()
    loadJobFiles()
  }

  return (
    <div className="p-6">
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
        <div className="lg:col-span-2">
          <Tabs defaultValue="overview" className="w-full">
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="overview">Overview</TabsTrigger>
              <TabsTrigger value="technicians">Technicians</TabsTrigger>
              <TabsTrigger value="photos">Photos</TabsTrigger>
              <TabsTrigger value="files">Files</TabsTrigger>
              <TabsTrigger value="notes">Notes</TabsTrigger>
            </TabsList>
            <TabsContent value="overview">
              <Card>
                <CardHeader>
                  <div className="flex justify-between items-center">
                    <CardTitle>Job Overview</CardTitle>
                    {!isEditingOverview && (
                      <Button size="sm" variant="outline" onClick={() => setIsEditingOverview(true)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  {isEditingOverview ? (
                    <div className="space-y-4">
                      <textarea
                        value={overviewText}
                        onChange={(e) => setOverviewText(e.target.value)}
                        className="w-full h-32 p-3 border rounded-md"
                        placeholder="Enter job overview..."
                      />
                      <div className="flex gap-2">
                        <Button size="sm" onClick={handleSaveOverview}>
                          <Save className="h-4 w-4 mr-2" />
                          Save
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={() => {
                            setIsEditingOverview(false)
                            setOverviewText(job.description || '')
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <p className="text-gray-700">
                      {job.description || 'No overview available. Click edit to add an overview.'}
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="technicians">
              <Card>
                <CardHeader>
                  <CardTitle>Assigned Technicians</CardTitle>
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
            </TabsContent>

            <TabsContent value="photos">
              <Card>
                <CardHeader>
                  <CardTitle>Job Photos</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  {currentUserId && (
                    <PhotoUpload 
                      jobId={job.id} 
                      userId={currentUserId} 
                      onUploadComplete={refreshJobMedia}
                    />
                  )}
                  
                  {jobPhotos.length > 0 && (
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                      {jobPhotos.map((photo) => (
                        <div key={photo.id} className="relative group">
                          <a 
                            href={photo.photo_url} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="block aspect-square overflow-hidden rounded-lg bg-gray-100"
                          >
                            <img 
                              src={photo.photo_url} 
                              alt={photo.caption || 'Job photo'}
                              className="w-full h-full object-cover hover:scale-105 transition-transform"
                            />
                          </a>
                          <button
                            onClick={() => deletePhoto(photo.id)}
                            className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition-opacity"
                          >
                            <X className="h-3 w-3" />
                          </button>
                          {photo.caption && (
                            <p className="text-xs text-gray-600 mt-1 truncate">{photo.caption}</p>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                  
                  {jobPhotos.length === 0 && (
                    <p className="text-gray-500 text-center py-8">
                      No photos uploaded yet. Use the form above to upload photos.
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="files">
              <Card>
                <CardHeader>
                  <CardTitle>Job Files</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  {currentUserId && (
                    <FileUploadDebug 
                      jobId={job.id} 
                      userId={currentUserId} 
                      onUploadComplete={refreshJobMedia}
                    />
                  )}
                  
                  {jobFiles.length > 0 && (
                    <div className="space-y-2">
                      {jobFiles.map((file) => (
                        <div key={file.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100">
                          <a 
                            href={file.file_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-3 flex-1 min-w-0"
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
                          </a>
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
                      No files uploaded yet. Use the form above to upload files.
                    </p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="notes">
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
            </TabsContent>
          </Tabs>
        </div>

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
              <div>
                <p className="text-sm text-muted-foreground">Job Type</p>
                <p className="font-medium">{job.job_type}</p>
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
              {userRole === 'boss' && (
                <>
                  <div>
                    <p className="text-sm text-muted-foreground">Total Amount</p>
                    <p className="font-medium">
                      ${job.total_amount ? job.total_amount.toFixed(2) : '0.00'}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Amount Paid</p>
                    <p className="font-medium">
                      ${job.amount_paid ? job.amount_paid.toFixed(2) : '0.00'}
                    </p>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

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

echo "✅ Updated JobDetailView with FileUploadDebug"

# Commit changes
git add -A
git commit -m "Add debug mode for FileUpload, clean up PhotoUpload display

- Created FileUploadDebug component with detailed logging
- Fixed PhotoUpload title (removed 'Debug Mode' text)
- FileUpload now shows detailed debug info to diagnose issues"

git push origin main

echo ""
echo "✅ COMPLETE!"
echo ""
echo "📋 INSTRUCTIONS:"
echo "1. Go to the Files tab in your job"
echo "2. Try uploading a file"
echo "3. Look for the debug log below the upload button"
echo "4. Share the error messages from the debug log"
echo ""
echo "The debug component will show:"
echo "- Authentication status"
echo "- Storage bucket upload status"
echo "- Database insert attempts"
echo "- Any specific error messages"
EOF
