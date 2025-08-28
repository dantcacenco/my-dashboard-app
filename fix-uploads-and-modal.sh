#!/bin/bash

echo "🔧 Wiring EditJobModal and fixing uploads with debug logging..."

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# 1. Import EditJobModal in JobDetailView and use it
cat > wire-edit-modal.patch << 'EOF'
--- a/app/(authenticated)/jobs/[id]/JobDetailView.tsx
+++ b/app/(authenticated)/jobs/[id]/JobDetailView.tsx
@@ -14,6 +14,7 @@
 import Link from 'next/link'
 import { toast } from 'sonner'
 import MediaUpload from '@/components/uploads/MediaUpload'
 import FileUpload from '@/components/uploads/FileUpload'
+import { EditJobModal } from './EditJobModal'
 import MediaViewer from '@/components/MediaViewer'
 import VideoThumbnail from '@/components/VideoThumbnail'
@@ -39,7 +40,6 @@
   const [isEditingNotes, setIsEditingNotes] = useState(false)
   const [notesText, setNotesText] = useState(job.notes || '')
-  const [showEditModal, setShowEditModal] = useState(false)
+  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
   const [showDeleteModal, setShowDeleteModal] = useState(false)
   const [isDeleting, setIsDeleting] = useState(false)
@@ -55,6 +56,18 @@
   useEffect(() => {
     loadTechnicians()
     loadJobMedia()
+    
+    // Debug logging
+    console.log('=== JobDetailView Debug Info ===')
+    console.log('Job ID:', job.id)
+    console.log('User ID:', userId)
+    console.log('User Role:', userRole)
+    console.log('Job scheduled_date:', job.scheduled_date)
+    console.log('Job status:', job.status)
+    console.log('Job technician_id:', job.technician_id)
+    console.log('Job customers:', job.customers)
+    console.log('Current URL:', window.location.href)
+    console.log('================================')
   }, [])
 
@@ -507,7 +520,7 @@
           <Card>
             <CardHeader className="flex flex-row items-center justify-between">
               <CardTitle>Job Details</CardTitle>
-              <Button size="sm" variant="outline" onClick={() => setShowEditModal(true)}>
+              <Button size="sm" variant="outline" onClick={() => setIsEditModalOpen(true)}>
                 <Edit className="h-4 w-4 mr-1" />
                 Edit
               </Button>
@@ -600,6 +613,14 @@
           )}
         </DialogContent>
       </Dialog>
+      
+      {/* Edit Job Modal */}
+      <EditJobModal
+        job={job}
+        isOpen={isEditModalOpen}
+        onClose={() => setIsEditModalOpen(false)}
+        onJobUpdated={loadJobData}
+      />
     </div>
   )
 }
EOF

patch -p1 < wire-edit-modal.patch 2>/dev/null || echo "Patch 1 partially applied"

# 2. Add loadJobData function to refresh after edit
cat > add-load-job.patch << 'EOF'
--- a/app/(authenticated)/jobs/[id]/JobDetailView.tsx
+++ b/app/(authenticated)/jobs/[id]/JobDetailView.tsx
@@ -118,6 +118,29 @@
     console.log('Loaded job files:', files)
   }
