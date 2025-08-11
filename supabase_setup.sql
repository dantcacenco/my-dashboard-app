-- 1. Create storage bucket for job photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('job-photos', 'job-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Set up storage policies for job photos
CREATE POLICY "Authenticated users can upload job photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'job-photos');

CREATE POLICY "Anyone can view job photos" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'job-photos');

CREATE POLICY "Authenticated users can update job photos" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'job-photos');

CREATE POLICY "Authenticated users can delete job photos" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'job-photos');

-- 3. Check if we need to add RLS policies for jobs table
-- Allow boss and technicians to update job status
CREATE POLICY "Users can update their organization's jobs" ON jobs
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'boss' OR profiles.role = 'admin' OR profiles.role = 'technician')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'boss' OR profiles.role = 'admin' OR profiles.role = 'technician')
  )
);

-- 4. Create a test technician (AFTER creating user in Auth Dashboard)
-- IMPORTANT: First create user in Supabase Auth with:
-- Email: technician@servicepro.com
-- Password: Test123!
-- Then uncomment and run this with the actual auth user ID:

-- INSERT INTO profiles (id, email, full_name, role, phone)
-- VALUES (
--     'REPLACE_WITH_AUTH_USER_ID', -- Get this from auth.users table after creating user
--     'technician@servicepro.com',
--     'John Smith',
--     'technician',
--     '828-555-0100'
-- )
-- ON CONFLICT (id) DO UPDATE SET
--     role = 'technician',
--     full_name = 'John Smith',
--     phone = '828-555-0100';

-- 5. Verify tables exist
SELECT 'Checking job_time_entries table...' as status;
SELECT COUNT(*) as count FROM job_time_entries;

SELECT 'Checking job_photos table...' as status;
SELECT COUNT(*) as count FROM job_photos;

SELECT 'Checking job_materials table...' as status;
SELECT COUNT(*) as count FROM job_materials;

SELECT 'Checking job_activity_log table...' as status;
SELECT COUNT(*) as count FROM job_activity_log;
