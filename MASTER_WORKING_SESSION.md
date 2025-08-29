# MASTER WORKING SESSION - Service Pro HVAC Management System
**Last Updated:** August 28, 2025  
**Version:** 2.2 STABLE  
**Project Path:** `/Users/dantcacenco/Documents/GitHub/my-dashboard-app`

## 🏗️ SYSTEM ARCHITECTURE UNDERSTANDING

### Core Technology Stack
- **Frontend:** Next.js 15.4.3 (App Router) + TypeScript
- **Database:** Supabase (PostgreSQL with RLS policies)
- **Auth:** Supabase Auth (multi-tenant with roles)
- **Payments:** Stripe (50/30/20 payment split model) - Moving to Bill.com
- **Email:** Resend API (⚠️ NEEDS PRODUCTION SETUP)
- **Storage:** Supabase Storage (job-photos, job-files buckets)
- **UI:** Tailwind CSS + shadcn/ui components
- **Hosting:** Vercel (automatic deployments from GitHub)

### Data Flow Architecture
```
Customer → Proposal → Job → Technician Assignment → Completion → Payment → Reminders
           ↓          ↓                                    ↓           ↓
        Email      Status Sync                     Auto Reminders   Admin Alerts
           ↓          ↓                                    ↓           ↓
        Token    DB Triggers                        Email Queue   Dashboard
```

## 🔑 KEY ARCHITECTURAL INSIGHTS

### 1. Database Design Philosophy
The database uses a **denormalized approach with intelligent triggers**:
- **Proposals** are the source of truth for financial data
- **Jobs** are operational entities created from proposals
- **Bidirectional sync** via PostgreSQL triggers maintains consistency
- **Payment tracking** embedded in proposals (deposit_amount, progress_payment_amount, final_payment_amount)
- **Time tracking** via time_entries table for technician hours

### 2. Status System Architecture (Version 2.2)

#### Dual Status System (Planned Enhancement)
**Work Status** (Technician-controlled):
- `not_scheduled`, `scheduled`, `work_started`, `in_progress`
- `rough_in_complete`, `work_complete`, `cancelled`

**Payment Status** (System-controlled):
- `pending`, `deposit_paid`, `rough_in_paid`, `final_paid`, `paid_in_full`

**Current Implementation:**
- **8 Proposal Statuses:** `draft`, `sent`, `approved`, `rejected`, `deposit paid`, `rough-in paid`, `final paid`, `completed`
- **5 Job Statuses:** `not_scheduled`, `scheduled`, `in_progress`, `completed`, `cancelled`

### 3. User Role Architecture
```typescript
type UserRole = 'boss' | 'technician' // NOT 'admin'
// Boss sees: Full system, financials, all jobs
// Technician sees: Assigned jobs only, no financials, time tracking
```

### 4. File Storage Pattern
```javascript
// Storage buckets use hyphens, not underscores
const buckets = {
  photos: 'job-photos',    // NOT job_photos
  files: 'job-files'       // NOT job_files
}
// File path structure: {bucket}/{jobId}/{timestamp}_{filename}
```

## ✅ COMPLETED IN VERSION 2.2

### Session Date: August 28, 2025

#### 1. Admin Dashboard Improvements
- ✅ Removed metric boxes for cleaner interface
- ✅ Calendar defaults to expanded view
- ✅ Calendar has Week/Month toggle with hourly slots (7 AM - 7 PM)
- ✅ Recent Proposals scrollable list (15 items)
- ✅ Recent Activities shows comprehensive data from last 7 days

#### 2. Technician Portal Complete Overhaul
- ✅ **Calendar View:** Added with Week/Month toggle
- ✅ **Time Sheet Feature:** Start/Stop timer with database tracking
- ✅ **Photo/File Display:** Fixed thumbnails and viewer
- ✅ **Notes System:** Changed to single editable field
- ✅ **Status Updates:** Work Started, Rough-In Done, Job Started, Final Done
- ✅ **Navigation Fix:** Calendar modal links to technician routes

#### 3. Database Enhancements
- ✅ Created `time_entries` table for time tracking
- ✅ Added PostgreSQL direct connection string to .env.local
- ✅ Implemented proper error handling for missing tables

#### 4. UI/UX Improvements
- ✅ Proposal Details shows in view mode (not just edit)
- ✅ Job Title auto-fills from Proposal Title
- ✅ Removed Actions column from Proposals list
- ✅ Removed "Click filename to view" text
- ✅ Status sync between jobs and proposals

#### 5. Documentation Created
- ✅ Comprehensive Bill.com integration plan
- ✅ Status and payment reminder strategy
- ✅ Database migration scripts

## 📋 IMPLEMENTATION REQUIREMENTS

