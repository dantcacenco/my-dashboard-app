-- Add job status tracking fields to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS work_started BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS roughin_done BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS final_done BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS work_started_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS roughin_done_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS final_done_at TIMESTAMP;