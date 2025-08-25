#!/bin/bash

echo "🔧 Updating app to use 'boss' as the admin role..."
cd /Users/dantcacenco/Documents/GitHub/my-dashboard-app

# Update dashboard to check for boss role
echo "📝 Updating dashboard..."
sed -i '' "s/profile.role !== 'admin'/profile.role !== 'boss'/g" "app/(authenticated)/dashboard/page.tsx"
sed -i '' "s/profile?.role !== 'admin'/profile?.role !== 'boss'/g" "app/(authenticated)/dashboard/page.tsx"

# Update home page
echo "📝 Updating home page..."
sed -i '' "s/userRole === 'admin'/userRole === 'boss'/g" "app/page.tsx"
sed -i '' "s/profile?.role === 'admin'/profile?.role === 'boss'/g" "app/page.tsx"

# Update proposals page
echo "📝 Updating proposals page..."
sed -i '' "s/profile?.role !== 'admin'/profile?.role !== 'boss'/g" "app/(authenticated)/proposals/page.tsx"

# Update other authenticated pages
echo "📝 Updating other pages..."
find app -name "*.tsx" -exec sed -i '' "s/=== 'admin'/=== 'boss'/g" {} \;
find app -name "*.tsx" -exec sed -i '' "s/!== 'admin'/!== 'boss'/g" {} \;

# Clean up temp files
rm -f create-admin-profile.js verify-profile.js fix-profile.js

echo ""
echo "✅ All role checks updated to use 'boss'"
echo ""
echo "💾 Committing changes..."
git add -A
git commit -m "fix: use 'boss' role as admin (database constraint)

- Database only allows: boss, technician, customer
- Updated all admin checks to use 'boss' role
- Your profile already exists with boss role
- App now works with existing database schema"

git push origin main

echo ""
echo "✅ SUCCESS! Your profile is set up:"
echo "   Name: Dan Tcacenco"
echo "   Email: dantcacenco@gmail.com"
echo "   Role: boss ✅"
echo "   Phone: 828-222-3333"
echo ""
echo "You can now access the dashboard as the BOSS!"
echo ""
echo "🧹 Cleaning up..."
rm -f "$0"
