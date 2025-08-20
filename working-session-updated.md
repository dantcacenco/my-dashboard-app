# Working Session - August 19, 2025 (Updated)
## Service Pro - HVAC Field Service Management App

**Status**: Core features working, technician portal needs update  
**Current Branch**: main  
**User**: dantcacenco@gmail.com (role: `boss`)
**Last Update**: Time tracking and technician portal fixes

---

## ⚠️ **IMPORTANT SQL PATTERNS TO AVOID**

### ❌ NEVER use `IF NOT EXISTS` with CREATE POLICY
```sql
-- WRONG - This will cause syntax error
CREATE POLICY IF NOT EXISTS "policy_name" ON table_name

-- CORRECT - Drop first if needed
DROP POLICY IF EXISTS "policy_name" ON table_name;
CREATE POLICY "policy_name" ON table_name
```

### ❌ NEVER use `IF EXISTS` with CREATE POLICY
The `IF EXISTS` / `IF NOT EXISTS` syntax is NOT supported for policies in PostgreSQL.
Always DROP POLICY IF EXISTS first, then CREATE POLICY.

---

## 📁 **Current Project Structure**

```
app/(authenticated)/
├── jobs/
│   ├── [id]/
│   │   ├── page.tsx
│   │   ├── JobDetailView.tsx    ✅ Redesigned - no tabs, all in one page
│   │   └── EditJobModal.tsx
│   ├── new/
│   │   ├── page.tsx
│   │   └── NewJobForm.tsx
│   └── JobsList.tsx
├── technician/
│   └── jobs/                     🔧 NEEDS UPDATE - Show assigned jobs
│       ├── page.tsx
│       └── TechnicianJobsList.tsx
└── proposals/
    └── [id]/
        ├── ProposalView.tsx
        └── CreateJobModal.tsx

components/
├── uploads/
│   ├── PhotoUpload.tsx          ✅ Working
│   ├── FileUpload.tsx           ✅ Fixed - accepts MP3s
│   └── MediaUpload.tsx          ✅ Photos + Videos combined
├── MediaViewer.tsx              ✅ Modal viewer with navigation
└── TimeTracking.tsx             ✅ NEW - Clock in/out component

app/api/
├── jobs/
│   ├── route.ts
│   └── create-from-proposal/route.ts
├── proposals/[id]/route.ts
└── payment-notification/route.ts
```

---

## 🗄️ **Database Schema**

### Tables:
- ✅ `profiles` - User profiles with roles
- ✅ `jobs` - Main jobs table
- ✅ `job_technicians` - Links technicians to jobs
- ✅ `job_photos` - Stores photos/videos
- ✅ `job_files` - Stores files (PDFs, MP3s, etc)
- ✅ `job_time_entries` - NEW - Time tracking
- ✅ `customers`
- ✅ `proposals`
- ✅ `proposal_items`
- ✅ `payment_stages`

### Storage Buckets:
- ✅ `job-photos` (public) - For photos and videos
- ✅ `job-files` (public) - For documents, MP3s, etc

---

## 🎯 **Current Implementation Status**

### ✅ Working Features:
1. Job creation from proposals
2. Photo/video uploads
3. File uploads (including MP3s)
4. Media viewer with navigation
5. Time tracking component created
6. New single-page job layout (no tabs)
7. Financial tracking with proposal linking

### 🔧 Needs Implementation:
1. Update technician portal to show "My Jobs"
2. Integrate TimeTracking component into job views
3. Hide financial info from technicians
4. Allow technicians to edit jobs (except deletion)

---

## 📝 **Key Technical Notes**

### File Upload Issues:
- Bucket name is `job-files` (with hyphen)
- MP3s need explicit mime type handling
- Check file extension if mime type is missing

### RLS Policies:
- Technicians can only see jobs assigned to them
- Boss/admin can see all jobs
- Time entries editable by creator or boss
- Use DROP POLICY IF EXISTS before CREATE POLICY

### Component Props:
- JobDetailView needs `userId` prop
- TimeTracking needs `jobId`, `userId`, `userRole`
- Media components need proper bucket names

---

## 🐛 **Known Issues & Solutions**

### TypeScript Build Errors:
- Always type setState callbacks: `(prev: any) => ...`
- Check imports are named/default correctly

### Storage Issues:
- Ensure buckets are public
- Use correct bucket names (with hyphens)
- Set proper content types for uploads

---

## 📌 **Important Reminders**
- All dates/times stored in UTC
- Technicians cannot see pricing/financial info
- Debug mode: Add ?debug=true to any URL
- Build warnings about SSR don't affect functionality
- NEVER use `IF NOT EXISTS` with CREATE POLICY in SQL

---

*Updated after time tracking implementation*
