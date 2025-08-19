-- Check current RLS policies for job_technicians
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'job_technicians';

-- Drop existing policies and recreate
DROP POLICY IF EXISTS "Technicians can view their assignments" ON job_technicians;
DROP POLICY IF EXISTS "Boss and admin can manage assignments" ON job_technicians;

-- Create comprehensive policies for job_technicians
CREATE POLICY "Technicians can view their assignments"
  ON job_technicians
  FOR SELECT
  USING (technician_id = auth.uid());

CREATE POLICY "Boss and admin can view all assignments"
  ON job_technicians
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

CREATE POLICY "Boss and admin can insert assignments"
  ON job_technicians
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

CREATE POLICY "Boss and admin can update assignments"
  ON job_technicians
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

CREATE POLICY "Boss and admin can delete assignments"
  ON job_technicians
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

-- Also ensure jobs table has proper policies for technicians
DROP POLICY IF EXISTS "Technicians can view assigned jobs" ON jobs;

CREATE POLICY "Technicians can view assigned jobs"
  ON jobs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM job_technicians 
      WHERE job_technicians.job_id = jobs.id 
      AND job_technicians.technician_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('boss', 'admin')
    )
  );

-- Test the policies
SELECT 
  'job_technicians' as table_name,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'job_technicians'
UNION ALL
SELECT 
  'jobs' as table_name,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'jobs';
