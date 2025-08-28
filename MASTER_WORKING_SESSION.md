# MASTER WORKING SESSION - Service Pro HVAC Management System
**Last Updated:** August 28, 2025  
**Version:** 2.0.0 (STABLE)  
**Project Path:** `/Users/dantcacenco/Documents/GitHub/my-dashboard-app`

## 🏗️ SYSTEM ARCHITECTURE UNDERSTANDING

### Core Technology Stack
- **Frontend:** Next.js 15.4.3 (App Router) + TypeScript
- **Database:** Supabase (PostgreSQL with RLS policies)
- **Auth:** Supabase Auth (multi-tenant with roles)
- **Payments:** Stripe (50/30/20 payment split model)
- **Email:** Resend API
- **Storage:** Supabase Storage (job-photos, job-files buckets)
- **UI:** Tailwind CSS + shadcn/ui components
- **Hosting:** Vercel (automatic deployments from GitHub)

### Data Flow Architecture
```
Customer → Proposal → Job → Technician Assignment → Completion → Payment
           ↓          ↓
        Email      Status Sync
           ↓          ↓
        Token    DB Triggers
```

## 🔑 KEY ARCHITECTURAL INSIGHTS

### 1. Database Design Philosophy
The database uses a **denormalized approach with intelligent triggers**:
- **Proposals** are the source of truth for financial data
- **Jobs** are operational entities created from proposals
- **Bidirectional sync** via PostgreSQL triggers maintains consistency
- **Payment tracking** embedded in proposals (deposit_amount, progress_payment_amount, final_payment_amount)

### 2. Status System Architecture
**8 Proposal Statuses** (financial focus):
- `draft`, `sent`, `approved`, `rejected`
- `deposit paid`, `rough-in paid`, `final paid`, `completed`

**5 Job Statuses** (operational focus):
- `not_scheduled`, `scheduled`, `in_progress`, `completed`, `cancelled`

**Sync Rules** (DB triggers handle automatically):
- Proposal payment statuses → Job operational statuses
- Job progress → Proposal status updates
- UI displays the most informative status (proposal takes priority)

### 3. User Role Architecture
```typescript
type UserRole = 'boss' | 'technician' // NOT 'admin'

// Boss sees: Full system, financials, all jobs
// Technician sees: Assigned jobs only, no financials
```

### 4. File Storage Pattern
```javascript
// Storage buckets use hyphens, not underscores
const buckets = {
  photos: 'job-photos',    // NOT job_photos
  files: 'job-files'       // NOT job_files
}

// File path structure:
// {bucket}/{jobId}/{timestamp}_{filename}
```

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

# File operations
desktop-commander:read_file path="/absolute/path"
desktop-commander:write_file path="/absolute/path" content="..."
desktop-commander:edit_block file_path="/path" old_string="exact" new_string="new"

# Process execution
desktop-commander:start_process command="npm run build" timeout_ms=10000
```

### 3. Component Prop Chain Pattern
```typescript
// Server Component (page.tsx) → Client Component chain
// Must pass userId through the entire chain for uploads to work

// page.tsx (server)
const { data: { user } } = await supabase.auth.getUser()
<JobDetailView job={job} userId={user.id} />

// JobDetailView.tsx (client)
<MediaUpload jobId={job.id} userId={userId} />
```

### 4. Error Handling Pattern
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

## 🛠️ SYSTEM CAPABILITIES

### Admin/Boss Features
- **Dashboard:** Revenue metrics, charts, job overview
- **Proposals:** Create, edit, send via email, track status
- **Jobs:** Full CRUD, financial visibility, technician assignment
- **Customers:** Complete management
- **Calendar:** Week/month views with job scheduling
- **Payments:** Track 50/30/20 split, Stripe integration

### Technician Features
- **Limited Dashboard:** Only assigned jobs visible
- **Job Management:** Status updates, photo/video/file uploads
- **Notes System:** Timestamped notes on jobs
- **No Financial Access:** Prices/costs hidden
- **Mobile-Optimized:** Works on phone/tablet

### Customer Features
- **Proposal Viewing:** Token-based access (no login required)
- **Approval System:** One-click approval
- **Payment Tracking:** See payment schedule and status
- **Email Notifications:** Automatic updates

## 🔍 COMMON PITFALLS & SOLUTIONS

### 1. Hydration Errors
**Issue:** React Error #418 - Server/client mismatch
**Solution:** Ensure consistent rendering between server and client
```typescript
// Use suppressHydrationWarning for dynamic content
<div suppressHydrationWarning>{new Date().toLocaleDateString()}</div>
```

### 2. Duplicate Key Violations
**Issue:** Trying to INSERT existing records
**Solution:** Always check existence first
```typescript
const { data: existing } = await supabase
  .from('job_technicians')
  .select('id')
  .eq('job_id', jobId)
  .eq('technician_id', techId)
  .single()

