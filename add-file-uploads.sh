#!/bin/bash

# Add File/Photo Upload Functionality
echo "🔧 Adding file and photo upload functionality..."

# 1. Create Photo Upload Component
echo "📝 Creating photo upload component..."
mkdir -p /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/uploads

cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/uploads/PhotoUpload.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Camera, Upload, X, Loader2 } from 'lucide-react'
import { toast } from 'sonner'

interface PhotoUploadProps {
  jobId: string
  userId: string
  onUploadComplete?: () => void
}

export default function PhotoUpload({ jobId, userId, onUploadComplete }: PhotoUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [previews, setPreviews] = useState<string[]>([])
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    
    // Validate file types
    const validFiles = files.filter(file => {
      const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
      if (!validTypes.includes(file.type)) {
        toast.error(`${file.name} is not a valid image file`)
        return false
      }
      if (file.size > 10 * 1024 * 1024) { // 10MB limit
        toast.error(`${file.name} is too large (max 10MB)`)
        return false
      }
      return true
    })

    setSelectedFiles(validFiles)
    
    // Create previews
    const newPreviews: string[] = []
    validFiles.forEach(file => {
      const reader = new FileReader()
      reader.onloadend = () => {
        newPreviews.push(reader.result as string)
        if (newPreviews.length === validFiles.length) {
          setPreviews(newPreviews)
        }
      }
      reader.readAsDataURL(file)
    })
  }

  const uploadPhoto = async (file: File) => {
    try {
      // Generate unique filename
      const fileExt = file.name.split('.').pop()
      const fileName = `${jobId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`

      // Upload to Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('job-photos')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('job-photos')
        .getPublicUrl(fileName)

      // Save to database
      const { error: dbError } = await supabase
        .from('job_photos')
        .insert({
          job_id: jobId,
          uploaded_by: userId,
          photo_url: publicUrl,
          photo_type: 'job_progress',
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
      toast.error('Please select photos to upload')
      return
    }

    setIsUploading(true)
    let successCount = 0
    let errorCount = 0

    for (const file of selectedFiles) {
      const result = await uploadPhoto(file)
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
      toast.success(`${successCount} photo(s) uploaded successfully`)
      onUploadComplete?.()
    }
    
    if (errorCount > 0) {
      toast.error(`${errorCount} photo(s) failed to upload`)
    }
  }

  const removeFile = (index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index))
    setPreviews(prev => prev.filter((_, i) => i !== index))
  }

  return (
    <div className="bg-white rounded-lg border p-4">
      <h3 className="font-medium mb-3 flex items-center gap-2">
        <Camera className="h-5 w-5" />
        Upload Photos
      </h3>

      {/* File Input */}
      <div className="mb-4">
        <label className="block w-full cursor-pointer">
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 transition-colors">
            <Upload className="h-8 w-8 mx-auto mb-2 text-gray-400" />
            <p className="text-sm text-gray-600">
              Click to select photos or drag and drop
            </p>
            <p className="text-xs text-gray-500 mt-1">
              JPG, PNG, GIF, WebP (max 10MB each)
            </p>
          </div>
          <input
            type="file"
            multiple
            accept="image/*"
            onChange={handleFileSelect}
            className="hidden"
            disabled={isUploading}
          />
        </label>
      </div>

      {/* Previews */}
      {previews.length > 0 && (
        <div className="mb-4">
          <div className="grid grid-cols-3 gap-2">
            {previews.map((preview, index) => (
              <div key={index} className="relative group">
                <img
                  src={preview}
                  alt={`Preview ${index + 1}`}
                  className="w-full h-24 object-cover rounded"
                />
                <button
                  onClick={() => removeFile(index)}
                  className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <X className="h-3 w-3" />
                </button>
              </div>
            ))}
          </div>
          <p className="text-sm text-gray-600 mt-2">
            {selectedFiles.length} photo(s) selected
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
              Upload {selectedFiles.length} Photo(s)
            </>
          )}
        </button>
      )}
    </div>
  )
}
EOF

