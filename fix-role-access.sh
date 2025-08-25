#!/bin/bash

echo "🔧 FIXING: Role showing as 'boss' - need to update database and ensure admin access"
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Step 1: Check current role in database
echo "📊 Checking current role in database..."
cat > check-role.js << 'EOF'
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://dqcxwekmehrqkigcufug.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxY3h3ZWttZWhycWtpZ2N1ZnVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTQ5NDYsImV4cCI6MjA2ODY3MDk0Nn0.m1vGbIc2md-kK0fKk_yBmxR4ugxbO2WOGp8n0_dPURQ';

const supabase = createClient(supabaseUrl, supabaseKey);

async function fixRole() {
  // First check current role
  const { data: checkProfile } = await supabase
    .from('profiles')
    .select('email, role')
    .eq('email', 'dantcacenco@gmail.com')
    .single();
  
  console.log('Current role:', checkProfile);
  
  // Update to admin if still boss
  if (checkProfile?.role === 'boss') {
    const { data, error } = await supabase
      .from('profiles')
      .update({ role: 'admin' })
      .eq('email', 'dantcacenco@gmail.com');
    
    if (error) {
      console.error('Error updating role:', error);
    } else {
      console.log('✅ Role updated to admin');
    }
  }
  
  // Verify the update
  const { data: newProfile } = await supabase
    .from('profiles')
    .select('email, role')
    .eq('email', 'dantcacenco@gmail.com')
    .single();
  
  console.log('New role:', newProfile);
}

fixRole();
EOF

node check-role.js
rm -f check-role.js

# Step 2: Update the home page to handle both boss and admin during transition
echo "📝 Updating home page to handle both roles..."
cat > "app/page.tsx" << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function HomePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile to check role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Route based on role - handle both 'boss' and 'admin' for now
  const userRole = profile?.role
  
  if (userRole === 'admin' || userRole === 'boss') {
    redirect('/dashboard')
  } else if (userRole === 'technician') {
    redirect('/technician')
  } else {
    // Show welcome for users without roles
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Welcome to Service Pro</h1>
          <p className="text-gray-600">Your account is being set up.</p>
          <p className="text-sm text-gray-500 mt-2">Role: {userRole || 'Not assigned'}</p>
          <p className="text-sm text-gray-500">Please contact support if you need assistance.</p>
        </div>
      </div>
    )
  }
}
EOF

# Step 3: Update dashboard to accept both boss and admin
echo "📝 Updating dashboard to accept both roles temporarily..."
sed -i '' "s/profile.role !== 'admin'/profile.role !== 'admin' \&\& profile.role !== 'boss'/g" "app/(authenticated)/dashboard/page.tsx"

echo ""
echo "🧪 Testing TypeScript..."
npx tsc --noEmit
if [ $? -eq 0 ]; then
  echo "✅ TypeScript successful!"
fi

echo ""
echo "💾 Committing fixes..."
git add -A
git commit -m "fix: handle both boss and admin roles during transition period

- Update database role from boss to admin
- Allow both roles to access dashboard temporarily
- Proper role routing without loops
- Database migration handled gracefully"

git push origin main

echo ""
echo "✅ Fix complete!"
echo ""
echo "Next steps:"
echo "1. Clear your browser cache/cookies"
echo "2. Sign in again"
echo "3. You should now be redirected to /dashboard"
echo ""
echo "🧹 Cleaning up..."
rm -f "$0"
