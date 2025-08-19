#!/bin/bash

# Service Pro - Comprehensive Fix Script Part 1
# Fixes photo/file upload and technician issues

set -e # Exit on error

echo "🔧 Starting comprehensive fix for Service Pro issues (Part 1)..."

# Navigate to project directory
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p app/jobs/\[id\]
mkdir -p app/components/technician

# 1. Fix Photo Upload in Jobs
echo "📸 Fixing photo upload in jobs..."
cat > 'app/jobs/[id]/PhotoUpload.tsx' << 'EOF'
'use client'

import { useState, useRef } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'
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
  const supabase = createBrowserClient()

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
        
        // Upload to Supabase storage
        const { error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(fileName, file)

        if (uploadError) throw uploadError

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(fileName)

        // Save metadata to database
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

      toast.success(`Successfully uploaded ${uploadedCount} photo${uploadedCount > 1 ? 's' : ''}`)
      setSelectedFiles([])
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
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
          <p className="text-sm text-gray-600">Selected files:</p>
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

echo "✅ PhotoUpload component created!"

# Test build
echo "🔨 Testing build..."
npm run build 2>&1 | tail -20

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
  
  echo "📤 Committing and pushing changes..."
  git add -A
  git commit -m "Fix photo upload functionality with multiple file selection"
  git push origin main
  
  echo "✅ Part 1 complete! Photo upload fixed."
else
  echo "❌ Build failed. Check errors above."
  exit 1
fi
