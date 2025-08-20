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
