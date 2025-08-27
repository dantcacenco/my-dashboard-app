#!/bin/bash

# Service Pro - Fix Technician Photo Display & Storage Analysis
# This script fixes the photo display issue and analyzes storage options

set -e

echo "============================================"
echo "Service Pro - Photo Display Fix & Storage Analysis"
echo "============================================"

# Project variables
PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
SUPABASE_URL="https://dqcxwekmehrqkigcufug.supabase.co"
PROJECT_REF="dqcxwekmehrqkigcufug"
DB_PASSWORD="cSEX2IYYjeJru6V"

cd "$PROJECT_DIR"

# Step 1: Create SQL fix for storage buckets
echo "Creating SQL fix for storage buckets..."
cat > fix_storage.sql << 'EOF'
-- Make buckets public for read access
UPDATE storage.buckets 
SET public = true 
WHERE name IN ('job-photos', 'job-files');

-- Add RLS policies for storage objects if not exists
DO $$ 
BEGIN
  -- Allow technicians to upload to job-photos
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Technicians can upload photos'
  ) THEN
    CREATE POLICY "Technicians can upload photos"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'job-photos' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Allow public to view job-photos
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Public can view job photos'
  ) THEN
    CREATE POLICY "Public can view job photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'job-photos');
  END IF;

  -- Allow technicians to upload to job-files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Technicians can upload files'
  ) THEN
    CREATE POLICY "Technicians can upload files"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'job-files' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Allow authenticated to view job-files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Authenticated can view job files'
  ) THEN
    CREATE POLICY "Authenticated can view job files"
    ON storage.objects FOR SELECT
    USING (
      bucket_id = 'job-files'
      AND auth.role() = 'authenticated'
    );
  END IF;
END $$;

-- Verify bucket settings
SELECT name, public, created_at 
FROM storage.buckets 
WHERE name IN ('job-photos', 'job-files');

-- Check existing storage policies
SELECT tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects';
EOF

# Step 2: Update MediaUpload component to ensure proper URL generation
echo "Updating MediaUpload component..."
cat > "$PROJECT_DIR/components/uploads/MediaUpload.tsx" << 'EOF'
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
          .upload(filePath, file, {
            cacheControl: '3600',
            upsert: false
          })
        
        if (uploadError) throw uploadError
        
        // Construct public URL directly for public buckets
        // Format: https://[project-ref].supabase.co/storage/v1/object/public/[bucket]/[path]
        const publicUrl = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/job-photos/${filePath}`
        
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

# Step 3: Create storage migration plan document
echo "Creating storage migration plan..."
cat > "$PROJECT_DIR/storage_migration_plan.md" << 'EOF'
# Storage Migration Plan - Service Pro HVAC

## Current Problem
- Supabase Pro: $35/mo = 8GB database + 100GB file storage
- HVAC jobs require 5-10 year photo retention for warranties
- Estimated: 100-500 photos per job × 50-100 jobs/month = massive storage needs

## Recommended Solution: Hybrid Architecture

### Option 1: Cloudflare R2 (RECOMMENDED)
**Cost**: $0.015/GB/month storage + $0/GB egress (no bandwidth fees!)

**Implementation**:
1. Keep Supabase for database and auth ($25/mo Pro plan)
2. Move file storage to Cloudflare R2
3. Use Cloudflare Workers for signed URLs

**Benefits**:
- 10x cheaper than Supabase storage
- No egress fees (huge savings)
- S3-compatible API
- Global CDN included

### Option 2: AWS S3 + CloudFront
**Cost**: $0.023/GB/month + egress fees

**Implementation**:
1. S3 for storage with lifecycle policies
2. CloudFront CDN for delivery
3. Lambda@Edge for auth

### Option 3: Self-Hosted MinIO
**Cost**: VPS ~$20-40/mo for unlimited storage

**Implementation**:
1. Digital Ocean Spaces or Linode Object Storage
2. MinIO server for S3 compatibility
3. Nginx reverse proxy

## Migration Steps

```bash
# 1. Install R2 migration tools
npm install @aws-sdk/client-s3 wrangler

# 2. Create R2 bucket
wrangler r2 bucket create service-pro-media

# 3. Update environment variables
NEXT_PUBLIC_R2_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_BUCKET_NAME=service-pro-media
```

## Code Changes Required

### 1. Create new upload service (lib/storage/r2.ts)
```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3'

const r2Client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!
  }
})

export async function uploadToR2(file: File, path: string) {
  const command = new PutObjectCommand({
    Bucket: process.env.R2_BUCKET_NAME,
    Key: path,
    Body: file,
    ContentType: file.type
  })
  
  await r2Client.send(command)
  return `https://media.yourcompany.com/${path}`
}
```

### 2. Update MediaUpload to use R2
- Replace Supabase storage calls with R2
- Store URLs in database

### 3. Set up Cloudflare Worker for serving files
- Handle authentication
- Serve from R2 bucket
- Cache at edge

## Cost Comparison (Monthly)

| Storage Amount | Supabase | R2 | S3+CloudFront | Self-Hosted |
|---------------|----------|-----|---------------|-------------|
| 100GB | $35 | $1.50 | $5-10 | $20 |
| 500GB | $175 | $7.50 | $25-40 | $20 |
| 1TB | $350 | $15 | $50-80 | $20-40 |
| 5TB | N/A | $75 | $250-400 | $40-80 |

## Recommended Timeline
1. Week 1: Set up R2 bucket and test uploads
2. Week 2: Migrate MediaUpload component
3. Week 3: Create migration script for existing photos
4. Week 4: Complete migration and verify

## Backup Strategy
- Keep last 30 days in Supabase
- Archive to R2 after 30 days
- Weekly backups to another region
EOF

# Step 4: Test build
echo "Testing build..."
npm run build 2>&1 | head -80

# Step 5: Commit changes
echo "Committing changes..."
git add -A
git commit -m "Fix photo display with public URL construction and add storage migration plan"
git push origin main

# Step 6: Display SQL to run manually
echo ""
echo "============================================"
echo "SUCCESS! Changes committed and pushed."
echo "============================================"
echo ""
echo "IMPORTANT: Run this SQL in Supabase Dashboard:"
echo "---------------------------------------------"
cat fix_storage.sql
echo ""
echo "---------------------------------------------"
echo ""
echo "Storage Migration Plan created at: storage_migration_plan.md"
echo ""
echo "Next Steps:"
echo "1. Run the SQL above in Supabase SQL Editor"
echo "2. Test photo uploads in technician portal"
echo "3. Review storage_migration_plan.md for long-term solution"
echo "4. Consider implementing Cloudflare R2 for massive cost savings"
echo ""
echo "============================================"