### 1. Resend API Production Setup
**⚠️ CRITICAL:** Currently using test mode - only sends to dantcacenco@gmail.com
```env
# NEEDS PRODUCTION CONFIGURATION
RESEND_API_KEY=re_hR5Qg7qC_7K3XcjzyGMztvaavZoGUoc6m  # Test key
EMAIL_FROM=onboarding@resend.dev  # Needs custom domain
```

**Required Actions:**
1. Verify domain in Resend dashboard
2. Switch to production API key
3. Update EMAIL_FROM to company domain
4. Test with real customer emails

### 2. Cross-Browser/Device Compatibility
**Known Issues to Test:**
- Android Chrome: Upload components
- Safari (iOS/macOS): Date picker formatting
- Windows Edge: PDF viewer in documents
- Mobile browsers: Calendar touch interactions

**Testing Matrix Needed:**
- [ ] Chrome (Windows, Mac, Android)
- [ ] Safari (iOS, macOS)
- [ ] Firefox (Desktop)
- [ ] Edge (Windows)
- [ ] Mobile responsive (iPhone, Android)

### 3. Automated Payment Reminder System

#### Trigger: Job Marked "work_complete"
**Day 0:** Completion email with payment link
**Day 2:** First friendly reminder
**Day 7:** Second reminder + Admin alert for phone follow-up
**Weekly:** Continued reminders to both customer and admin

#### Database Requirements
```sql
-- Add to jobs table
ALTER TABLE jobs ADD COLUMN work_status VARCHAR(50);
ALTER TABLE jobs ADD COLUMN work_completed_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN payment_status VARCHAR(50);

-- Reminder tracking
CREATE TABLE payment_reminders (
  id UUID PRIMARY KEY,
  job_id UUID REFERENCES jobs(id),
  reminder_type VARCHAR(50),
  sent_at TIMESTAMP DEFAULT NOW()
);

-- Scheduled reminders
CREATE TABLE reminder_schedule (
  id UUID PRIMARY KEY,
  job_id UUID REFERENCES jobs(id),
  scheduled_for TIMESTAMP,
  reminder_type VARCHAR(50),
  status VARCHAR(50) DEFAULT 'pending'
);
```

### 4. Bill.com API Integration Plan

#### Phase 1: Environment Setup
```env
BILLCOM_DEV_KEY=
BILLCOM_ORG_ID=
BILLCOM_USERNAME=
BILLCOM_PASSWORD=
PAYMENT_PROVIDER=billcom  # or stripe
```

#### Phase 2: Core Functions
- Customer sync with Bill.com
- Invoice creation from proposals
- Payment webhook processing
- ACH payment support

#### Implementation Timeline
- **Weeks 1-2:** Research & Setup
- **Weeks 3-4:** Core Implementation
- **Weeks 5-6:** Integration
- **Weeks 7-8:** Testing
- **Weeks 9-10:** Rollout

#### Benefits
- Lower fees with ACH payments
- Better accounting integration
- Automated AR/AP
- Professional invoicing

## 💡 CRITICAL PATTERNS DISCOVERED

### 1. Supabase Join Pattern
```typescript
// ❌ WRONG - Supabase returns OBJECT not ARRAY for single joins
const customer = job.customers[0] // This will fail

// ✅ CORRECT - Direct object access
const customer = job.customers    // Returns object when using !inner join
```

### 2. Desktop Commander Pattern
```bash
# ❌ NEVER create .sh files or use artifacts
# ✅ ALWAYS use Desktop Commander directly
desktop-commander:read_file path="/absolute/path"
desktop-commander:write_file path="/absolute/path" content="..."
desktop-commander:edit_block file_path="/path" old_string="exact" new_string="new"
```

### 3. PostgreSQL Direct Access
```bash
# Database connection for SQL queries
DATABASE_URL=postgresql://postgres.dqcxwekmehrqkigcufug:zEnhom-qaxfir-2xypmi@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# Usage examples:
psql "$DATABASE_URL" -c "SELECT * FROM jobs LIMIT 5;"
psql "$DATABASE_URL" -f migration.sql
```

### 4. Component Prop Chain Pattern
```typescript
// Server Component (page.tsx) → Client Component chain
// Must pass userId through the entire chain for uploads to work
const { data: { user } } = await supabase.auth.getUser()
<JobDetailView job={job} userId={user.id} />
```

### 5. Error Handling Pattern
```typescript
// Always check for duplicate before INSERT
const { data: existing } = await supabase
  .from('table')
  .select('id')
  .eq('key', value)
  .single()

if (!existing) {
  // Safe to insert
}
```

## 🚀 DEPLOYMENT & TESTING

### Build & Deploy
```bash
# Local build test
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app
npm run build

# Deploy (automatic via Vercel on push)
git add -A && git commit -m "Description" && git push origin main
```

