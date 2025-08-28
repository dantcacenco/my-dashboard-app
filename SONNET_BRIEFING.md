# Service Pro HVAC App - Sonnet Briefing Document

## 🚨 CRITICAL: READ FIRST
**Project Path**: `/Users/dantcacenco/Documents/GitHub/my-dashboard-app`
**DO NOT**: Create artifacts or .sh files - use Desktop Commander for everything
**ALWAYS**: Check `working_session_aug28.md` first for latest context

## Project Overview
Multi-tenant SaaS for HVAC businesses built with:
- **Next.js 15.4.3** (App Router)
- **Supabase** (PostgreSQL with RLS)
- **Stripe** (Payments)
- **Resend** (Email)
- **Tailwind CSS + shadcn/ui**

## ⚠️ Current Critical Issues (From Console)

### 1. React Minified Error #418
```
Error: Minified React error #418
URL: https://react.dev/errors/418?args[]=&args[0]=
```
**Solution**: Need to check for hydration mismatches or invalid HTML nesting

### 2. Missing API Routes (404 Errors)
```
Failed to load: /invoices/new?job_id=3915209b-93f8-4474-990f-533090b98138&_rsc=uas7n
Failed to load: /job_technicians (status 409)
```
**Required Actions**:
- Create `/app/api/invoices/route.ts`
- Fix job_technicians endpoint duplicate key issue

### 3. Technician Assignment Error
```sql
Error toggling technician:
duplicate key value violates unique constraint "job_technicians_job_id_technician_id_key"
```
**Issue**: Trying to insert duplicate technician assignment
**Fix**: Check if assignment exists before INSERT

## Working Rules & Patterns

### 1. Desktop Commander Only
```bash
# NEVER create .sh files or artifacts
# Instead, run commands directly:
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app && npm run build

# Read files:
desktop-commander:read_file path="/path/to/file"

# Edit files with precision:
desktop-commander:edit_block file_path="/path" old_string="exact text" new_string="replacement"
```

### 2. Database Patterns
```typescript
// Supabase returns OBJECTS not arrays for joins
const { data } = await supabase
  .from('jobs')
  .select(`
    *,
    customers!inner (  // Returns as object, not array
      id, name, email
    )
  `)
  .single()

// Access as: data.customers.name NOT data.customers[0].name
```

### 3. Fix Technician Assignment
```typescript
// In JobDetailView.tsx toggleTechnician function, replace INSERT with:
const toggleTechnician = async (technicianId: string) => {
  const isAssigned = assignedTechnicians.some(t => t.id === technicianId)
  
  if (isAssigned) {
    // Remove assignment
    await supabase
      .from('job_technicians')
      .delete()
      .eq('job_id', job.id)
      .eq('technician_id', technicianId)
  } else {
    // First check if already exists
    const { data: existing } = await supabase
      .from('job_technicians')
      .select('id')
      .eq('job_id', job.id)
      .eq('technician_id', technicianId)
      .single()
    
    if (!existing) {
      // Only insert if doesn't exist
      await supabase
        .from('job_technicians')
        .insert({ job_id: job.id, technician_id: technicianId })
    }
  }
  loadAssignedTechnicians()
}
```

### 4. Create Missing Invoice Route
```typescript
// Create: /app/api/invoices/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = await createClient()
  const { searchParams } = new URL(request.url)
  const jobId = searchParams.get('job_id')
  
  if (!jobId) {
    return NextResponse.json({ error: 'Job ID required' }, { status: 400 })
  }
  
  const { data, error } = await supabase
    .from('invoices')
    .select('*')
    .eq('job_id', jobId)
    .order('created_at', { ascending: false })
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
  
  return NextResponse.json(data)
}

export async function POST(request: Request) {
  const supabase = await createClient()
  const body = await request.json()
  
  const { data, error } = await supabase
    .from('invoices')
    .insert(body)
    .select()
    .single()
  
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }
  
  return NextResponse.json(data)
}
```

## File Structure Context
```
app/(authenticated)/jobs/[id]/
  ├── JobDetailView.tsx     ← Main component (NOT JobDetailsView with 's')
  ├── EditJobModal.tsx      ← Connected and working
  ├── page.tsx              ← Entry point, passes userId
  └── diagnostic.tsx        ← Debug tool

components/uploads/
  ├── MediaUpload.tsx       ← Has debug logs for photos
  └── FileUpload.tsx        ← Has debug logs for files
```

## Upload Debug Strategy
Debug logs are already in place. To identify issue:
1. Open browser console
2. Try upload
3. Check for these common issues:
   - Missing userId in props chain
   - Storage bucket name mismatch (job-photos vs job_photos)
   - RLS policy blocking INSERT
   - Storage bucket not public

## Database Tables & RLS
```sql
-- Check if user has INSERT permission
SELECT * FROM pg_policies WHERE tablename = 'job_technicians';

-- Storage buckets should be:
-- 'job-photos' (with hyphen)
-- 'job-files' (with hyphen)
```

## Testing Commands
```bash
# Build test (catches TypeScript errors)
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app && npm run build 2>&1 | head -80

# Type check only
npx tsc --noEmit

# Git workflow
git add -A && git commit -m "Fix: [description]" && git push origin main
```

## Response Style Requirements
1. **Non-verbose**: Direct solutions only
2. **Single solution**: One comprehensive fix per issue
3. **Test before push**: Always run build test
4. **Use Desktop Commander**: Never create .sh files or artifacts
5. **Minimal edits**: Change only what's necessary

## Priority Fix Order
1. ✅ Fix technician duplicate key error (code above)
2. ✅ Create invoice API route (code above)  
3. ✅ Test uploads with console to identify specific failure
4. ⏳ Fix any React hydration issues if persistent

## Environment Variables
All configured in `.env.local`:
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_PUBLISHABLE_OR_ANON_KEY
- RESEND_API_KEY
- STRIPE_SECRET_KEY

## Common Pitfalls to Avoid
1. **DON'T** use `job.customers[0]` - it's `job.customers` (object not array)
2. **DON'T** create new UI unless asked - preserve existing design
3. **DON'T** use relative paths - always use absolute paths
4. **DON'T** assume storage bucket names - verify exact names
5. **DON'T** forget to check if technician already assigned before INSERT

## Success Criteria
- No console errors
- Uploads working (photos and files)
- Technicians can be assigned/unassigned without errors
- Build passes without warnings
