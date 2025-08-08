'use client'

import { useState, useRef } from 'react'
import { Camera, Upload, X, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { createClient } from '@/lib/supabase/client'

interface PhotoUploadProps {
  jobId: string
  userId: string
  onPhotoUploaded?: () => void
}

export default function PhotoUpload({ jobId, userId, onPhotoUploaded }: PhotoUploadProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [photoType, setPhotoType] = useState<'before' | 'after' | 'during' | 'issue'>('before')
  const fileInputRef = useRef<HTMLInputElement>(null)
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    setSelectedFiles(files)
  }

  const handleUpload = async () => {
    if (selectedFiles.length === 0) return

    setIsUploading(true)
    
    try {
      // For now, we'll store photos in Supabase Storage
      // Later, this can be replaced with Google Drive API
      
      for (const file of selectedFiles) {
        // Upload to Supabase Storage
        const fileName = `${jobId}/${Date.now()}-${file.name}`
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(fileName, file)

        if (uploadError) {
          console.error('Upload error:', uploadError)
          continue
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(fileName)

        // Save photo record in database
        const { error: dbError } = await supabase
          .from('job_photos')
          .insert({
            job_id: jobId,
            uploaded_by: userId,
            photo_url: publicUrl,
            photo_type: photoType,
            caption: file.name,
            file_size_bytes: file.size,
            mime_type: file.type
          })

        if (dbError) {
          console.error('Database error:', dbError)
        }
      }

      // Clear selection
      setSelectedFiles([])
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }

      // Notify parent component
      if (onPhotoUploaded) {
        onPhotoUploaded()
      }

      alert('Photos uploaded successfully!')
    } catch (error) {
      console.error('Error uploading photos:', error)
      alert('Failed to upload photos')
    } finally {
      setIsUploading(false)
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Camera className="h-5 w-5" />
          Photo Upload
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Photo Type Selection */}
        <div>
          <label className="text-sm font-medium text-gray-700 mb-2 block">
            Photo Type
          </label>
          <div className="flex gap-2">
            {(['before', 'after', 'during', 'issue'] as const).map((type) => (
              <Button
                key={type}
                variant={photoType === type ? 'default' : 'outline'}
                size="sm"
                onClick={() => setPhotoType(type)}
                type="button"
              >
                {type.charAt(0).toUpperCase() + type.slice(1)}
              </Button>
            ))}
          </div>
        </div>

        {/* File Input */}
        <div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            multiple
            onChange={handleFileSelect}
            className="hidden"
          />
          <Button
            variant="outline"
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading}
            className="w-full"
          >
            <Camera className="h-4 w-4 mr-2" />
            Select Photos
          </Button>
        </div>

        {/* Selected Files Preview */}
        {selectedFiles.length > 0 && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Selected Photos:</p>
            {selectedFiles.map((file, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                <span className="text-sm truncate">{file.name}</span>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setSelectedFiles(files => files.filter((_, i) => i !== index))}
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        )}

        {/* Upload Button */}
        {selectedFiles.length > 0 && (
          <Button
            onClick={handleUpload}
            disabled={isUploading}
            className="w-full"
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
          </Button>
        )}

        {/* Google Drive Integration Note */}
        <div className="text-xs text-gray-500 bg-blue-50 p-3 rounded">
          <strong>Note:</strong> Photos are currently stored in Supabase Storage. 
          For Google Drive integration, you'll need:
          <ul className="list-disc list-inside mt-1">
            <li>Google Cloud Console project</li>
            <li>Service Account credentials</li>
            <li>Drive API enabled</li>
            <li>Shared folder permissions</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  )
}
