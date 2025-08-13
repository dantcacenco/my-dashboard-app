-- Check if RLS is enabled on profiles table
SELECT 
  schemaname,
  tablename,
  tablename = 'profiles' as is_profiles_table,
  rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- Check existing RLS policies on profiles
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'profiles';

-- Test query as would be run by the app
SELECT 
  COUNT(*) as total_technicians,
  array_agg(email) as emails
FROM profiles
WHERE role = 'technician';

-- If RLS is the issue, this will show all data (bypasses RLS)
SELECT 
  'Direct Query (No RLS)' as query_type,
  id,
  email,
  full_name,
  role
FROM profiles
WHERE role = 'technician';
