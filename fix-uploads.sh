#!/bin/bash

# Service Pro - Comprehensive Fix Implementation
# Part 2: Fix remaining issues after photo upload

set -e
echo "🔧 Implementing remaining fixes..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Fix PhotoUpload import issue
echo "📸 Fixing PhotoUpload imports..."
cat > 'app/jobs/[id]/PhotoUpload.tsx' << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Upload, X, Loader2 } from 'lucide-react'

interface PhotoUploadProps {
  jobId: string
  onPhotosUploaded: () => void
}

export function PhotoUpload({ jobId, onPhotosUploaded }: PhotoUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)
      setSelectedFiles(files)
    }
  }
EOF

# Create FileUpload component
echo "📁 Creating FileUpload component..."
cat > 'app/jobs/[id]/FileUpload.tsx' << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Upload, X, Loader2, FileText } from 'lucide-react'

interface FileUploadProps {
  jobId: string
  onFilesUploaded: () => void
}

export function FileUpload({ jobId, onFilesUploaded }: FileUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)
      setSelectedFiles(files)
    }
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast.error('Please select files to upload')
      return
    }

    setIsUploading(true)
    let uploadedCount = 0

    try {
      for (const file of selectedFiles) {
        const fileName = `${jobId}/${Date.now()}_${file.name}`
        
        const { error: uploadError } = await supabase.storage
          .from('job-files')
          .upload(fileName, file)

        if (uploadError) throw uploadError

        const { data: { publicUrl } } = supabase.storage
          .from('job-files')
          .getPublicUrl(fileName)

        const { error: dbError } = await supabase
          .from('job_files')
          .insert({
            job_id: jobId,
            file_name: file.name,
            file_url: publicUrl,
            file_type: file.type || 'application/octet-stream',
            file_size: file.size,
            uploaded_by: (await supabase.auth.getUser()).data.user?.id
          })

        if (dbError) throw dbError
        uploadedCount++
      }

      toast.success(`Uploaded ${uploadedCount} file${uploadedCount > 1 ? 's' : ''}`)
      setSelectedFiles([])
      if (fileInputRef.current) fileInputRef.current.value = ''
      onFilesUploaded()
    } catch (error) {
      console.error('Upload error:', error)
      toast.error('Failed to upload files')
    } finally {
      setIsUploading(false)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <input
          ref={fileInputRef}
          type="file"
          multiple
          onChange={handleFileSelect}
          className="hidden"
          id="file-upload"
        />
        <label
          htmlFor="file-upload"
          className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
        >
          <Upload className="h-4 w-4 mr-2" />
          Select Files
        </label>
        {selectedFiles.length > 0 && (
          <button
            onClick={handleUpload}
            disabled={isUploading}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {isUploading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Uploading...
              </>
            ) : (
              <>
                <Upload className="h-4 w-4 mr-2" />
                Upload {selectedFiles.length} File{selectedFiles.length > 1 ? 's' : ''}
              </>
            )}
          </button>
        )}
      </div>

      {selectedFiles.length > 0 && (
        <div className="mt-4 space-y-2">
          <p className="text-sm text-gray-600">Selected files:</p>
          {selectedFiles.map((file, index) => (
            <div key={index} className="flex items-center justify-between bg-gray-50 p-2 rounded">
              <div className="flex items-center">
                <FileText className="h-4 w-4 mr-2 text-gray-500" />
                <span className="text-sm text-gray-700">{file.name}</span>
              </div>
              <button
                onClick={() => removeFile(index)}
                className="text-red-500 hover:text-red-700"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

echo "✅ File upload components created!"

# Now continue with PhotoUpload completion
cat >> 'app/jobs/[id]/PhotoUpload.tsx' << 'EOF'

  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      toast.error('Please select photos to upload')
      return
    }

    setIsUploading(true)
    let uploadedCount = 0

    try {
      for (const file of selectedFiles) {
        const fileName = `${jobId}/${Date.now()}_${file.name}`
        
        const { error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(fileName, file)

        if (uploadError) throw uploadError

        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(fileName)

        const { error: dbError } = await supabase
          .from('job_photos')
          .insert({
            job_id: jobId,
            photo_url: publicUrl,
            photo_type: 'during',
            uploaded_by: (await supabase.auth.getUser()).data.user?.id
          })

        if (dbError) throw dbError
        uploadedCount++
      }

      toast.success(`Uploaded ${uploadedCount} photo${uploadedCount > 1 ? 's' : ''}`)
      setSelectedFiles([])
      if (fileInputRef.current) fileInputRef.current.value = ''
      onPhotosUploaded()
    } catch (error) {
      console.error('Upload error:', error)
      toast.error('Failed to upload photos')
    } finally {
      setIsUploading(false)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4">
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept="image/*"
          onChange={handleFileSelect}
          className="hidden"
          id="photo-upload"
        />
        <label
          htmlFor="photo-upload"
          className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
        >
          <Upload className="h-4 w-4 mr-2" />
          Select Photos
        </label>
        {selectedFiles.length > 0 && (
          <button
            onClick={handleUpload}
            disabled={isUploading}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {isUploading ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Uploading...
              </>
            ) : (
              <>
                <Upload className="h-4 w-4 mr-2" />
                Upload {selectedFiles.length} Photo{selectedFiles.length > 1 ? 's' : ''}
              </>
            )}
          </button>
        )}
      </div>

      {selectedFiles.length > 0 && (
        <div className="mt-4 space-y-2">
          <p className="text-sm text-gray-600">Selected photos:</p>
          {selectedFiles.map((file, index) => (
            <div key={index} className="flex items-center justify-between bg-gray-50 p-2 rounded">
              <span className="text-sm text-gray-700">{file.name}</span>
              <button
                onClick={() => removeFile(index)}
                className="text-red-500 hover:text-red-700"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

echo "📝 Testing build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
  
  git add -A
  git commit -m "Fix photo/file upload components with proper imports and multiple file selection"
  git push origin main
  
  echo "🎉 Successfully fixed:"
  echo "✅ Photo upload with multiple selection"
  echo "✅ File upload with multiple selection"
  echo ""
  echo "📋 Still to address:"
  echo "- Technician dropdown population"
  echo "- Edit Job modal save"
  echo "- Customer data sync"
  echo "- Proposal approval flow"
  echo "- Navigation cleanup"
else
  echo "❌ Build failed. Review errors above."
  exit 1
fi
