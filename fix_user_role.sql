-- Update user role from technician to boss
UPDATE profiles 
SET 
    role = 'boss',
    full_name = 'Dan Tcacenco',
    updated_at = NOW()
WHERE id = 'd59c31b1-ccce-4fe8-be8d-7295ec41f7ac';

-- Verify the update
SELECT id, email, full_name, role 
FROM profiles 
WHERE id = 'd59c31b1-ccce-4fe8-be8d-7295ec41f7ac';
