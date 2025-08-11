-- 1. Create storage bucket for job photos (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('job-photos', 'job-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Drop existing policies if they exist and recreate them
DO $$
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "Authenticated users can upload job photos" ON storage.objects;
    DROP POLICY IF EXISTS "Anyone can view job photos" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can update job photos" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can delete job photos" ON storage.objects;
    
    -- Create new policies
    CREATE POLICY "Authenticated users can upload job photos" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'job-photos');

    CREATE POLICY "Anyone can view job photos" ON storage.objects
    FOR SELECT TO public
    USING (bucket_id = 'job-photos');

    CREATE POLICY "Authenticated users can update job photos" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'job-photos');

    CREATE POLICY "Authenticated users can delete job photos" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'job-photos');
END $$;

-- 3. Ensure RLS policies for jobs table
DROP POLICY IF EXISTS "Users can update their organization's jobs" ON jobs;

CREATE POLICY "Users can update their organization's jobs" ON jobs
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'boss' OR profiles.role = 'admin' OR profiles.role = 'technician')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'boss' OR profiles.role = 'admin' OR profiles.role = 'technician')
  )
);

-- 4. Create function to handle technician creation (if not exists)
CREATE OR REPLACE FUNCTION create_technician_user(
    email text,
    password text,
    full_name text,
    phone text
) RETURNS json AS $$
DECLARE
    new_user_id uuid;
    result json;
BEGIN
    -- This function will be called from the app
    -- The app will use service role key to create the auth user
    -- Then insert the profile
    result := json_build_object(
        'success', true,
        'message', 'Function ready for technician creation'
    );
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
