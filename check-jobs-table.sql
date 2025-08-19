-- Check if jobs table has RLS issues
SELECT * FROM pg_policies WHERE tablename = 'jobs';

-- Check if any jobs exist
SELECT COUNT(*) as total_jobs FROM jobs;

-- Try to insert a test job directly (replace with your actual IDs)
-- This will help determine if it's an RLS issue or data issue
/*
INSERT INTO jobs (
  job_number,
  customer_id,
  title,
  job_type,
  status,
  created_by
) VALUES (
  'TEST-' || NOW()::text,
  (SELECT id FROM customers LIMIT 1),
  'Test Job Creation',
  'repair',
  'not_scheduled',
  (SELECT id FROM profiles WHERE role = 'boss' LIMIT 1)
) RETURNING *;
*/

-- Check if job_technicians table has issues
SELECT * FROM pg_policies WHERE tablename = 'job_technicians';

-- See recently created jobs
SELECT id, job_number, title, created_at 
FROM jobs 
ORDER BY created_at DESC 
LIMIT 10;
