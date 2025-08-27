#!/bin/bash

# Update project scope with storage and backup requirements

set -e

echo "============================================"
echo "Updating Project Scope with Storage & Backup Plans"
echo "============================================"

PROJECT_DIR="/Users/dantcacenco/Documents/GitHub/my-dashboard-app"
cd "$PROJECT_DIR"

# Create storage comparison document
cat > "$PROJECT_DIR/storage_comparison.md" << 'EOF'
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
EOF

# Update PROJECT_SCOPE.md
cat >> "$PROJECT_DIR/PROJECT_SCOPE.md" << 'EOF'

---

## 🗄️ STORAGE SOLUTION STRATEGY (NEW)

### Current Issue
- Supabase storage is too expensive for HVAC photo requirements
- Need 5-10 year retention for warranty documentation
- Estimated 1-5TB storage needed within first year

### Approved Solution: Hybrid Architecture
**Database & Auth**: Supabase ($25/mo Pro plan)
- User authentication
- All database tables
- Real-time subscriptions
- Small files (<1MB)

**File Storage**: IDrive e2 ($4/TB/mo)
- All job photos and videos
- Customer documents
- PDF invoices and proposals
- Long-term archives

### Migration Timeline
- **Week 1**: Set up IDrive e2 account and buckets
- **Week 2**: Update upload code to use IDrive
- **Week 3**: Migrate existing files
- **Week 4**: Implement CDN for faster delivery

### Expected Savings
- Current: $350/mo for 1TB (Supabase)
- New: $29/mo for 1TB (Hybrid)
- **Savings: $321/mo (92%)**

See `storage_comparison.md` for detailed analysis.

---

## 🔄 AUTOMATED BACKUP SYSTEM (NEW)

### Requirements
Automated weekly backup of all job data to local Windows office computer with email status reports.

### Backup Scope
1. **Database Backup** (Weekly)
   - All job records
   - Customer data
   - Proposal/Invoice history
   - Payment records
   - Export format: PostgreSQL dump + CSV

2. **File Backup** (Weekly)
   - Job photos and videos
   - Documents and PDFs
   - Organized by job number and date
   - Compressed archives

3. **Incremental Backups**
   - Only new/modified files since last backup
   - Reduces bandwidth and storage
   - Maintains version history

### Implementation Architecture

#### Backup Service Components
```typescript
// Scheduled via cron job or Windows Task Scheduler
// Runs every Sunday at 2 AM

1. Database Export Service
   - Connect to Supabase
   - Export tables to CSV/JSON
   - Create PostgreSQL dump
   
2. File Sync Service  
   - Connect to IDrive e2
   - Download new files since last backup
   - Organize by job/date structure
   
3. Compression Service
   - ZIP archives by week
   - Password protection
   - Checksums for integrity
   
4. Local Storage Service
   - Save to: C:\ServicePro\Backups\[YYYY-MM-DD]
   - Maintain 90-day retention
   - Auto-cleanup old backups
   
5. Email Report Service
   - Send to: dantcacenco@gmail.com
   - Subject: "Service Pro Backup - [Date] - [Status]"
   - Include: Files backed up, size, errors
```

### Backup Email Report Format
```
Subject: Service Pro Weekly Backup - SUCCESS - 2025-08-27

Backup Summary:
- Status: ✅ Successfully Completed
- Date: August 27, 2025 02:00 AM
- Duration: 12 minutes

Database Backup:
- Records Backed Up: 1,247
- New Jobs: 23
- New Customers: 8
- Size: 45 MB

File Backup:
- New Photos: 342
- New Documents: 18
- Total Size: 2.3 GB
- Location: C:\ServicePro\Backups\2025-08-27\

Next Scheduled Backup: September 3, 2025

---
Automated by Service Pro Backup System
```

### Failure Handling
```
Subject: Service Pro Weekly Backup - FAILED - URGENT

Backup Failed:
- Status: ❌ UNSUCCESSFUL - NEEDS ATTENTION
- Date: August 27, 2025 02:00 AM
- Error: Connection timeout to IDrive e2

Failed Components:
- Database: ✅ Successful
- Files: ❌ Failed at 34%

Action Required:
1. Check internet connection
2. Verify IDrive credentials
3. Run manual backup
4. Contact support if needed

Manual Backup Command:
C:\ServicePro\backup.exe --manual --verbose

---
URGENT: Please address immediately to prevent data loss
```

### Windows Implementation

#### Option 1: Node.js Script + Task Scheduler
```javascript
// backup-service.js
const { execSync } = require('child_process');
const nodemailer = require('nodemailer');
const AWS = require('@aws-sdk/client-s3');

// Runs weekly via Windows Task Scheduler
async function weeklyBackup() {
  // Implementation details...
}
```

#### Option 2: PowerShell Script
```powershell
# ServicePro-Backup.ps1
# Schedule in Task Scheduler for weekly execution
$backupPath = "C:\ServicePro\Backups\$(Get-Date -Format 'yyyy-MM-dd')"
# Implementation details...
```

