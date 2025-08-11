#!/bin/bash
echo "🔧 Fixing user role from 'technician' to 'boss'..."

# Create SQL file to update the user role
echo "📝 Creating SQL update script..."
cat > fix_user_role.sql << 'EOF'
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
EOF

echo "✅ SQL script created!"
echo ""
echo "📝 Instructions:"
echo "1. Go to your Supabase Dashboard"
echo "2. Navigate to SQL Editor"
echo "3. Copy and paste this SQL:"
echo ""
cat fix_user_role.sql
echo ""
echo "4. Run the SQL query"
echo "5. After updating, sign out and sign back in"
echo "6. Try accessing /proposals again - it should work!"
echo ""
echo "Alternative: If you want to keep testing as technician AND access proposals,"
echo "we can update the proposals page to also accept 'technician' role."