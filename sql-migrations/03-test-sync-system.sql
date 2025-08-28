-- Test Script for Verifying Status Synchronization
-- Run this AFTER executing the migration scripts

-- Test 1: Verify new status constraints are in place
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'proposals'::regclass 
AND contype = 'c';

-- Test 2: Check if triggers exist
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name IN ('trigger_sync_job_to_proposal', 'trigger_sync_proposal_to_job');

-- Test 3: Test Proposal to Job sync
-- Update a proposal status and verify job status changes
DO $$
DECLARE
    test_proposal_id UUID;
    test_job_id UUID;
    job_status_before TEXT;
    job_status_after TEXT;
BEGIN
    -- Find a proposal with an associated job
    SELECT p.id, j.id, j.status 
    INTO test_proposal_id, test_job_id, job_status_before
    FROM proposals p 
    JOIN jobs j ON j.proposal_id = p.id 
    LIMIT 1;
    
    IF test_proposal_id IS NOT NULL THEN
        -- Update proposal to 'deposit paid'
        UPDATE proposals SET status = 'deposit paid' WHERE id = test_proposal_id;
        
        -- Check job status (should be 'scheduled')
        SELECT status INTO job_status_after FROM jobs WHERE id = test_job_id;
        
        RAISE NOTICE 'Test Proposal->Job Sync: Proposal set to "deposit paid", Job changed from "%" to "%"', 
                     job_status_before, job_status_after;
    ELSE
        RAISE NOTICE 'No proposals with jobs found for testing';
    END IF;
END $$;

-- Test 4: Test Job to Proposal sync
DO $$
DECLARE
    test_proposal_id UUID;
    test_job_id UUID;
    proposal_status_before TEXT;
    proposal_status_after TEXT;
BEGIN
    -- Find a job with an associated proposal
    SELECT j.id, j.proposal_id, p.status 
    INTO test_job_id, test_proposal_id, proposal_status_before
    FROM jobs j 
    JOIN proposals p ON p.id = j.proposal_id 
    LIMIT 1;
    
    IF test_job_id IS NOT NULL THEN
        -- Update job to 'in_progress'
        UPDATE jobs SET status = 'in_progress' WHERE id = test_job_id;
        
        -- Check proposal status (should be 'rough-in paid')
        SELECT status INTO proposal_status_after FROM proposals WHERE id = test_proposal_id;
        
        RAISE NOTICE 'Test Job->Proposal Sync: Job set to "in_progress", Proposal changed from "%" to "%"', 
                     proposal_status_before, proposal_status_after;
    ELSE
        RAISE NOTICE 'No jobs with proposals found for testing';
    END IF;
END $$;

-- Test 5: Verify all new statuses work
DO $$
DECLARE
    test_id UUID;
BEGIN
    -- Try to insert a proposal with each new status
    test_id := gen_random_uuid();
    
    -- This should succeed
    INSERT INTO proposals (id, proposal_number, title, status, subtotal, tax_rate, tax_amount, total, customer_id, created_by)
    VALUES (test_id, 'TEST-001', 'Test Proposal', 'deposit paid', 100, 0.08, 8, 108, 
            (SELECT id FROM customers LIMIT 1), 
            (SELECT id FROM auth.users LIMIT 1));
    
    -- Clean up
    DELETE FROM proposals WHERE id = test_id;
    
    RAISE NOTICE 'Test 5: New status "deposit paid" works correctly';
END $$;

-- Summary of expected results:
-- 1. Constraint should show all 8 statuses
-- 2. Both triggers should be listed
-- 3. Proposal status change should update job status
-- 4. Job status change should update proposal status
-- 5. New statuses should be accepted by the database