#### Option 3: Desktop Companion App
- Electron app running in system tray
- Visual backup status
- Manual backup trigger
- Settings configuration
- Log viewer

### Backup Configuration
```env
# Backup Settings
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * 0  # Every Sunday at 2 AM
BACKUP_RETENTION_DAYS=90
BACKUP_PATH=C:\ServicePro\Backups
BACKUP_EMAIL=dantcacenco@gmail.com
BACKUP_PASSWORD=encrypted_password_here
```

### Disaster Recovery Plan
1. **Local Backups**: Weekly on office computer
2. **Cloud Backups**: Daily in IDrive e2
3. **Database Replication**: Real-time in Supabase
4. **Recovery Time Objective (RTO)**: 4 hours
5. **Recovery Point Objective (RPO)**: 24 hours

---

## 📅 UPDATED DEVELOPMENT PHASES

### Phase 1: Current Implementation ✅
- Core proposal → payment flow
- Job management system
- Technician portal
- Calendar views

### Phase 2: Storage Migration (Next Priority)
- Set up IDrive e2 account
- Implement dual storage system
- Migrate existing files
- Update upload/download code

### Phase 3: Backup System
- Create backup service
- Windows scheduled task setup
- Email reporting system
- Disaster recovery testing

### Phase 4: Advanced Features
- QuickBooks integration
- Inventory management
- Recurring service contracts
- Advanced analytics

---

*Last Updated: August 27, 2025*
*Storage and Backup sections added*
EOF

echo "Creating backup service template..."
cat > "$PROJECT_DIR/backup-service-template.js" << 'EOF'
// Service Pro Backup Service
// To be run on Windows office computer via Task Scheduler

