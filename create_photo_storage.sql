-- Create storage bucket for job photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('job-photos', 'job-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Authenticated users can upload job photos" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'job-photos');

CREATE POLICY "Anyone can view job photos" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'job-photos');

CREATE POLICY "Authenticated users can delete job photos" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'job-photos');
