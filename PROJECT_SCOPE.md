# Service Pro - HVAC Field Service Management System
## Comprehensive Project Scope Document

**Last Updated**: August 27, 2025  
**Version**: 2.1  
**Tech Stack**: Next.js 15.4.3, Supabase, Stripe, Vercel, Resend  

---

## 🎯 PROJECT OVERVIEW

Service Pro is a multi-tenant SaaS application for HVAC field service businesses, similar to Housecall Pro. It manages the complete workflow from proposal creation to payment collection with a focus on customer self-service and multi-stage payment processing.

### Core Business Flow
1. **Admin** creates proposals with services and optional add-ons
2. **Customer** receives proposal link via email (no login required)
3. **Customer** reviews, selects add-ons, approves/rejects proposal
4. **Upon approval**, customer pays in 3 stages (50% deposit, 30% rough-in, 20% final)
5. **System** tracks payments, creates jobs, generates invoices

---

## 💾 STORAGE ARCHITECTURE & MIGRATION PLAN

### Current Problem
- **Supabase Storage**: $35/mo for only 100GB - completely insufficient
- **HVAC Requirements**: 5-10 year photo/video retention for warranties
- **Estimated Need**: 1-5TB within first year, 10-20TB over 5 years
- **Current Cost Projection**: $350-700/mo with Supabase (unsustainable)

### Recommended Hybrid Architecture

#### Keep in Supabase (Fast, Small Data)
- **Database**: All relational data (jobs, customers, proposals)
- **Authentication**: User accounts and sessions
- **Real-time**: Live updates for technicians
- **Small Files**: Profile photos, company logos
- **Temporary Files**: Recent uploads (last 30 days)

#### Migrate to IDrive e2 (Massive Storage)
- **Job Photos/Videos**: All field documentation
- **Project Files**: PDFs, manuals, warranties
- **Historical Data**: Archived jobs older than 30 days
- **Backup Archives**: Weekly backup snapshots

### Storage Cost Comparison (Monthly)
| Storage | Supabase | IDrive e2 | Cloudflare R2 | Backblaze B2 | AWS S3 |
|---------|----------|-----------|---------------|--------------|--------|
| 100GB | $35 | $0.40 | $1.50 | $0.60 | $2.30 |
| 500GB | $175 | $2.00 | $7.50 | $3.00 | $11.50 |
| 1TB | $350 | $4.00 | $15.00 | $6.00 | $23.00 |
| 5TB | N/A | $20.00 | $75.00 | $30.00 | $115.00 |
| 10TB | N/A | $40.00 | $150.00 | $60.00 | $230.00 |

### Why IDrive e2?
- **Ultra-Low Cost**: $0.004/GB/month (87% cheaper than R2, 99% cheaper than Supabase)
- **S3 Compatible**: Works with existing S3 SDKs and tools
- **No Vendor Lock-in**: Standard S3 API means easy migration if needed
- **Good Performance**: CDN integration available if needed
- **No Egress Fees**: First 3x storage free egress monthly

### Migration Implementation Plan

#### Phase 1: Setup (Week 1)
```javascript
// Install AWS SDK (works with IDrive e2)
npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner

// Environment variables to add
IDRIVE_E2_ENDPOINT=https://[endpoint].idrivee2.com
IDRIVE_E2_ACCESS_KEY=xxx
IDRIVE_E2_SECRET_KEY=xxx
IDRIVE_E2_BUCKET=service-pro-media
IDRIVE_E2_REGION=us-east-1
```

#### Phase 2: Dual Upload (Week 2-3)
- Continue uploading to Supabase (for immediate access)
- Simultaneously upload to IDrive e2 (for long-term storage)
- Keep last 30 days in Supabase for fast access

#### Phase 3: Migration Script (Week 4)
- Migrate all existing Supabase files to IDrive e2
- Update database URLs to point to IDrive e2
- Implement CDN for frequently accessed files

#### Phase 4: Cleanup (Week 5)
- Remove old files from Supabase (keep only recent)
- Reduce Supabase plan to save costs
- Monitor performance and adjust CDN settings

---

## 🔐 AUTOMATED BACKUP SYSTEM

### Requirements
- **Frequency**: Weekly automated backups (every Sunday night)
- **Scope**: All jobs, photos, files, and database exports
- **Storage**: Local download to office Windows computer
- **Redundancy**: Keep last 12 weeks of backups
- **Notification**: Email report after each backup

