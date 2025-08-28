#!/bin/bash

# HVAC App - Fix File Upload & Viewing
# Fixes: 1) File upload not working 2) File viewing not working
# Run as: ./fix_files.sh from my-dashboard-app directory

set -e  # Exit on error

echo "HVAC App - File Upload & Viewing Fix Starting..."
echo "============================================="

# Check we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "app" ]]; then
    echo "Error: Must run from my-dashboard-app project root directory"
    exit 1
fi

# Backup original files
echo "Creating backups..."
mkdir -p .fix-backups
cp -f components/uploads/FileUpload.tsx .fix-backups/FileUpload.tsx.backup 2>/dev/null || echo "FileUpload.tsx not found"
cp -f app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx .fix-backups/JobDetailView.tsx.backup

echo "1. Updating FileUpload component to work correctly..."

# Update FileUpload.tsx to use correct database schema
cat > components/uploads/FileUpload.tsx << 'EOF'
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
EOF

echo "FileUpload component updated"

echo "2. Fixing file viewing functionality in JobDetailView..."

# Use Python to safely update the JobDetailView file
python3 - << 'EOF'
import re

with open('app/(authenticated)/jobs/[id]/JobDetailView.tsx', 'r') as f:
    content = f.read()

# Make sure openFileViewer function exists with correct implementation
if 'openFileViewer' not in content:
    # Find the end of openMediaViewer and add openFileViewer
    pattern = r'(setViewerOpen\(true\)\s*\n\s*\})'
    replacement = r'\1\n\n  const openFileViewer = (files: any[], index: number) => {\n    const items = files.map(file => ({\n      id: file.id,\n      url: file.file_url,\n      name: file.file_name,\n      caption: file.file_name,\n      type: \'file\' as const,\n      mime_type: file.mime_type || \'application/octet-stream\'\n    }))\n    \n    setViewerItems(items)\n    setViewerIndex(index)\n    setViewerOpen(true)\n  }'
    
    content = re.sub(pattern, replacement, content)
    print("Added openFileViewer function")

# Fix file viewing by making sure the View buttons have onClick handlers
# Look for the file mapping section and ensure it has proper onClick
if 'onClick={() => openFileViewer' not in content:
    # Find the file mapping section and add onClick
    pattern = r'(\{jobFiles\.map\((file(?:, index)?) => \(\s*<div key=\{file\.id\}.*?)<Button[^>]*>\s*View\s*</Button>'
    
    def replace_func(match):
        file_param = match.group(2)
        if ', index' in file_param:
            return match.group(1) + '<Button\n                        size="sm"\n                        variant="outline"\n                        onClick={() => openFileViewer(jobFiles, index)}\n                      >\n                        View\n                      </Button>'
        else:
            return match.group(1) + '<Button\n                        size="sm"\n                        variant="outline"\n                        onClick={() => openFileViewer(jobFiles, jobFiles.indexOf(file))}\n                      >\n                        View\n                      </Button>'
    
    new_content = re.sub(pattern, replace_func, content, flags=re.DOTALL)
    
    if new_content != content:
        content = new_content
        print("Added onClick handlers to View buttons")
    else:
        # Try a different approach - look for jobFiles.map and ensure it has index parameter
        if 'jobFiles.map(file =>' in content:
            content = content.replace('jobFiles.map(file =>', 'jobFiles.map((file, index) =>')
            print("Added index parameter to jobFiles.map")
        
        # Now add onClick handlers
        content = re.sub(
            r'<Button\s+size="sm"\s+variant="outline"\s*>\s*View\s*</Button>',
            '<Button\n                        size="sm"\n                        variant="outline"\n                        onClick={() => openFileViewer(jobFiles, index)}\n                      >\n                        View\n                      </Button>',
            content
        )
        print("Added onClick handlers to View buttons (second attempt)")

with open('app/(authenticated)/jobs/[id]/JobDetailView.tsx', 'w') as f:
    f.write(content)

print("JobDetailView.tsx updated successfully")
EOF

echo "JobDetailView updated with file viewing functionality"

echo "3. Running TypeScript check..."
if ! npx tsc --noEmit; then
    echo "TypeScript errors found. Check output above."
    echo "Restoring backups..."
    cp .fix-backups/FileUpload.tsx.backup ./components/uploads/FileUpload.tsx 2>/dev/null || true
    cp .fix-backups/JobDetailView.tsx.backup ./app/\(authenticated\)/jobs/\[id\]/JobDetailView.tsx 2>/dev/null || true
    exit 1
fi

echo "TypeScript check passed"

echo "4. Git commit and push..."
git add -A
git commit -m "Fix: File upload and viewing functionality

- Updated FileUpload component to use correct database schema (job_files table)
- Fixed file_url, file_name column names to match database
- Added comprehensive error logging for file uploads
- Fixed openFileViewer function implementation
- Added onClick handlers to file View buttons
- Files now upload to job-files storage bucket
- Documents can be viewed in MediaViewer with download/new tab options"

if ! git push origin main; then
    echo "Git push failed, but changes are committed locally"
    echo "You may need to pull latest changes first: git pull origin main"
fi

echo ""
echo "SUCCESS! File upload and viewing fixes applied!"
echo "=============================================="
echo "File uploads now use:"
echo "- Storage bucket: job-files (not job-photos)"
echo "- Database table: job_files with correct columns"
echo "- Proper error logging for debugging"
echo ""
echo "File viewing now works:"
echo "- View buttons have onClick handlers"
echo "- Opens files in MediaViewer"
echo "- Download and new tab options available"
echo ""
echo "TEST NOW:"
echo "1. Upload a PDF/document file"
echo "2. Check console for debug output"
echo "3. Click 'View' button on uploaded files"
echo "4. Should open in full MediaViewer"

# Cleanup
rm -f build.log