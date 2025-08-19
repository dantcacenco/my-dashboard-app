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
