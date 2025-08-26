# Storage Permissions SQL

The SQL commands have been saved to `storage-permissions.sql`.

## Quick Setup Instructions:

1. Go to your Supabase SQL Editor:
   https://supabase.com/dashboard/project/dqcxwekmehrqkigcufug/sql/new

2. Copy and paste the entire contents of `storage-permissions.sql`

3. Click "Run" to execute

## What This Enables:

✅ **For Technicians:**
- View photos/files for their assigned jobs
- Upload new photos/files to their assigned jobs
- Cannot access media from jobs they're not assigned to

✅ **Security:**
- Policies enforce that technicians can only access job media where they have a record in `job_technicians` table
- Uses Supabase's built-in auth.uid() to identify the current user

## Verification:

After running the SQL, you can verify the policies were created by running:

```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE policyname LIKE '%Technician%';
```

You should see 8 policies created (4 for storage buckets, 4 for database tables).
