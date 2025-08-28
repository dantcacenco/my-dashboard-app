-- STEP 1: Update Proposal Status Constraints
-- This adds the new payment-related statuses to the proposals table

-- Remove existing constraint
ALTER TABLE proposals DROP CONSTRAINT IF EXISTS proposals_status_check;

-- Add new constraint with expanded statuses
ALTER TABLE proposals 
ADD CONSTRAINT proposals_status_check 
CHECK (status IN (
  'draft',
  'sent', 
  'approved',
  'rejected',
  'deposit paid',
  'rough-in paid', 
  'final paid',
  'completed'
));

-- Verify the change
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'proposals'::regclass 
AND contype = 'c';