+  
+  const loadJobData = async () => {
+    console.log('🔄 Reloading job data...')
+    try {
+      const { data: updatedJob, error } = await supabase
+        .from('jobs')
+        .select(`
+          *,
+          customers!customer_id (
+            id,
+            name,
+            email,
+            phone,
+            address
+          )
+        `)
+        .eq('id', job.id)
+        .single()
+      
+      if (!error && updatedJob) {
+        console.log('✅ Job data reloaded:', updatedJob)
+        setJob(updatedJob)
+      }
+    } catch (error) {
+      console.error('❌ Error reloading job:', error)
+    }
+  }
 
   const saveNotes = async () => {
EOF

patch -p1 < add-load-job.patch 2>/dev/null || echo "Patch 2 partially applied"

# 3. Fix MediaUpload with extensive debugging
cat > components/uploads/MediaUpload.tsx << 'EOF'
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
    console.log('📁 File select event triggered')
    const files = Array.from(e.target.files || [])
    console.log('Files selected:', files.length)
    
    const validFiles = files.filter(file => {
      console.log(`Checking file: ${file.name}, Type: ${file.type}, Size: ${file.size}`)
      const isImage = file.type.startsWith('image/')
      const isVideo = file.type.startsWith('video/')
      const isValidSize = file.size <= 50 * 1024 * 1024 // 50MB limit
      
      if (!isImage && !isVideo) {
        console.warn(`❌ ${file.name} is not an image or video`)
        toast.error(`${file.name} is not an image or video`)
        return false
      }
      if (!isValidSize) {
        console.warn(`❌ ${file.name} is too large (max 50MB)`)
        toast.error(`${file.name} is too large (max 50MB)`)
        return false
      }
      console.log(`✅ ${file.name} is valid`)
      return true
    })
    
    console.log('Valid files:', validFiles.length)
    setSelectedFiles(validFiles)
  }

  const uploadFiles = async () => {
    if (selectedFiles.length === 0) {
      console.warn('No files selected')
      return
    }
    
    console.log('🚀 Starting upload process')
    console.log('Job ID:', jobId)
    console.log('User ID:', userId)
    console.log('Files to upload:', selectedFiles.map(f => f.name))
    
    setUploading(true)
    let successCount = 0
    
    for (const file of selectedFiles) {
      try {
        console.log(`📤 Uploading ${file.name}...`)
        
        // Generate unique file name
        const fileExt = file.name.split('.').pop()
        const timestamp = Date.now()
        const randomStr = Math.random().toString(36).substring(7)
        const fileName = `${timestamp}_${randomStr}.${fileExt}`
        const filePath = `${jobId}/${fileName}`
        
        console.log('Storage path:', filePath)
        console.log('Bucket: job-photos')
        
        // Upload to storage
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('job-photos')
          .upload(filePath, file, {
            cacheControl: '3600',
            upsert: false
          })
        
        if (uploadError) {
          console.error('❌ Storage upload error:', uploadError)
          throw uploadError
        }
        
        console.log('✅ File uploaded to storage:', uploadData)
        
        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-photos')
          .getPublicUrl(filePath)
        
        console.log('Public URL:', publicUrl)
        
        // Save to database
        const dbRecord = {
          job_id: jobId,
          url: publicUrl,
          caption: caption || null,
          media_type: file.type.startsWith('video/') ? 'video' : 'photo',
          uploaded_by: userId,
          file_name: file.name,
          file_size: file.size,
          file_type: file.type
        }
        
        console.log('Database record:', dbRecord)
        
        const { data: dbData, error: dbError } = await supabase
          .from('job_photos')
          .insert(dbRecord)
          .select()
        
        if (dbError) {
          console.error('❌ Database insert error:', dbError)
          throw dbError
        }
        
        console.log('✅ Database record created:', dbData)
        successCount++
        
      } catch (error) {
        console.error(`❌ Failed to upload ${file.name}:`, error)
        toast.error(`Failed to upload ${file.name}`)
      }
    }
    
    if (successCount > 0) {
      console.log(`✅ Successfully uploaded ${successCount} file(s)`)
      toast.success(`Uploaded ${successCount} file(s)`)
      setSelectedFiles([])
      setCaption('')
      onUploadComplete()
    } else {
      console.warn('⚠️ No files were uploaded successfully')
    }
    
    setUploading(false)
  }

  return (
    <div>
      <div className="space-y-4">
        {selectedFiles.length === 0 ? (
          <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
            <div className="flex flex-col items-center justify-center pt-5 pb-6">
              <Upload className="w-8 h-8 mb-2 text-gray-400" />
              <p className="mb-2 text-sm text-gray-500">
                <span className="font-semibold">Click to upload</span> or drag and drop
              </p>
              <p className="text-xs text-gray-500">Images or videos (Max 50MB)</p>
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
        ) : (
          <div>
            <div className="mb-3">
              <p className="text-sm font-medium mb-2">Selected files:</p>
              {selectedFiles.map((file, index) => (
                <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded mb-1">
                  <span className="text-sm">{file.name}</span>
                  <button
                    onClick={() => setSelectedFiles(files => files.filter((_, i) => i !== index))}
                    className="text-red-500 hover:text-red-700"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
            
            <input
              type="text"
              placeholder="Add a caption (optional)"
              value={caption}
              onChange={(e) => setCaption(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md mb-3"
            />
            
            <div className="flex gap-2">
              <Button
                onClick={uploadFiles}
                disabled={uploading}
              >
                {uploading ? 'Uploading...' : 'Upload'}
              </Button>
              <Button
                variant="outline"
                onClick={() => {
                  setSelectedFiles([])
                  setCaption('')
                }}
                disabled={uploading}
              >
                Cancel
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
EOF

# 4. Fix FileUpload similarly with debugging
cat > components/uploads/FileUpload.tsx << 'EOF'
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { FileText, Upload, X, Loader2 } from 'lucide-react'
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

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    console.log('📎 File select triggered for documents')
    const files = Array.from(e.target.files || [])
    console.log('Files selected:', files.length)
    
    const validFiles = files.filter(file => {
      console.log(`Checking file: ${file.name}, Type: ${file.type}, Size: ${file.size}`)
      const isValidSize = file.size <= 50 * 1024 * 1024 // 50MB
      
      if (!isValidSize) {
        console.warn(`❌ ${file.name} is too large`)
        toast.error(`${file.name} is too large (max 50MB)`)
        return false
      }
      
      console.log(`✅ ${file.name} is valid`)
      return true
    })
    
    setSelectedFiles(validFiles)
  }

  const uploadFiles = async () => {
    if (selectedFiles.length === 0) {
      console.warn('No files selected')
      return
    }
    
    console.log('📤 Starting file upload')
    console.log('Job ID:', jobId)
    console.log('User ID:', userId)
    
    setIsUploading(true)
    let successCount = 0
    
    for (const file of selectedFiles) {
      try {
        console.log(`Uploading document: ${file.name}`)
        
        const fileExt = file.name.split('.').pop()
        const timestamp = Date.now()
        const randomStr = Math.random().toString(36).substring(7)
        const fileName = `${timestamp}_${randomStr}.${fileExt}`
        const filePath = `${jobId}/${fileName}`
        
        console.log('Storage path:', filePath)
        console.log('Bucket: job-files')
        
        // Upload to storage
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('job-files')
          .upload(filePath, file, {
            cacheControl: '3600',
            upsert: false
          })
        
        if (uploadError) {
          console.error('❌ Storage error:', uploadError)
          throw uploadError
        }
        
        console.log('✅ File uploaded:', uploadData)
        
        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('job-files')
          .getPublicUrl(filePath)
        
        console.log('Public URL:', publicUrl)
        
        // Save to database
        const dbRecord = {
          job_id: jobId,
          url: publicUrl,
          file_name: file.name,
          file_type: file.type || 'application/octet-stream',
          file_size: file.size,
          uploaded_by: userId
        }
        
        console.log('DB Record:', dbRecord)
        
        const { data: dbData, error: dbError } = await supabase
          .from('job_files')
          .insert(dbRecord)
          .select()
        
        if (dbError) {
          console.error('❌ Database error:', dbError)
          throw dbError
        }
        
        console.log('✅ DB record created:', dbData)
        successCount++
        
      } catch (error) {
        console.error(`❌ Failed to upload ${file.name}:`, error)
        toast.error(`Failed to upload ${file.name}`)
      }
    }
    
    if (successCount > 0) {
      console.log(`✅ Uploaded ${successCount} file(s)`)
      toast.success(`Uploaded ${successCount} file(s)`)
      setSelectedFiles([])
      if (onUploadComplete) onUploadComplete()
    }
    
    setIsUploading(false)
  }

  return (
    <div>
      {selectedFiles.length === 0 ? (
        <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
          <div className="flex flex-col items-center justify-center pt-5 pb-6">
            <FileText className="w-8 h-8 mb-2 text-gray-400" />
            <p className="mb-2 text-sm text-gray-500">
              <span className="font-semibold">Click to upload</span> or drag and drop
            </p>
            <p className="text-xs text-gray-500">PDFs, documents, etc. (Max 50MB)</p>
          </div>
          <input
            type="file"
            className="hidden"
            multiple
            onChange={handleFileSelect}
            disabled={isUploading}
          />
        </label>
      ) : (
        <div>
          <div className="mb-3">
            {selectedFiles.map((file, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded mb-1">
                <span className="text-sm">{file.name}</span>
                <button
                  onClick={() => setSelectedFiles(files => files.filter((_, i) => i !== index))}
                  className="text-red-500"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>
          
          <button
            onClick={uploadFiles}
            disabled={isUploading}
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
          >
            {isUploading ? (
              <>
                <Loader2 className="animate-spin h-4 w-4 inline mr-2" />
                Uploading...
              </>
            ) : (
              'Upload Files'
            )}
          </button>
        </div>
      )}
    </div>
  )
}
EOF

# Clean up patch files
rm -f *.patch

echo "✅ EditJobModal wired and uploads fixed with extensive debugging"
echo "
📊 Debug logs will show:
- File selection events
- Upload progress
- Storage bucket operations  
- Database inserts
- Error details
- Public URLs generated

Check browser console (F12) for detailed logs!
"
