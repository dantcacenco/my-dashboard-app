#!/bin/bash

set -e

echo "🔧 Fixing MP3 uploads and technician portal with time tracking..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Update FileUpload to explicitly accept audio files including MP3
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

  const getFileIcon = (mimeType: string, fileName: string) => {
    // Check by mime type first
    if (mimeType.startsWith('image/')) return Image
    if (mimeType.startsWith('audio/')) return Music
    if (mimeType.startsWith('video/')) return FileVideo
    if (mimeType === 'application/pdf') return FileText
    
    // Check by file extension as fallback
    const ext = fileName.split('.').pop()?.toLowerCase()
    if (ext === 'mp3' || ext === 'wav' || ext === 'ogg' || ext === 'm4a') return Music
    if (ext === 'mp4' || ext === 'mov' || ext === 'avi') return FileVideo
    if (ext === 'pdf') return FileText
    
    return File
  }

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    console.log('Selected files:', files.map(f => ({ name: f.name, type: f.type, size: f.size })))
    
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

      console.log(`Uploading ${file.name} (${file.type || 'unknown type'}) to job-files bucket`)

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('job-files')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.type || 'application/octet-stream'
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
              PDFs, documents, MP3, audio files, etc. (max 50MB each)
            </p>
          </div>
          <input
            type="file"
            multiple
            onChange={handleFileSelect}
            className="hidden"
            disabled={isUploading}
            accept=".pdf,.doc,.docx,.xls,.xlsx,.txt,.mp3,.wav,.ogg,.m4a,.aac,.flac,audio/*,application/*,text/*"
          />
        </label>
      </div>

      {selectedFiles.length > 0 && (
        <div className="mb-4">
          <div className="space-y-2">
            {selectedFiles.map((file, index) => {
              const Icon = getFileIcon(file.type, file.name)
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

echo "✅ Fixed FileUpload to accept MP3 and all audio files"

# 2. Create TimeTracking component
cat > components/TimeTracking.tsx << 'EOF'
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
        duration_minutes
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
EOF

echo "✅ Created TimeTracking component"

# Clean up and commit
rm -f fix-build.sh

git add -A
git commit -m "Fix MP3 uploads and add time tracking component

- Fixed FileUpload to explicitly accept MP3 and all audio files
- Added file extension checking as fallback for mime type detection
- Created TimeTracking component with clock in/out functionality
- Time entries are editable by boss and the technician who created them
- Shows total hours worked on job by all technicians
- Ready for integration with technician portal"

git push origin main

echo ""
echo "✅ Components ready!"
echo ""
echo "Next steps:"
echo "1. Need to create job_time_entries table in Supabase"
echo "2. Update technician portal to show jobs"
echo "3. Integrate TimeTracking component into job view"
EOF
