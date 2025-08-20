# Working Session - Service Pro HVAC App
## Updated: August 20, 2025

**Status**: Core features working, technician portal complete  
**Current Branch**: main  
**User**: dantcacenco@gmail.com (role: `boss`)

---

## 🚨 **CRITICAL: ALWAYS CHECK BEFORE PUSHING**

### Before EVERY commit and push:
```bash
# 1. Check TypeScript errors
npx tsc --noEmit

# 2. Test build locally
npm run build

# 3. Only push if both pass!
```

**NO DEPLOYMENTS WITHOUT LOCAL BUILD TEST!**

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

---

## 📁 **Current Features Status**

### ✅ **Working Features:**
1. **Job Management**
   - Create jobs from proposals
   - Edit all job fields
   - Single-page layout (no tabs)
   - Financial tracking with proposal linking
   - Shows balance due

2. **Media Handling**
   - Photos + Videos combined upload
   - File uploads (PDFs, MP3s, documents)
   - Media viewer with arrow key navigation
   - Correct bucket names: `job-photos`, `job-files`

3. **Technician Portal**
   - "My Jobs" shows assigned jobs
   - Time tracking with clock in/out
   - Can edit jobs (no deletion)
   - No financial info visible
   - Customer contact info clickable

4. **Time Tracking**
   - Clock in/out button
   - Editable time entries
   - Shows total hours from all technicians
   - Stored in `job_time_entries` table

---

## 🗄️ **Database Tables**

### Core Tables:
- `profiles` - User profiles with roles
- `jobs` - Main jobs table  
- `job_technicians` - Links technicians to jobs
- `job_photos` - Photos and videos
- `job_files` - Documents and audio files
- `job_time_entries` - Time tracking records
- `customers` - Customer records
- `proposals` - Job proposals
- `payment_stages` - Payment tracking

### Storage Buckets:
- `job-photos` - For photos/videos (public)
- `job-files` - For documents/audio (public)

---

## 🔧 **Common Fixes**

### TypeScript Errors:
```typescript
// Always type setState callbacks
setJob((prev: any) => ({ ...prev, field: value }))

// Check variable names match (camelCase in TS, snake_case in DB)
durationMinutes // TypeScript
duration_minutes // Database
```

### File Upload Issues:
- Bucket: `job-files` (with hyphen)
- Check MIME type AND file extension
- Add contentType to upload options

### Build Errors:
```bash
# Check for type errors
npx tsc --noEmit

# Test build locally BEFORE pushing
npm run build

# Only if both pass, then push
git push origin main
```

---

## 📝 **Component Architecture**

### JobDetailView (Boss):
- Shows all job info including financials
- Time tracking component
- Full edit capabilities
- Can delete jobs

### TechnicianJobDetailView:
- Hides financial info
- Shows time tracking at top
- Can edit but not delete
- Shows customer contact info

### TimeTracking Component:
Props: `jobId`, `userId`, `userRole`
- Clock in/out functionality
- Editable time entries
- Shows total hours

### MediaUpload Component:
- Handles photos AND videos
- 50MB file size limit
- Shows size warnings

---

## 🎯 **Next Steps**
1. Add time tracking to boss JobDetailView
2. Create reports/analytics for time tracking
3. Add job completion workflow
4. Implement payment tracking UI

---

## 💡 **Best Practices**
1. **ALWAYS** test build locally before pushing
2. **ALWAYS** check TypeScript errors
3. Use correct bucket names (with hyphens)
4. Drop policies before creating (no IF NOT EXISTS)
5. Test in incognito/private browser
6. Check console for errors before deploying

---

*Remember: No push without build test!*
