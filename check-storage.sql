-- Check storage bucket settings
SELECT name, public, allowed_mime_types, file_size_limit 
FROM storage.buckets 
WHERE name IN ('job-photos', 'job-files');
