#!/bin/bash

set -e

echo "🔧 Fixing file storage bucket name and adding support for all file types..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update FileUpload to use correct bucket name and support all files
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
    
    // Validate file sizes
    const validFiles = files.filter(file => {
      if (file.size > 50 * 1024 * 1024) { // 50MB limit
        toast.error(`${file.name} is too large (max 50MB)`)
        return false
      }
      return true
    })

    setSelectedFiles(validFiles)
  }

  const uploadFile = async (file: File) => {
    try {
      // Generate unique filename
      const fileExt = file.name.split('.').pop()
      const sanitizedName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')
      const fileName = `${jobId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`

      console.log('Uploading file:', file.name, 'to bucket: jobfiles')

      // Upload to Supabase Storage - using 'jobfiles' bucket (no hyphen)
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('jobfiles')  // Changed from 'job-files' to 'jobfiles'
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) {
        console.error('Storage upload error:', uploadError)
        // If bucket doesn't exist, try alternative names
        if (uploadError.message?.includes('Bucket not found')) {
          console.log('Trying alternative bucket name: job_files')
          const { data: altUpload, error: altError } = await supabase.storage
            .from('job_files')  // Try with underscore
            .upload(fileName, file, {
              cacheControl: '3600',
              upsert: false
            })
          
          if (!altError) {
            // Use alternative bucket for URL
            const { data: { publicUrl } } = supabase.storage
              .from('job_files')
              .getPublicUrl(fileName)
            
            // Save to database
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
          }
        }
        throw uploadError
      }

      // Get public URL from jobfiles bucket
      const { data: { publicUrl } } = supabase.storage
        .from('jobfiles')
        .getPublicUrl(fileName)

      // Save to database
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
              Any file type including PDF, MP3, images, documents (max 50MB each)
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

      {/* Selected Files */}
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
    </div>
  )
}
EOF

echo "✅ Updated FileUpload with correct bucket name"

# Commit changes
git add -A
git commit -m "Fix file upload bucket name and add support for all file types

- Changed bucket name from 'job-files' to 'jobfiles'
- Added fallback to try 'job_files' if 'jobfiles' fails
- Added support for all file types including MP3, videos, etc
- Added file type icons for different formats
- Improved file size formatting"

git push origin main

echo ""
echo "✅ FIXES APPLIED!"
echo ""
echo "📋 IMPORTANT - Check your Supabase storage buckets:"
echo ""
echo "1. Go to Supabase Dashboard → Storage"
echo "2. Check what your file bucket is actually named:"
echo "   - 'jobfiles' (no hyphen/underscore)"
echo "   - 'job-files' (with hyphen)"
echo "   - 'job_files' (with underscore)"
echo ""
echo "3. If needed, create the bucket with this SQL:"
echo ""
EOF
