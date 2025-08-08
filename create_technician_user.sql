-- First, you need to create the user in Supabase Auth Dashboard
-- Email: technician@hvac.com
-- Password: asdf
-- Then run this SQL to create the profile:

-- Insert technician profile (update the ID after creating auth user)
INSERT INTO profiles (id, email, full_name, role, phone)
VALUES (
    'YOUR_AUTH_USER_ID_HERE', -- Replace this with the actual auth.users.id after creating the user
    'technician@hvac.com',
    'Test Technician',
    'technician',
    '828-222-3333'
) ON CONFLICT (id) DO UPDATE SET
    full_name = 'Test Technician',
    role = 'technician',
    phone = '828-222-3333';

-- Alternative: If you already created the auth user, find their ID:
-- SELECT id FROM auth.users WHERE email = 'technician@hvac.com';
