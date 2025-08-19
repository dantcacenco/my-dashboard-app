-- Check what roles exist in profiles
SELECT role, COUNT(*) as count 
FROM profiles 
GROUP BY role;

-- Check all profiles
SELECT id, email, full_name, role, is_active 
FROM profiles
ORDER BY role, full_name;

-- Check specifically for technicians
SELECT id, email, full_name, role, is_active 
FROM profiles 
WHERE role = 'technician';

-- If you need to update users to be technicians (replace emails with actual technician emails)
-- UPDATE profiles 
-- SET role = 'technician', is_active = true 
-- WHERE email IN ('asdf@asdf.com', 'asdf@gmail.com', 'john@example.com', 'hgfh@gmail.com', 'technician@gmail.com');
