-- Check what the current constraint is
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'jobs'::regclass
AND contype = 'c';

-- Drop the old constraint if it exists
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_status_check;

-- Add a new constraint that includes all our status values
ALTER TABLE jobs ADD CONSTRAINT jobs_status_check 
CHECK (status IN ('not_scheduled', 'scheduled', 'in_progress', 'completed', 'cancelled', 'pending'));

-- Verify the fix
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'jobs'::regclass
AND contype = 'c';