if (!existing) {
  await supabase.from('job_technicians').insert({...})
}
```

### 3. Upload Failures
**Common Causes:**
- Missing userId in prop chain
- Wrong bucket name (use hyphens not underscores)
- RLS policies blocking access
- Storage bucket not public

**Debug Strategy:**
```javascript
console.log('Upload attempt:', { userId, jobId, fileName, bucket })
// Check each step in the upload chain
```

### 4. Status Display Confusion
**Issue:** Job shows wrong status
**Solution:** Use unified display function
```typescript
import { getUnifiedDisplayStatus } from '@/lib/status-sync'
const displayStatus = getUnifiedDisplayStatus(job.status, proposal?.status)
```

## 📂 PROJECT STRUCTURE

```
app/
├── (authenticated)/         # Protected routes
│   ├── jobs/               # Job management
│   │   ├── [id]/          # Job detail with uploads
│   │   └── JobsList.tsx   # List view with status display
│   ├── proposals/          # Proposal system
│   │   └── [id]/edit/     # Edit with payment statuses
│   └── technician/         # Technician portal
├── (public)/               # Public routes
│   └── proposals/[token]/  # Customer proposal view
└── api/                    # API routes
    ├── stripe/             # Payment webhooks
    └── send-proposal/      # Email sending

components/
├── uploads/                # Upload components with debug logs
├── CalendarView.tsx        # Week/month calendar
└── MediaViewer.tsx         # Photo/video viewer

lib/
├── supabase/              # Database client setup
├── status-sync.ts         # Status synchronization logic
└── stripe/                # Payment processing
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

## 🎯 FUTURE DEVELOPMENT INSIGHTS

### Recommended Next Features
1. **Mobile App:** React Native with same Supabase backend
2. **Recurring Jobs:** Template system for regular maintenance
3. **Inventory Management:** Parts tracking with job integration
4. **Customer Portal:** Full dashboard with history
5. **Advanced Reporting:** Analytics and business intelligence

### Scalability Considerations
- **Database:** Add indexes on frequently queried columns
- **Storage:** Implement CDN for media files
- **Auth:** Consider SSO for enterprise clients
- **Performance:** Add Redis caching layer
- **Monitoring:** Implement Sentry for error tracking

## ⚠️ NEVER MODIFY WITHOUT TESTING
1. **Payment routing** (documented in PAYMENT_ROUTING.md)
2. **Customer proposal view UI** (perfectly designed)
3. **Database triggers** (complex bidirectional logic)
4. **Status sync functions** (core business logic)

## 🔐 CREDENTIALS & ENVIRONMENT
```bash
# Database
Project Ref: dqcxwekmehrqkigcufug
URL: https://dqcxwekmehrqkigcufug.supabase.co

# Required .env.local variables
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_OR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
RESEND_API_KEY
STRIPE_SECRET_KEY
STRIPE_PUBLISHABLE_KEY
```

## 📝 DEVELOPMENT PHILOSOPHY
1. **Minimal Changes:** Don't fix what isn't broken
2. **Test First:** Always run build before pushing
3. **Preserve UI:** Don't change design unless explicitly asked
4. **Use Existing Patterns:** Follow established code patterns
5. **Document Intentions:** Clear commit messages

## 🎓 KEY LESSONS LEARNED

### What Works Well
- **Trigger-based sync:** More reliable than application-level sync
- **Token-based access:** Simpler than customer accounts
- **Role-based UI:** Same codebase, different experiences
- **Desktop Commander:** Faster than artifacts for file operations

### What to Avoid
- **Over-engineering:** Simple solutions often work best
- **Breaking changes:** Always maintain backward compatibility
- **Assumption-based fixes:** Always verify with console/logs
- **UI redesigns:** Users prefer consistency

---
**This master document represents the complete understanding of the Service Pro system architecture, patterns, and best practices accumulated across all working sessions.**