-- Delete all test jobs created on July 29, 2025
DELETE FROM job_technicians 
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_photos
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_files
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_materials
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_time_entries
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

DELETE FROM job_activity_log
WHERE job_id IN (
  SELECT id FROM jobs 
  WHERE job_number LIKE 'JOB-20250729-%'
);

-- Now delete the jobs themselves
DELETE FROM jobs 
WHERE job_number LIKE 'JOB-20250729-%';

-- Return count of deleted jobs
SELECT 'Deleted ' || COUNT(*) || ' test jobs' as result
FROM jobs 
WHERE job_number LIKE 'JOB-20250729-%';
