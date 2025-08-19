-- Make sure job_created column exists in proposals table
ALTER TABLE proposals 
ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT false;

-- Also ensure all required columns exist in jobs table
ALTER TABLE jobs
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS customer_email TEXT,
ADD COLUMN IF NOT EXISTS customer_phone TEXT,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);
