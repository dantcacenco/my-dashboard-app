-- Check the current constraint on job_photos table
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'job_photos'::regclass
AND contype = 'c';

-- Drop the old constraint if it exists
ALTER TABLE job_photos 
DROP CONSTRAINT IF EXISTS job_photos_photo_type_check;

-- Add a new constraint that includes 'job_progress' or make it nullable
-- Option 1: Add 'job_progress' to allowed values
ALTER TABLE job_photos 
ADD CONSTRAINT job_photos_photo_type_check 
CHECK (photo_type IN ('before', 'during', 'after', 'job_progress', 'inspection', 'damage', 'completion', 'other'));

-- Or Option 2: Make photo_type nullable (simpler)
-- ALTER TABLE job_photos ALTER COLUMN photo_type DROP NOT NULL;
