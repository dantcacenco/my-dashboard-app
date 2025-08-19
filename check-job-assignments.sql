-- Check job_technicians table
SELECT 
    jt.job_id,
    jt.technician_id,
    j.job_number,
    j.title,
    p.email as technician_email,
    p.full_name as technician_name
FROM job_technicians jt
JOIN jobs j ON j.id = jt.job_id
JOIN profiles p ON p.id = jt.technician_id
ORDER BY jt.assigned_at DESC;

-- Check RLS policies on job_technicians
SELECT * FROM pg_policies WHERE tablename = 'job_technicians';

-- If no policies exist, create them
/*
CREATE POLICY "Technicians can view their assignments" 
ON job_technicians FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Boss can manage assignments" 
ON job_technicians FOR ALL 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('boss', 'admin')
  )
);
*/
