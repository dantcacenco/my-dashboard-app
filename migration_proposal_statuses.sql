-- Migration: Update proposal status constraints
-- Execute this in Supabase SQL Editor

-- Backup current data first (already done via backup script)

-- Drop existing constraint
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

-- Update existing 'viewed' status to 'sent' if any exist
UPDATE proposals SET status = 'sent' WHERE status = 'viewed';

-- Comment: New status flow
-- draft -> sent -> approved/rejected -> deposit paid -> rough-in paid -> final paid -> completed
