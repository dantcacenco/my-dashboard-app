-- Storage bucket policies for job-photos
-- Allow technicians to view photos for jobs they're assigned to
CREATE POLICY "Technicians can view job photos for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-photos' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Allow technicians to upload photos to jobs they're assigned to  
CREATE POLICY "Technicians can upload photos to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-photos' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Storage bucket policies for job-files
-- Allow technicians to view files for jobs they're assigned to
CREATE POLICY "Technicians can view job files for assigned jobs"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'job-files' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Allow technicians to upload files to jobs they're assigned to
CREATE POLICY "Technicians can upload files to assigned jobs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'job-files' 
  AND auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = (storage.foldername(name)::uuid)
  )
);

-- Also ensure the job_photos and job_files tables allow technician access
-- Allow technicians to view job_photos records for assigned jobs
CREATE POLICY "Technicians can view job_photos for assigned jobs"
ON public.job_photos FOR SELECT
USING (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_photos.job_id
  )
);

-- Allow technicians to create job_photos records for assigned jobs
CREATE POLICY "Technicians can create job_photos for assigned jobs"
ON public.job_photos FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_photos.job_id
  )
);

-- Allow technicians to view job_files records for assigned jobs
CREATE POLICY "Technicians can view job_files for assigned jobs"
ON public.job_files FOR SELECT
USING (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_files.job_id
  )
);

-- Allow technicians to create job_files records for assigned jobs
CREATE POLICY "Technicians can create job_files for assigned jobs"
ON public.job_files FOR INSERT
WITH CHECK (
  auth.uid() IN (
    SELECT technician_id 
    FROM public.job_technicians 
    WHERE job_id = job_files.job_id
  )
);
