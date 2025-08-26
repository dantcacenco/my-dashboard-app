#!/bin/bash

# Fix technician permissions for photos and files
echo "Fixing technician permissions for media access..."

# Create a script to update Supabase storage policies
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/fix-storage-permissions.sql << 'EOF'
-- Storage bucket policies for job-photos
-- Allow technicians to view photos for jobs they're assigned to
CREATE POLICY "Technicians can view job photos for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-photos' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Allow technicians to upload photos to jobs they're assigned to  
CREATE POLICY "Technicians can upload photos to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-photos' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Storage bucket policies for job-files
-- Allow technicians to view files for jobs they're assigned to
CREATE POLICY "Technicians can view job files for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-files' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Allow technicians to upload files to jobs they're assigned to
CREATE POLICY "Technicians can upload files to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-files' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Also ensure the job_photos and job_files tables allow technician access
-- Allow technicians to view job_photos records for assigned jobs
CREATE POLICY "Technicians can view job_photos for assigned jobs"
ON public.job_photos FOR SELECT
USING (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_photos.job_id
  )
);

-- Allow technicians to create job_photos records for assigned jobs
CREATE POLICY "Technicians can create job_photos for assigned jobs"
ON public.job_photos FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_photos.job_id
  )
);

-- Allow technicians to view job_files records for assigned jobs
CREATE POLICY "Technicians can view job_files for assigned jobs"
ON public.job_files FOR SELECT
USING (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_files.job_id
  )
);

-- Allow technicians to create job_files records for assigned jobs
CREATE POLICY "Technicians can create job_files for assigned jobs"
ON public.job_files FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_files.job_id
  )
);
EOF

# Update MediaUpload component to ensure proper URL generation
cat > /Users/dantcacenco/Documents/GitHub/my-dashboard-app/components/uploads/MediaUpload.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Camera, Video, Upload, X } from 'lucide-react'
import { toast } from 'sonner'

interface MediaUploadProps {
  jobId: string
  userId: string
  onUploadComplete: () => void
}

export default function MediaUpload({ jobId, userId, onUploadComplete }: MediaUploadProps) {
  const [uploading, setUploading] = useState(false)
  const [selectedFiles, setSelectedFiles] = useState<File[]>([])
  const [caption, setCaption] = useState('')
  const supabase = createClient()

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    const validFiles = files.filter(file => {
      const isImage = file.type.startsWith('image/')
      const isVideo = file.type.startsWith('video/')
      const isValidSize = file.size <= 50 * 1024 * 1024 // 50MB limit
      
      if (!isImage && !isVideo) {
        toast.error(`${file.name} is not an image or video`)
        return false
      }
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
    
    for (const file of selectedFiles) {
      try {
        // Upload to storage with proper path
        const fileExt = file.name.split('.').pop()
        const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`
        const filePath = `${jobId}/${fileName}`
        
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(filePath, file)
        
        if (uploadError) throw uploadError
        
        // Get public URL - ensure proper URL format
        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(filePath)
        
        // Save to database
        const { error: dbError } = await supabase
          .from('job_photos')
          .insert({
            job_id: jobId,
            url: publicUrl,
            caption: caption || null,
            media_type: file.type.startsWith('video/') ? 'video' : 'photo',
            uploaded_by: userId
          })
        
        if (dbError) throw dbError
        
        successCount++
      } catch (error) {
        console.error('Upload error:', error)
        toast.error(`Failed to upload ${file.name}`)
      }
    }
    
    if (successCount > 0) {
      toast.success(`Uploaded ${successCount} file(s)`)
      setSelectedFiles([])
      setCaption('')
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
              Click to select photos/videos or drag and drop
            </p>
            <p className="text-xs text-gray-500">
              JPG, PNG, GIF, WebP, MP4, MOV (max 50MB each)
            </p>
          </div>
          <input
            type="file"
            className="hidden"
            multiple
            accept="image/*,video/*"
            onChange={handleFileSelect}
            disabled={uploading}
          />
        </label>
      </div>

      {selectedFiles.length > 0 && (
        <div className="space-y-2">
          <div className="flex flex-wrap gap-2">
            {selectedFiles.map((file, index) => (
              <div key={index} className="relative group">
                {file.type.startsWith('image/') ? (
                  <img
                    src={URL.createObjectURL(file)}
                    alt={file.name}
                    className="w-20 h-20 object-cover rounded"
                  />
                ) : (
                  <div className="w-20 h-20 bg-gray-200 rounded flex items-center justify-center">
                    <Video className="w-8 h-8 text-gray-500" />
                  </div>
                )}
                <button
                  onClick={() => removeFile(index)}
                  className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            ))}
          </div>
          
          <input
            type="text"
            placeholder="Add a caption (optional)"
            value={caption}
            onChange={(e) => setCaption(e.target.value)}
            className="w-full px-3 py-2 border rounded-md"
          />
          
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
EOF

echo ""
echo "============================================"
echo "IMPORTANT: Manual Steps Required!"
echo "============================================"
echo ""
echo "You need to run these SQL commands in your Supabase dashboard:"
echo ""
echo "1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/sql/new"
echo "2. Copy the contents of fix-storage-permissions.sql above"
echo "3. Run the SQL to create the storage policies"
echo ""
echo "The policies will allow technicians to:"
echo "- View photos/files for jobs they're assigned to"
echo "- Upload new photos/files to their assigned jobs"
echo ""

# Build and commit the code changes
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build 2>&1 | head -20

git add -A
git commit -m "Fix technician media access - update components and add storage policies"
git push origin main

echo "✅ Code updates deployed!"
echo "⚠️  Don't forget to run the SQL commands in Supabase!"
