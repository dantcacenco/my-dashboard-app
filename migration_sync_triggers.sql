-- Database triggers for bidirectional status sync
-- Execute this in Supabase SQL Editor after running migration_proposal_statuses.sql

-- Function to sync proposal status when job status changes
CREATE OR REPLACE FUNCTION sync_job_to_proposal()
RETURNS TRIGGER AS $$
BEGIN
  -- Only sync if job has a proposal_id
  IF NEW.proposal_id IS NOT NULL THEN
    -- Update proposal status based on job status
    UPDATE proposals 
    SET status = CASE 
      WHEN NEW.status = 'scheduled' THEN 'approved'
      WHEN NEW.status = 'in_progress' THEN 'rough-in paid'
      WHEN NEW.status = 'completed' THEN 'completed'
      WHEN NEW.status = 'cancelled' THEN 'rejected'
      ELSE 'draft'
    END,
    updated_at = NOW()
    WHERE id = NEW.proposal_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to sync job status when proposal status changes  
CREATE OR REPLACE FUNCTION sync_proposal_to_job()
RETURNS TRIGGER AS $$
BEGIN
  -- Update job status based on proposal status
  UPDATE jobs 
  SET status = CASE 
    WHEN NEW.status IN ('approved', 'deposit paid') THEN 'scheduled'
    WHEN NEW.status IN ('rough-in paid', 'final paid') THEN 'in_progress' 
    WHEN NEW.status = 'completed' THEN 'completed'
    WHEN NEW.status = 'rejected' THEN 'cancelled'
    ELSE 'not_scheduled'
  END,
  updated_at = NOW()
  WHERE proposal_id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_sync_job_to_proposal ON jobs;
CREATE TRIGGER trigger_sync_job_to_proposal
  AFTER UPDATE OF status ON jobs
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION sync_job_to_proposal();

DROP TRIGGER IF EXISTS trigger_sync_proposal_to_job ON proposals;  
CREATE TRIGGER trigger_sync_proposal_to_job
  AFTER UPDATE OF status ON proposals
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION sync_proposal_to_job();