### Backup Architecture

#### What Gets Backed Up
1. **Database Export**: Full PostgreSQL dump
2. **Job Data**: All job records as JSON
3. **Media Files**: Photos/videos from IDrive e2
4. **Documents**: Proposals, invoices, reports
5. **Customer Data**: Encrypted customer records

#### Backup Process Flow
```mermaid
1. GitHub Actions / Node Schedule (Sunday 2 AM)
2. Export database to SQL dump
3. Download media from IDrive e2
4. Create timestamped ZIP archive
5. Upload to backup location
6. Send email report via Resend
7. Clean up old backups (>12 weeks)
```

#### Implementation Components

##### 1. Backup Script (runs on server/cloud function)
```javascript
// backup-service.js
async function weeklyBackup() {
  const timestamp = new Date().toISOString()
  const backupId = `backup_${timestamp}`
  
  try {
    // 1. Export database
    await exportDatabase(backupId)
    
    // 2. Download media files
    await downloadMediaFiles(backupId)
    
    // 3. Create ZIP archive
    await createArchive(backupId)
    
    // 4. Upload to Windows share or FTP
    await uploadToOfficePC(backupId)
    
    // 5. Send success email
    await sendBackupReport({
      status: 'success',
      backupId,
      size: getBackupSize(backupId),
      timestamp
    })
    
  } catch (error) {
    // Send failure email
    await sendBackupReport({
      status: 'failure',
      error: error.message,
      timestamp
    })
  }
}
```

##### 2. Email Report Template
```html
Subject: [Service Pro] Weekly Backup Report - {DATE}

Status: ✅ Successfully Backed Up / ❌ Backup Failed

Backup Details:
- Backup ID: {BACKUP_ID}
- Date: {DATE}
- Total Size: {SIZE}
- Jobs Backed Up: {JOB_COUNT}
- Photos/Videos: {MEDIA_COUNT}
- Location: \\OFFICE-PC\Backups\{BACKUP_ID}

Next Backup: {NEXT_DATE}

Action Required: {ACTION_IF_FAILED}
```

##### 3. Windows Integration Options

**Option A: Network Share**
- Set up SMB share on office Windows PC
- Backup script uploads via SMB protocol
- Requires VPN for remote access

**Option B: OneDrive Business**
- Use OneDrive API for uploads
- Automatic sync to Windows PC
- Built-in versioning and recovery

**Option C: FTP Server**
- Run FTP server on Windows PC
- Secure FTPS for encrypted transfer
- Schedule Windows Task to organize files

### Backup Restoration Process
1. Locate backup file by date
2. Extract ZIP archive
3. Restore database from SQL dump
4. Re-upload media files to IDrive e2
5. Update URLs in database if needed
6. Verify data integrity

### Monitoring & Alerts
- **Success**: Green checkmark email every Sunday
- **Warning**: Yellow alert if backup is smaller than expected
- **Failure**: Red alert with immediate retry
- **Missing**: Alert if no backup for 10 days

---

## 🗄️ DATABASE STRUCTURE (ACTUAL FROM SUPABASE)

### Key Tables

#### `proposals` Table
Critical columns with naming inconsistencies (BOTH exist):
- `deposit_amount` - 50% deposit amount
- `progress_payment_amount` AND `progress_amount` - 30% rough-in amount
- `final_payment_amount` AND `final_amount` - 20% final amount
- `total` - Total proposal amount (NOT `total_amount`)
- `subtotal` - Amount before tax
- `tax_amount` - Tax amount
- `customer_view_token` - Unique token for customer access
- `payment_stage` - Current payment stage ('deposit', 'roughin', 'final', 'complete')
- `deposit_paid_at`, `progress_paid_at`, `final_paid_at` - Payment timestamps
- `total_paid` - Running total of payments received

#### `payment_stages` Table (EXISTS)
- `id`, `proposal_id`, `stage`
- `percentage`, `amount`, `due_date`
- `paid`, `paid_at`
- `stripe_session_id`, `stripe_payment_intent_id`
- `created_at`, `updated_at`

#### `customers` Table
- Standard fields: `id`, `name`, `email`, `phone`, `address`
- `created_by`, `updated_by` - User references

#### `profiles` Table
- `role` field contains: 'boss', 'admin', or 'technician'
- Current user (dantcacenco@gmail.com) has role: 'boss'

