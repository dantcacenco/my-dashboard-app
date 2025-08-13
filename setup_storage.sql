-- Create storage buckets for files and photos
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('job-files', 'job-files', false),
  ('job-photos', 'job-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for job-files (private)
CREATE POLICY "Authenticated users can upload job files" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'job-files');

CREATE POLICY "Authenticated users can view job files" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'job-files');

CREATE POLICY "Users can delete their own job files" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'job-files');

-- Policies for job-photos (public)
CREATE POLICY "Authenticated users can upload job photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'job-photos');

CREATE POLICY "Anyone can view job photos" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'job-photos');

CREATE POLICY "Users can delete job photos" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'job-photos');

-- Add job_created column to proposals if it doesn't exist
ALTER TABLE proposals ADD COLUMN IF NOT EXISTS job_created BOOLEAN DEFAULT FALSE;

-- Add notes columns to jobs if they don't exist  
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS boss_notes TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS completion_notes TEXT;