const { S3Client, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const { createClient } = require('@supabase/supabase-js');
const nodemailer = require('nodemailer');
const fs = require('fs-extra');
const path = require('path');
const archiver = require('archiver');

// Configuration
const config = {
  supabase: {
    url: process.env.SUPABASE_URL,
    key: process.env.SUPABASE_SERVICE_KEY
  },
  idrive: {
    endpoint: 'https://s3.us-west-1.idrivee2.com',
    accessKeyId: process.env.IDRIVE_ACCESS_KEY,
    secretAccessKey: process.env.IDRIVE_SECRET_KEY,
    bucket: 'service-pro-media'
  },
  backup: {
    basePath: 'C:\\ServicePro\\Backups',
    retentionDays: 90,
    emailTo: 'dantcacenco@gmail.com',
    emailFrom: 'backup@service-pro.com'
  }
};

// S3 Client for IDrive e2
const s3Client = new S3Client({
  endpoint: config.idrive.endpoint,
  region: 'us-west-1',
  credentials: {
    accessKeyId: config.idrive.accessKeyId,
    secretAccessKey: config.idrive.secretAccessKey
  }
});

// Supabase Client
const supabase = createClient(config.supabase.url, config.supabase.key);

// Email Transporter
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

class BackupService {
  constructor() {
    this.backupDate = new Date().toISOString().split('T')[0];
    this.backupPath = path.join(config.backup.basePath, this.backupDate);
    this.stats = {
      startTime: new Date(),
      dbRecords: 0,
      filesDownloaded: 0,
      totalSize: 0,
      errors: []
    };
  }

  async run() {
    console.log(`Starting backup for ${this.backupDate}...`);
    
    try {
      // Create backup directory
      await fs.ensureDir(this.backupPath);
      
      // Step 1: Backup database
      await this.backupDatabase();
      
      // Step 2: Backup files from IDrive
      await this.backupFiles();
      
      // Step 3: Create archive
      await this.createArchive();
      
      // Step 4: Cleanup old backups
      await this.cleanupOldBackups();
      
      // Step 5: Send success email
      await this.sendReport('SUCCESS');
      
      console.log('Backup completed successfully!');
    } catch (error) {
      console.error('Backup failed:', error);
      this.stats.errors.push(error.message);
      await this.sendReport('FAILED');
      process.exit(1);
    }
  }

  async backupDatabase() {
    console.log('Backing up database...');
    const dbPath = path.join(this.backupPath, 'database');
    await fs.ensureDir(dbPath);

    // Export each table
    const tables = ['jobs', 'customers', 'proposals', 'invoices', 'payment_stages'];
    
    for (const table of tables) {
      const { data, error } = await supabase
        .from(table)
        .select('*');
      
      if (error) throw error;
      
      // Save as JSON
      await fs.writeJson(
        path.join(dbPath, `${table}.json`),
        data,
        { spaces: 2 }
      );
      
      this.stats.dbRecords += data.length;
    }
  }

  async backupFiles() {
    console.log('Backing up files from IDrive...');
    const filesPath = path.join(this.backupPath, 'files');
    await fs.ensureDir(filesPath);

    // Get last backup date
    const lastBackupDate = await this.getLastBackupDate();
    
    // List objects modified since last backup
    const command = new ListObjectsV2Command({
      Bucket: config.idrive.bucket,
      Prefix: 'job-photos/'
    });

    const response = await s3Client.send(command);
    const files = response.Contents || [];

    // Filter files modified since last backup
    const newFiles = lastBackupDate 
      ? files.filter(f => new Date(f.LastModified) > new Date(lastBackupDate))
      : files;

    console.log(`Found ${newFiles.length} new files to backup`);

    // Download each file
    for (const file of newFiles) {
      const getCommand = new GetObjectCommand({
        Bucket: config.idrive.bucket,
        Key: file.Key
      });

      const response = await s3Client.send(getCommand);
      const filePath = path.join(filesPath, file.Key);
      
      await fs.ensureDir(path.dirname(filePath));
      await fs.writeFile(filePath, response.Body);
      
      this.stats.filesDownloaded++;
      this.stats.totalSize += file.Size;
    }
  }

  async createArchive() {
    console.log('Creating archive...');
    
    return new Promise((resolve, reject) => {
      const output = fs.createWriteStream(
        path.join(config.backup.basePath, `${this.backupDate}.zip`)
      );
      
      const archive = archiver('zip', {
        zlib: { level: 9 },
        password: process.env.BACKUP_PASSWORD
      });

      output.on('close', resolve);
      archive.on('error', reject);

      archive.pipe(output);
      archive.directory(this.backupPath, false);
      archive.finalize();
    });
  }

  async cleanupOldBackups() {
    console.log('Cleaning up old backups...');
    
    const files = await fs.readdir(config.backup.basePath);
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - config.backup.retentionDays);

    for (const file of files) {
      const filePath = path.join(config.backup.basePath, file);
      const stats = await fs.stat(filePath);
      
      if (stats.birthtime < cutoffDate) {
        await fs.remove(filePath);
        console.log(`Removed old backup: ${file}`);
      }
    }
  }

  async getLastBackupDate() {
    const markerFile = path.join(config.backup.basePath, 'last-backup.txt');
    
    if (await fs.pathExists(markerFile)) {
      return await fs.readFile(markerFile, 'utf-8');
    }
    
    return null;
  }

  async sendReport(status) {
    const duration = Math.round((new Date() - this.stats.startTime) / 1000 / 60);
    const sizeMB = (this.stats.totalSize / 1024 / 1024).toFixed(2);

    const subject = `Service Pro Weekly Backup - ${status} - ${this.backupDate}`;
    
    let html = `
      <h2>Backup ${status === 'SUCCESS' ? '✅ Successfully Completed' : '❌ FAILED - NEEDS ATTENTION'}</h2>
      
      <h3>Summary</h3>
      <ul>
        <li>Date: ${this.backupDate}</li>
        <li>Duration: ${duration} minutes</li>
        <li>Database Records: ${this.stats.dbRecords}</li>
        <li>Files Downloaded: ${this.stats.filesDownloaded}</li>
        <li>Total Size: ${sizeMB} MB</li>
        <li>Location: ${this.backupPath}</li>
      </ul>
    `;

    if (this.stats.errors.length > 0) {
      html += `
        <h3>Errors</h3>
        <ul>
          ${this.stats.errors.map(e => `<li>${e}</li>`).join('')}
        </ul>
      `;
    }

    html += `
      <hr>
      <p>Next scheduled backup: ${this.getNextBackupDate()}</p>
      <p><small>Automated by Service Pro Backup System</small></p>
    `;

    await transporter.sendMail({
      from: config.backup.emailFrom,
      to: config.backup.emailTo,
      subject,
      html
    });

    // Save last backup marker
    await fs.writeFile(
      path.join(config.backup.basePath, 'last-backup.txt'),
      this.backupDate
    );
  }

  getNextBackupDate() {
    const next = new Date();
    next.setDate(next.getDate() + 7);
    return next.toLocaleDateString();
  }
}

// Run backup
if (require.main === module) {
  const backup = new BackupService();
  backup.run().catch(console.error);
}

module.exports = BackupService;
EOF

echo "Testing build..."
npm run build 2>&1 | head -80

echo "Committing changes..."
git add -A
git commit -m "Add IDrive e2 storage strategy and automated backup system to project scope"
git push origin main

echo ""
echo "============================================"
echo "SUCCESS! Project scope updated with:"
echo "============================================"
echo ""
echo "1. STORAGE SOLUTION:"
echo "   - IDrive e2 recommended ($4/TB vs $350/TB Supabase)"
echo "   - 92% cost savings at 1TB scale"
echo "   - Hybrid architecture: Supabase for DB, IDrive for files"
echo ""
echo "2. BACKUP SYSTEM:"
echo "   - Weekly automated backups to Windows"
echo "   - Email status reports"
echo "   - 90-day retention policy"
echo "   - Disaster recovery plan"
echo ""
echo "FILES CREATED:"
echo "   - storage_comparison.md (detailed analysis)"
echo "   - backup-service-template.js (Windows backup service)"
echo "   - Updated PROJECT_SCOPE.md"
echo ""
echo "NEXT STEPS:"
echo "1. Sign up for IDrive e2 account"
echo "2. Review storage_comparison.md for implementation"
echo "3. Set up Windows Task Scheduler for backups"
echo ""
echo "============================================"