### Critical Data Structure Facts
1. **Supabase joins return OBJECTS not arrays**
   - ✅ CORRECT: `proposal.customers.name`
   - ❌ WRONG: `proposal.customers[0].name`
2. **User role is 'boss' not 'admin'** - but code should check for both
3. **Both column name variants exist** in proposals table

---

## 📁 PROJECT STRUCTURE

```
/app
├── (authenticated)/          # Protected routes requiring login
│   ├── proposals/           # Admin proposal management
│   │   ├── page.tsx        # List all proposals
│   │   ├── ProposalsList.tsx
│   │   ├── [id]/
│   │   │   ├── page.tsx    # View single proposal
│   │   │   ├── ProposalView.tsx
│   │   │   ├── SendProposal.tsx
│   │   │   ├── PaymentStages.tsx
│   │   │   └── edit/       # Edit proposal
│   │   └── new/            # Create proposal
│   ├── dashboard/          # Admin dashboard
│   ├── customers/          # Customer management
│   ├── jobs/              # Job tracking
│   ├── invoices/          # Invoice management
│   └── technicians/       # Technician management
│
├── proposal/               # PUBLIC customer-facing routes (no auth)
│   ├── view/
│   │   └── [token]/       # Token-based proposal viewing
│   │       ├── page.tsx
│   │       └── CustomerProposalView.tsx
│   └── payment-success/   # Stripe payment return
│
├── api/
│   ├── create-payment/    # Stripe checkout session creation
│   ├── proposal-approval/ # Handle approval/rejection
│   ├── send-proposal/     # Email proposal to customer
│   ├── backup/            # Backup automation endpoints
│   └── stripe/
│       └── webhook/       # Process Stripe events
│
/components
├── PaymentStages.tsx      # Reusable payment stages display
├── MultiStagePayment.tsx  # Multi-stage payment handler
└── SendProposal.tsx       # Send proposal modal
```

---

## 💰 PAYMENT FLOW IMPLEMENTATION

### Current Implementation Status
1. ✅ Stripe integration configured (API version: '2025-07-30.basil')
2. ✅ Multi-stage payment UI components exist
3. ✅ Payment stages table exists in database
4. ⚠️ Payment flow partially implemented but needs consolidation

### Desired Payment Flow
1. **Customer views proposal** → Shows "Approve Proposal" button
2. **Customer approves** → Page refreshes, approval button disappears
3. **Payment stages appear**:
   - 50% Deposit: ✅ Active "Pay Now" button
   - 30% Rough-in: 🔒 Grayed out (locked)
   - 20% Final: 🔒 Grayed out (locked)
4. **After deposit paid** → Returns to same page:
   - Deposit shows as paid ✅
   - Rough-in becomes active
5. **Progressive unlocking** continues through all stages
6. **All payments complete** → Status changes to 'complete'

### Payment Technical Details
- Amounts stored in DOLLARS (not cents) in database
- Stripe requires amounts in CENTS (multiply by 100)
- Return URL after payment: `/proposal/view/[token]`
- Each payment updates both `proposals` and `payment_stages` tables

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### User Roles
- **boss/admin**: Full system access (treat these as equivalent)
- **technician**: Limited access to assigned jobs
- **customer**: No login required, token-based proposal access

### Route Protection
- `/app/(authenticated)/*`: Requires login and boss/admin role
- `/app/proposal/*`: PUBLIC routes, no authentication required
- Middleware must allow public paths for customer access

### Role Check Pattern
```typescript
// Always check for BOTH roles
if (profile?.role !== 'admin' && profile?.role !== 'boss') {
  redirect('/')
}
```

---

## 🚀 ENVIRONMENT CONFIGURATION

### Required Environment Variables (All configured in Vercel)
```
# Supabase
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY

# Stripe
STRIPE_SECRET_KEY
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
STRIPE_WEBHOOK_SECRET

# Resend Email
RESEND_API_KEY
EMAIL_FROM=onboarding@resend.dev
BUSINESS_EMAIL=dantcacenco@gmail.com

# IDrive e2 (To be added)
IDRIVE_E2_ENDPOINT
IDRIVE_E2_ACCESS_KEY
IDRIVE_E2_SECRET_KEY
IDRIVE_E2_BUCKET
IDRIVE_E2_REGION

# Optional but recommended
NEXT_PUBLIC_BASE_URL
```

