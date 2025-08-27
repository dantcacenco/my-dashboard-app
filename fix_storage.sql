-- Make buckets public for read access
UPDATE storage.buckets 
SET public = true 
WHERE name IN ('job-photos', 'job-files');

-- Add RLS policies for storage objects if not exists
DO $$ 
BEGIN
  -- Allow technicians to upload to job-photos
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Technicians can upload photos'
  ) THEN
    CREATE POLICY "Technicians can upload photos"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'job-photos' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Allow public to view job-photos
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Public can view job photos'
  ) THEN
    CREATE POLICY "Public can view job photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'job-photos');
  END IF;

  -- Allow technicians to upload to job-files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Technicians can upload files'
  ) THEN
    CREATE POLICY "Technicians can upload files"
    ON storage.objects FOR INSERT
    WITH CHECK (
      bucket_id = 'job-files' 
      AND auth.uid()::text = (storage.foldername(name))[1]
    );
  END IF;

  -- Allow authenticated to view job-files
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'objects' 
    AND policyname = 'Authenticated can view job files'
  ) THEN
    CREATE POLICY "Authenticated can view job files"
    ON storage.objects FOR SELECT
    USING (
      bucket_id = 'job-files'
      AND auth.role() = 'authenticated'
    );
  END IF;
END $$;

-- Verify bucket settings
SELECT name, public, created_at 
FROM storage.buckets 
WHERE name IN ('job-photos', 'job-files');

-- Check existing storage policies
SELECT tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects';
