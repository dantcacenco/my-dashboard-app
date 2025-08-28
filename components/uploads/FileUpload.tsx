'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { FileText, Upload, X } from 'lucide-react'
import { toast } from 'sonner'

interface FileUploadProps {
  jobId: string
  userId: string
  onUploadComplete: () => void
}

export default function FileUpload({ jobId, userId, onUploadComplete }: FileUploadProps) {
  const [uploading, setUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    const validFiles = files.filter(file => {
      const isValidSize = file.size <= 50 * 1024 * 1024 // 50MB limit
      
      if (!isValidSize) {
        toast.error(`${file.name} is too large (max 50MB)`)
        return false
      }
      return true
    })
    
    setSelectedFiles(validFiles)
  }

  const uploadFiles = async () => {
    if (selectedFiles.length === 0) return
    
    setUploading(true)
    let successCount = 0
    
    console.log('=== FILE UPLOAD DEBUG START ===')
    console.log('Component props:', { jobId, userId, selectedFilesCount: selectedFiles.length })
    
    for (const file of selectedFiles) {
      try {
        console.log('--- File Upload Start ---')
        console.log('Upload attempt:', {
          userId,
          jobId,
          fileName: file.name,
          fileSize: file.size,
          fileType: file.type,
          bucketName: 'job-files'
        })

        // Upload to storage with proper path
        const fileExt = file.name.split('.').pop()
        const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`
        const filePath = `${jobId}/${fileName}`
        
        console.log('Full upload path:', filePath)
        
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('job-files')
          .upload(filePath, file)
        
        console.log('Storage response:', { uploadData, uploadError })
        
        if (uploadError) {
          console.error('Storage upload failed:', uploadError)
          throw uploadError
        }
        
        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-files')
          .getPublicUrl(filePath)
        
        console.log('Generated public URL:', publicUrl)
        
        // Save to database - using job_files table
        const dbInsert = {
          job_id: jobId,
          file_name: file.name,
          file_url: publicUrl,
          mime_type: file.type || 'application/octet-stream',
          uploaded_by: userId
        }
        console.log('Database insert payload:', dbInsert)
        
        const { data: insertData, error: dbError } = await supabase
          .from('job_files')
          .insert(dbInsert)
          .select()
        
        console.log('Database insert result:', { insertData, dbError })
        
        if (dbError) {
          console.error('Database insert failed:', dbError)
          throw dbError
        }
        
        console.log('--- File Upload SUCCESS ---')
        successCount++
      } catch (error: any) {
        console.error('=== FILE UPLOAD ERROR DETAILS ===', error)
        console.error('Error type:', typeof error)
        console.error('Error message:', error?.message)
        console.error('Error code:', error?.code)
        console.error('Full error object:', JSON.stringify(error, null, 2))
        toast.error(`Failed to upload ${file.name}: ${error?.message || 'Unknown error'}`)
      }
    }
    
    console.log('=== FILE UPLOAD DEBUG END ===')
    console.log(`Upload summary: ${successCount}/${selectedFiles.length} successful`)
    
    if (successCount > 0) {
      toast.success(`Uploaded ${successCount} file(s)`)
      setSelectedFiles([])
      onUploadComplete()
    }
    
    setUploading(false)
  }

  const removeFile = (index: number) => {
    setSelectedFiles(files => files.filter((_, i) => i !== index))
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-center w-full">
        <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100">
          <div className="flex flex-col items-center justify-center pt-5 pb-6">
            <Upload className="w-8 h-8 mb-2 text-gray-400" />
            <p className="mb-2 text-sm text-gray-500">
              Click to select files or drag and drop
            </p>
            <p className="text-xs text-gray-500">
              PDFs, documents, MP3, audio files, etc. (max 50MB each)
            </p>
          </div>
          <input
            type="file"
            className="hidden"
            multiple
            accept=".pdf,.doc,.docx,.txt,.csv,.xlsx,.xls,.mp3,.wav,.zip,.rar"
            onChange={handleFileSelect}
            disabled={uploading}
          />
        </label>
      </div>

      {selectedFiles.length > 0 && (
        <div className="space-y-2">
          <div className="space-y-2">
            {selectedFiles.map((file, index) => (
              <div key={index} className="flex items-center justify-between p-2 border rounded">
                <div className="flex items-center gap-2">
                  <FileText className="w-4 h-4 text-gray-500" />
                  <span className="text-sm">{file.name}</span>
                  <span className="text-xs text-gray-400">
                    ({(file.size / 1024 / 1024).toFixed(1)} MB)
                  </span>
                </div>
                <button
                  onClick={() => removeFile(index)}
                  className="text-red-500 hover:text-red-700"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
          
          <Button
            onClick={uploadFiles}
            disabled={uploading}
            className="w-full"
          >
            {uploading ? 'Uploading...' : `Upload ${selectedFiles.length} file(s)`}
          </Button>
        </div>
      )}
    </div>
  )
}
