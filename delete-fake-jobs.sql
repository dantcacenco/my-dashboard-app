-- Delete fake/test jobs
-- Be careful! This will delete jobs with these specific IDs or patterns

-- Delete jobs with placeholder titles
DELETE FROM jobs 
WHERE title IN ('Furnace Repair - Danny', 'HVAC System Installation - Danny', 
                'Emergency AC Repair - Danny', 'Annual Maintenance - Danny')
   OR title LIKE '%Danny%'
   OR job_number IN ('JOB-20250729-001', 'JOB-20250729-002', 'JOB-20250729-003', 'JOB-20250729-004');

-- Or if you want to delete ALL jobs (be very careful!):
-- TRUNCATE TABLE jobs CASCADE;

-- To see what will be deleted first, run:
-- SELECT id, job_number, title FROM jobs 
-- WHERE title LIKE '%Danny%' OR title LIKE '%Furnace%' OR title LIKE '%HVAC%';