# 2. Create File Upload Component
echo "📝 Creating file upload component..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/uploads/FileUpload.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { FileText, Upload, X, Loader2, File } from 'lucide-react'
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

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + ' B'
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  }

  const getFileIcon = (fileName: string) => {
    const ext = fileName.split('.').pop()?.toLowerCase()
    if (['pdf'].includes(ext || '')) return '📄'
    if (['doc', 'docx'].includes(ext || '')) return '📝'
    if (['xls', 'xlsx'].includes(ext || '')) return '📊'
    if (['zip', 'rar'].includes(ext || '')) return '📦'
    return '📎'
  }

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    
    // Validate files
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
      const fileName = `${jobId}/${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`

      // Upload to Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('job-files')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (uploadError) throw uploadError

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('job-files')
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
          mime_type: file.type,
          is_visible_to_all: true
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

  return (
    <div className="bg-white rounded-lg border p-4">
      <h3 className="font-medium mb-3 flex items-center gap-2">
        <FileText className="h-5 w-5" />
        Upload Files
      </h3>

      {/* File Input */}
      <div className="mb-4">
        <label className="block w-full cursor-pointer">
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 transition-colors">
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
                <div className="flex items-center gap-2 flex-1">
                  <span className="text-xl">{getFileIcon(file.name)}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{file.name}</p>
                    <p className="text-xs text-gray-500">{formatFileSize(file.size)}</p>
                  </div>
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

# 3. Update JobDetailView to include upload components
echo "📝 Updating JobDetailView to include uploads..."
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/app/\(authenticated\)/jobs/\[id\]/JobDetailWithUploads.tsx << 'EOF'
'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import PhotoUpload from '@/components/uploads/PhotoUpload'
import FileUpload from '@/components/uploads/FileUpload'
import { Camera, FileText, X } from 'lucide-react'

interface JobDetailWithUploadsProps {
  jobId: string
  userId: string
}

export default function JobDetailWithUploads({ jobId, userId }: JobDetailWithUploadsProps) {
  const [photos, setPhotos] = useState<any[]>([])
  const [files, setFiles] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  const fetchMedia = async () => {
    setLoading(true)
    
    // Fetch photos
    const { data: photosData } = await supabase
      .from('job_photos')
      .select('*')
      .eq('job_id', jobId)
      .order('created_at', { ascending: false })

    // Fetch files
    const { data: filesData } = await supabase
      .from('job_files')
      .select('*')
      .eq('job_id', jobId)
      .order('created_at', { ascending: false })

    setPhotos(photosData || [])
    setFiles(filesData || [])
    setLoading(false)
  }

  useEffect(() => {
    fetchMedia()
  }, [jobId])

  const deletePhoto = async (photoId: string) => {
    if (!confirm('Are you sure you want to delete this photo?')) return

    const { error } = await supabase
      .from('job_photos')
      .delete()
      .eq('id', photoId)

    if (!error) {
      setPhotos(prev => prev.filter(p => p.id !== photoId))
    }
  }

  const deleteFile = async (fileId: string) => {
    if (!confirm('Are you sure you want to delete this file?')) return

    const { error } = await supabase
      .from('job_files')
      .delete()
      .eq('id', fileId)

    if (!error) {
      setFiles(prev => prev.filter(f => f.id !== fileId))
    }
  }

  return (
    <div className="space-y-6">
      {/* Upload Sections */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <PhotoUpload 
          jobId={jobId} 
          userId={userId} 
          onUploadComplete={fetchMedia}
        />
        <FileUpload 
          jobId={jobId} 
          userId={userId} 
          onUploadComplete={fetchMedia}
        />
      </div>

      {/* Existing Photos */}
      {photos.length > 0 && (
        <div className="bg-white rounded-lg border p-4">
          <h3 className="font-medium mb-3 flex items-center gap-2">
            <Camera className="h-5 w-5" />
            Job Photos ({photos.length})
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {photos.map((photo) => (
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
        </div>
      )}

      {/* Existing Files */}
      {files.length > 0 && (
        <div className="bg-white rounded-lg border p-4">
          <h3 className="font-medium mb-3 flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Job Files ({files.length})
          </h3>
          <div className="space-y-2">
            {files.map((file) => (
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
        </div>
      )}
    </div>
  )
}
EOF

echo "🔨 Building the application..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -50

echo ""
echo "📦 Committing changes..."
git add -A
git commit -m "Add photo and file upload functionality for jobs"
git push origin main

echo ""
echo "✅ File upload functionality added!"
echo ""
echo "📝 Next steps:"
echo "1. Run the SQL above to create storage buckets if needed"
echo "2. Import JobDetailWithUploads in your job detail page"
echo "3. Test uploading photos and files"
