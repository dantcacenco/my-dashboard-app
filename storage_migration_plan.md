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
