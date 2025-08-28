-- SQL script to update proposal statuses and create bidirectional sync
-- Execute in Supabase SQL Editor

-- 1. Drop existing constraint
ALTER TABLE proposals DROP CONSTRAINT IF EXISTS proposals_status_check;

-- 2. Add new constraint with extended statuses  
ALTER TABLE proposals ADD CONSTRAINT proposals_status_check 
CHECK (status IN ('draft', 'sent', 'approved', 'rejected', 'deposit_paid', 'rough_in_paid', 'final_paid', 'completed'));

-- 3. Add trigger function for bidirectional sync
CREATE OR REPLACE FUNCTION sync_job_proposal_status()
RETURNS trigger AS $$
BEGIN
  -- If proposal status changed, update related job
  IF TG_TABLE_NAME = 'proposals' THEN
    IF OLD.status != NEW.status THEN
      UPDATE jobs 
      SET status = CASE 
        WHEN NEW.status = 'approved' THEN 'scheduled'
        WHEN NEW.status = 'deposit_paid' THEN 'scheduled' 
        WHEN NEW.status = 'rough_in_paid' THEN 'in_progress'
        WHEN NEW.status = 'final_paid' THEN 'in_progress'
        WHEN NEW.status = 'completed' THEN 'completed'
        WHEN NEW.status = 'rejected' THEN 'cancelled'
        ELSE 'not_scheduled'
      END
      WHERE proposal_id = NEW.id;
    END IF;
    RETURN NEW;
  END IF;
  
  -- If job status changed, update related proposal  
  IF TG_TABLE_NAME = 'jobs' THEN
    IF OLD.status != NEW.status AND NEW.proposal_id IS NOT NULL THEN
      UPDATE proposals
      SET status = CASE
        WHEN NEW.status = 'completed' THEN 'completed'
        WHEN NEW.status = 'cancelled' THEN 'rejected'
        WHEN NEW.status = 'in_progress' THEN 
          CASE 
            WHEN (SELECT status FROM proposals WHERE id = NEW.proposal_id) = 'rough_in_paid' THEN 'rough_in_paid'
            WHEN (SELECT status FROM proposals WHERE id = NEW.proposal_id) = 'final_paid' THEN 'final_paid'
            ELSE 'approved'
          END
        WHEN NEW.status = 'scheduled' THEN
          CASE
            WHEN (SELECT status FROM proposals WHERE id = NEW.proposal_id) = 'deposit_paid' THEN 'deposit_paid'
            ELSE 'approved'
          END
        ELSE (SELECT status FROM proposals WHERE id = NEW.proposal_id) -- Keep current status
      END
      WHERE id = NEW.proposal_id;
    END IF;
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Create triggers for both tables
DROP TRIGGER IF EXISTS proposal_status_sync ON proposals;
CREATE TRIGGER proposal_status_sync
  AFTER UPDATE ON proposals
  FOR EACH ROW
  EXECUTE FUNCTION sync_job_proposal_status();

DROP TRIGGER IF EXISTS job_status_sync ON jobs;  
CREATE TRIGGER job_status_sync
  AFTER UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION sync_job_proposal_status();

-- 5. Add status change logging (optional)
CREATE TABLE IF NOT EXISTS status_change_log (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  table_name text NOT NULL,
  record_id uuid NOT NULL, 
  old_status text,
  new_status text,
  changed_at timestamp with time zone DEFAULT now(),
  changed_by uuid REFERENCES auth.users(id)
);

-- Enable RLS on status_change_log
ALTER TABLE status_change_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for status_change_log
CREATE POLICY "Users can view status changes" ON status_change_log
  FOR SELECT USING (auth.role() = 'authenticated');