---

## ⚠️ CRITICAL IMPLEMENTATION NOTES

### Database Column Usage Rules
1. **Use the longer column names** for consistency:
   - Use `progress_payment_amount` not `progress_amount`
   - Use `final_payment_amount` not `final_amount`
   - Use `total` not `total_amount`

2. **Customer Data Access**:
   - Customers is an OBJECT: `proposal.customers.name`
   - NOT an array: ~~`proposal.customers[0].name`~~

3. **Role Checking**:
   - Always check for both 'boss' and 'admin'
   - Plan to migrate all to 'admin' in future

4. **Payment Processing**:
   - Database stores amounts in dollars
   - Stripe needs cents (multiply by 100)
   - Use lowercase stage names: 'deposit', 'roughin', 'final'

5. **Testing Requirements**:
   - Always test customer flows in incognito/private browser
   - Verify token-based access works without login
   - Check payment flow returns to proposal view

---

## 🎯 CURRENT PRIORITIES

### Immediate Issues to Fix
1. **Photo display issue** - Debug why thumbnails don't show in technician portal
2. **Consolidate payment flow** - Single implementation in CustomerProposalView
3. **Update all role checks** to use 'admin' consistently
4. **Fix column name inconsistencies** throughout codebase

### Next Phase Features
1. **IDrive e2 Storage Migration** - Implement dual upload system
2. **Automated Weekly Backups** - Set up backup service with email reports
3. Job creation from approved proposals
4. Invoice generation from completed jobs
5. Technician assignment and scheduling
6. Email notifications for payment reminders
7. Migration to Bill.com for payment processing

---

## 📝 DEVELOPMENT GUIDELINES

### Code Standards
- Single comprehensive .sh scripts for all changes
- Complete file replacements (no sed/grep)
- Test builds before committing
- Clear, descriptive commit messages
- Always push to main branch
- Minimize Vercel deployments (100/day limit on free plan)

### Testing Protocol
1. Run TypeScript check: `npx tsc --noEmit`
2. Test build: `npm run build`
3. Test in private browser for customer flows
4. Verify Stripe webhooks fire correctly
5. Check database updates

### File Change Strategy
- Replace entire files to avoid conflicts
- Keep backups of working versions
- Test after every major change
- Batch commits to preserve Vercel deployment limit
- **DELETE temporary scripts immediately after use**

### 🧹 Project Hygiene Rules
1. **No accumulation of .sh scripts** - Delete after execution
2. **Clean up backup files** - Remove .backup, .bak files after confirming changes work
3. **Remove old log files** - build.log, type_check.log, etc.
4. **Keep only essential documentation**:
   - PROJECT_SCOPE.md (this file - master reference)
   - WORKING_SESSION.md (current active tasks)
   - README.md (standard project readme)
5. **Git commit cleanup changes** immediately

### Cleanup Command
```bash
# Run periodically to clean up project
rm -f *.sh *.log *.backup *.bak
find . -name "*.backup" -type f -delete
find . -name "*.bak" -type f -delete
```

---

## 🔄 KNOWN ISSUES & SOLUTIONS

### Issue: Photos not showing thumbnails
**Solution**: Check browser console for CORS errors, verify URLs are properly formatted

### Issue: Payment stages not displaying
**Solution**: Ensure `payment_stages` table is populated after proposal approval

### Issue: Customer can't access proposal
**Solution**: Check middleware allows `/proposal/view/*` as public path

### Issue: Role authorization failures
**Solution**: Update all checks to include both 'boss' and 'admin'

### Issue: Payment amounts incorrect
**Solution**: Use correct column names and ensure dollar/cent conversion

---

## 📚 REFERENCE QUERIES

### Useful SQL Queries
```sql
-- Check user role
SELECT role FROM profiles 
WHERE email = 'dantcacenco@gmail.com';

-- View proposal with customer
SELECT p.*, c.* 
FROM proposals p 
LEFT JOIN customers c ON p.customer_id = c.id 
LIMIT 1;

-- Check payment stages
SELECT * FROM payment_stages 
WHERE proposal_id = '[PROPOSAL_ID]'
ORDER BY stage;

-- Check photo URLs
SELECT url, media_type 
FROM job_photos 
WHERE job_id = '[JOB_ID]';
```

---

This document represents the authoritative source for project understanding. Any conflicting information in other documents should defer to this scope.