### Testing Checklist
1. **Status Sync:** Change job status → Check proposal updates
2. **Uploads:** Test photo/video upload with console open
3. **Technician Assignment:** Assign/unassign without duplicates
4. **Payment Flow:** Customer approval → Payment status updates
5. **Email:** Send proposal → Check token access works
6. **Time Tracking:** Start/Stop timer → Verify database entries
7. **Calendar:** Week/Month views → Job modal navigation

## 🎯 NEXT PHASE DEVELOPMENT

### Immediate Priorities
1. **Resend API Production Setup** - Enable real customer emails
2. **Dual Status System** - Separate work and payment tracking
3. **Payment Reminders** - Automated follow-up system
4. **Cross-browser Testing** - Fix compatibility issues

### Phase 2 Features
1. **Bill.com Integration** - Replace Stripe gradually
2. **SMS Reminders** - Twilio integration
3. **Customer Portal** - Payment history access
4. **Mobile App** - React Native version
5. **Advanced Reporting** - Analytics dashboard

### Scalability Considerations
- **Database:** Add indexes on frequently queried columns
- **Storage:** Implement CDN for media files
- **Auth:** Consider SSO for enterprise clients
- **Performance:** Add Redis caching layer
- **Monitoring:** Implement Sentry for error tracking

## ⚠️ NEVER MODIFY WITHOUT TESTING
1. **Payment routing** (working perfectly)
2. **Customer proposal view UI** (perfectly designed)
3. **Database triggers** (complex bidirectional logic)
4. **Status sync functions** (core business logic)
5. **Webhook processing** (payment critical)

## 🔐 CREDENTIALS & ENVIRONMENT
```bash
# Database
Project Ref: dqcxwekmehrqkigcufug
URL: https://dqcxwekmehrqkigcufug.supabase.co
Direct SQL: postgresql://postgres.dqcxwekmehrqkigcufug:zEnhom-qaxfir-2xypmi@aws-0-us-east-1.pooler.supabase.com:6543/postgres

# Required .env.local variables
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_OR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
RESEND_API_KEY  # ⚠️ Needs production key
STRIPE_SECRET_KEY
STRIPE_PUBLISHABLE_KEY
DATABASE_URL  # PostgreSQL direct connection
```

## 📝 DEVELOPMENT PHILOSOPHY
1. **Minimal Changes:** Don't fix what isn't broken
2. **Test First:** Always run build before pushing
3. **Preserve UI:** Don't change design unless explicitly asked
4. **Use Existing Patterns:** Follow established code patterns
5. **Document Intentions:** Clear commit messages
6. **Clean Project:** Delete temp files immediately after use

## 🎓 KEY LESSONS LEARNED

### What Works Well
- **Trigger-based sync:** More reliable than application-level sync
- **Token-based access:** Simpler than customer accounts
- **Role-based UI:** Same codebase, different experiences
- **Desktop Commander:** Faster than artifacts for file operations
- **Direct SQL access:** Essential for migrations

### What to Avoid
- **Over-engineering:** Simple solutions often work best
- **Breaking changes:** Always maintain backward compatibility
- **Assumption-based fixes:** Always verify with console/logs
- **UI redesigns:** Users prefer consistency
- **Test-only APIs:** Switch to production for real usage

## 🔍 COMMON PITFALLS & SOLUTIONS

### 1. Hydration Errors
**Issue:** React Error #418 - Server/client mismatch
**Solution:** Use suppressHydrationWarning for dynamic content

### 2. Duplicate Key Violations
**Issue:** Trying to INSERT existing records
**Solution:** Always check existence first

### 3. Upload Failures
**Common Causes:**
- Missing userId in prop chain
- Wrong bucket name (use hyphens not underscores)
- RLS policies blocking access

### 4. Status Display Confusion
**Issue:** Job shows wrong status
**Solution:** Use unified display function from lib/status-sync

### 5. Time Entries Table Missing
**Issue:** Timesheet feature fails
**Solution:** Run migration in database_migrations/create_time_entries_table.sql

## 📂 PROJECT STRUCTURE

```
app/
├── (authenticated)/         # Protected routes
│   ├── jobs/               # Job management with time tracking
│   ├── proposals/          # Proposal system
│   └── technician/         # Technician portal with calendar
├── (public)/               # Public routes
│   └── proposals/[token]/  # Customer proposal view
└── api/                    # API routes
    ├── stripe/             # Payment webhooks
    ├── billcom/            # Future Bill.com integration
    └── send-proposal/      # Email sending

components/
├── uploads/                # Upload components
├── CalendarView.tsx        # Week/month calendar (7am-7pm)
└── MediaViewer.tsx         # Photo/video viewer

lib/
├── supabase/              # Database client
├── status-sync.ts         # Status synchronization
├── stripe/                # Payment processing
└── billcom/               # Future integration

database_migrations/
└── create_time_entries_table.sql  # Time tracking setup
```

---
**This master document represents the complete understanding of the Service Pro system architecture, completed features, and future development roadmap as of Version 2.2 STABLE.**