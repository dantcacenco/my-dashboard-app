-- First check and drop existing policies to avoid conflicts
DO $$ 
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "Technicians can view job photos for assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can upload photos to assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can view job files for assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can upload files to assigned jobs" ON storage.objects;
    DROP POLICY IF EXISTS "Technicians can view job_photos for assigned jobs" ON public.job_photos;
    DROP POLICY IF EXISTS "Technicians can create job_photos for assigned jobs" ON public.job_photos;
    DROP POLICY IF EXISTS "Technicians can view job_files for assigned jobs" ON public.job_files;
    DROP POLICY IF EXISTS "Technicians can create job_files for assigned jobs" ON public.job_files;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

-- Storage bucket policies for job-photos
CREATE POLICY "Technicians can view job photos for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-photos' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

CREATE POLICY "Technicians can upload photos to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-photos' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

-- Storage bucket policies for job-files
CREATE POLICY "Technicians can view job files for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-files' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

CREATE POLICY "Technicians can upload files to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-files' 
  AND EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id::text = split_part(storage.objects.name, '/', 1)
  )
);

-- Table policies for job_photos
CREATE POLICY "Technicians can view job_photos for assigned jobs"
ON public.job_photos FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_photos.job_id
  )
);

CREATE POLICY "Technicians can create job_photos for assigned jobs"
ON public.job_photos FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_photos.job_id
  )
);

-- Table policies for job_files
CREATE POLICY "Technicians can view job_files for assigned jobs"
ON public.job_files FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_files.job_id
  )
);

CREATE POLICY "Technicians can create job_files for assigned jobs"
ON public.job_files FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.job_technicians 
    WHERE technician_id = auth.uid() 
    AND job_id = job_files.job_id
  )
);

-- Verify the policies were created
SELECT tablename, policyname FROM pg_policies WHERE tablename IN ('objects', 'job_photos', 'job_files') AND policyname LIKE '%Technician%';
