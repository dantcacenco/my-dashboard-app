-- Check auth users and profiles
SELECT 
  'Auth Users' as source,
  au.id,
  au.email,
  au.created_at,
  au.user_metadata->>'full_name' as full_name,
  au.user_metadata->>'role' as role
FROM auth.users au
ORDER BY au.created_at DESC;

-- Check profiles table
SELECT 
  'Profiles' as source,
  p.id,
  p.email,
  p.full_name,
  p.role,
  p.is_active,
  p.created_at
FROM profiles p
ORDER BY p.created_at DESC;

-- Check for orphaned auth users (no profile)
SELECT 
  'Orphaned Auth Users (no profile)' as issue,
  au.id,
  au.email,
  au.created_at
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Check for technicians specifically
SELECT 
  'Technicians in Profiles' as category,
  COUNT(*) as count
FROM profiles
WHERE role = 'technician';
