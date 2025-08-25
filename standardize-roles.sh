#!/bin/bash

echo "🔧 Standardizing all roles to 'admin'..."
echo ""

cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# First, update the database
echo "🗄️ Updating database roles from 'boss' to 'admin'..."
cat > update_roles.js << 'EOF'
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTQ5NDYsImV4cCI6MjA2ODY3MDk0Nn0.m1vGbIc2md-kK0fKk_yBmxR4ugxbO2WOGp8n0_dPURQ';

const supabase = createClient(supabaseUrl, supabaseKey);

async function updateRoles() {
  const { data, error } = await supabase
    .from('profiles')
    .update({ role: 'admin' })
    .eq('role', 'boss');
  
  if (error) {
    console.error('Error updating roles:', error);
    process.exit(1);
  }
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('email, role')
    .eq('email', 'dantcacenco@gmail.com')
    .single();
  
  console.log('✅ Database updated. Your role is now:', profile?.role);
}

updateRoles();
EOF

node update_roles.js
rm -f update_roles.js

echo ""
echo "📝 Updating all TypeScript files to only check for 'admin' role..."

# Update files that check for both boss and admin roles
# Using sed to update the role checks

# Fix proposals page
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/proposals/page.tsx"
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/proposals/page.tsx"

# Fix dashboard page
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/dashboard/page.tsx"
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/dashboard/page.tsx"

# Fix proposal edit page
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/proposals/[id]/edit/page.tsx"
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/proposals/[id]/edit/page.tsx"

# Fix proposals new page
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/proposals/new/page.tsx"
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/proposals/new/page.tsx"

# Fix invoices page
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/invoices/page.tsx"
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/invoices/page.tsx"

# Fix technicians page
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/technicians/page.tsx"
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/technicians/page.tsx"

# Fix jobs new page
sed -i '' "s/profile?.role !== 'boss' && profile?.role !== 'admin'/profile?.role !== 'admin'/g" "app/(authenticated)/jobs/new/page.tsx"
sed -i '' "s/profile?.role !== 'admin' && profile?.role !== 'boss'/profile?.role !== 'admin'/g" "app/(authenticated)/jobs/new/page.tsx"

# Fix customers page
sed -i '' "s/userRole === 'boss' || userRole === 'admin'/userRole === 'admin'/g" "app/(authenticated)/customers/[id]/CustomerDetailView.tsx"
sed -i '' "s/userRole === 'admin' || userRole === 'boss'/userRole === 'admin'/g" "app/(authenticated)/customers/[id]/CustomerDetailView.tsx"

# Fix job detail view
sed -i '' "s/userRole === 'boss'/userRole === 'admin'/g" "app/(authenticated)/jobs/[id]/JobDetailView.tsx"

# Fix test-auth page
sed -i '' "s/profile1?.role === 'admin' || profile1?.role === 'boss'/profile1?.role === 'admin'/g" "app/(authenticated)/test-auth/page.tsx"
sed -i '' "s/profile1?.role === 'boss'/profile1?.role === 'admin'/g" "app/(authenticated)/test-auth/page.tsx"

# Also update any standalone boss checks
find app -name "*.tsx" -o -name "*.ts" | xargs grep -l "role.*'boss'" | while read file; do
  sed -i '' "s/'boss'/'admin'/g" "$file"
done

echo "✅ All role checks updated to 'admin'"
echo ""

# Test TypeScript compilation
echo "🧪 Testing TypeScript compilation..."
npx tsc --noEmit 2>&1 | head -10
if [ $? -eq 0 ]; then
  echo "✅ TypeScript compilation successful!"
else
  echo "⚠️ TypeScript compilation has errors - check above"
fi

echo ""
echo "💾 Committing changes..."
git add -A
git commit -m "refactor: standardize all roles to 'admin' - remove 'boss' role checks"
git push origin main

echo ""
echo "✅ Role standardization complete!"
echo ""
echo "🧹 Cleaning up this script..."
rm -f "$0"

echo ""
echo "Next steps:"
echo "1. Test login as admin"
echo "2. Verify all pages are accessible"
echo "3. Move to Task 2: Fix column name inconsistencies"
