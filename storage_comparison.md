# Storage Solution Comparison - Service Pro HVAC

## Current Problem
- Supabase storage is expensive: $35/mo for only 100GB
- HVAC requires 5-10 year photo retention for warranties
- Expected storage: 1-5TB within first year

## Storage Solution Comparison

| Provider | Storage Cost | Egress Cost | API Compatibility | Speed | Best For |
|----------|-------------|------------|-------------------|-------|----------|
| **Supabase** | $0.35/GB/mo | Included | Native | Fast | Database & Auth only |
| **IDrive e2** | $0.004/GB/mo | $0.01/GB | S3-compatible | Good | **RECOMMENDED for files** |
| **Cloudflare R2** | $0.015/GB/mo | FREE | S3-compatible | Excellent | Alternative option |
| **AWS S3** | $0.023/GB/mo | $0.09/GB | Native S3 | Excellent | Enterprise option |
| **Backblaze B2** | $0.006/GB/mo | $0.01/GB | S3-compatible | Good | Budget option |

## ✅ RECOMMENDED ARCHITECTURE

### Hybrid Solution: Supabase + IDrive e2

**Keep in Supabase:**
- User authentication & profiles
- Database (jobs, customers, proposals)
- Small files (<1MB): avatars, logos
- Temporary files (<30 days)
- **Monthly Cost**: $25 (Pro plan without storage)

**Move to IDrive e2:**
- All job photos/videos
- Documents & PDFs
- Customer files
- Archived data
- **Monthly Cost**: $4/TB ($0.004/GB)

### Cost Savings Example
| Storage | Supabase Only | Hybrid (Supabase + IDrive e2) | Savings |
|---------|--------------|--------------------------------|---------|
| 100GB | $35/mo | $25 + $0.40 = $25.40 | $9.60/mo (27%) |
| 500GB | $175/mo | $25 + $2 = $27 | $148/mo (84%) |
| 1TB | $350/mo | $25 + $4 = $29 | $321/mo (92%) |
| 5TB | N/A | $25 + $20 = $45 | Massive savings |

## Why IDrive e2?

### Pros:
- **Ultra-low cost**: $0.004/GB/mo (88% cheaper than Supabase)
- **S3-compatible**: Use AWS SDK, works with existing code
- **Low egress**: Only $0.01/GB (vs AWS at $0.09/GB)
- **No API charges**: Unlimited API calls
- **11 9s durability**: Enterprise-grade reliability
- **Geographic redundancy**: Multiple data centers
- **HIPAA compliant**: Good for sensitive data

### Cons:
- Not as fast as Cloudflare R2's edge network
- Less known than AWS/Google
- Fewer regions than major clouds

## Implementation Plan

### Phase 1: Set Up IDrive e2 (Week 1)
```bash
# 1. Sign up for IDrive e2
# 2. Create bucket: service-pro-media
# 3. Generate access keys
```

### Phase 2: Update Upload Code (Week 2)
```typescript
// lib/storage/idrive.ts
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3'

const s3Client = new S3Client({
  endpoint: 'https://s3.us-west-1.idrivee2.com',
  region: 'us-west-1',
  credentials: {
    accessKeyId: process.env.IDRIVE_ACCESS_KEY!,
    secretAccessKey: process.env.IDRIVE_SECRET_KEY!
  }
})

export async function uploadToIDrive(file: File, path: string) {
  const command = new PutObjectCommand({
    Bucket: 'service-pro-media',
    Key: path,
    Body: file,
    ContentType: file.type
  })
  
  await s3Client.send(command)
  
  // Store URL in Supabase database
  return `https://service-pro-media.s3.us-west-1.idrivee2.com/${path}`
}
```

### Phase 3: Migrate Existing Files (Week 3)
- Write migration script
- Transfer existing files from Supabase to IDrive
- Update database URLs
- Verify all files accessible

### Phase 4: Implement CDN (Optional)
- Use Cloudflare as CDN in front of IDrive
- Cache frequently accessed files
- Further reduce egress costs

## Alternative: Cloudflare R2

If you prefer maximum speed over lowest cost:
- **Cost**: $0.015/GB/mo (still 95% cheaper than Supabase)
- **Egress**: FREE (huge advantage)
- **Speed**: Excellent (global edge network)
- **Integration**: Easy with Workers

## Final Recommendation

**Use IDrive e2 for:**
- Primary file storage (photos, videos, documents)
- Long-term archives
- Backup storage

**Keep Supabase for:**
- Database
- Authentication
- Real-time subscriptions
- Small, frequently accessed files

**Monthly costs at 1TB scale:**
- Current: $350/mo (Supabase only)
- New: $29/mo (Hybrid solution)
- **Savings: $321/mo (92%)**

## Environment Variables Needed

```env
# IDrive e2
IDRIVE_ACCESS_KEY=xxx
IDRIVE_SECRET_KEY=xxx
IDRIVE_BUCKET_NAME=service-pro-media
IDRIVE_ENDPOINT=https://s3.us-west-1.idrivee2.com
IDRIVE_REGION=us-west-1

# Keep Supabase for database
NEXT_PUBLIC_SUPABASE_URL=xxx
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
```
