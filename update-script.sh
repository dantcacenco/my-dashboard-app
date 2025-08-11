#!/bin/bash
echo "🔧 Creating diagnostic test page to understand the redirect issue..."

# Create a test page that shows auth and profile information
echo "📝 Creating test auth page..."
cat > app/test-auth/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'

export default async function TestAuthPage() {
  const supabase = await createClient()
  
  // Get user
  const { data: { user }, error: userError } = await supabase.auth.getUser()
  
  // Try multiple ways to get profile
  let profile1, profile2, profile3, profileError1, profileError2, profileError3
  
  if (user) {
    // Method 1: Direct query
    const result1 = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()
    profile1 = result1.data
    profileError1 = result1.error
    
    // Method 2: With maybeSingle
    const result2 = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle()
    profile2 = result2.data
    profileError2 = result2.error
    
    // Method 3: Without RLS
    const result3 = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .limit(1)
    profile3 = result3.data?.[0]
    profileError3 = result3.error
  }
  
  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Auth Test Page</h1>
      
      <div className="space-y-4">
        <div className="bg-gray-100 p-4 rounded">
          <h2 className="font-bold mb-2">User Auth:</h2>
          <pre className="text-sm overflow-auto">
            {JSON.stringify({ user, userError }, null, 2)}
          </pre>
        </div>
        
        <div className="bg-gray-100 p-4 rounded">
          <h2 className="font-bold mb-2">Profile Query 1 (single):</h2>
          <pre className="text-sm overflow-auto">
            {JSON.stringify({ profile: profile1, error: profileError1 }, null, 2)}
          </pre>
        </div>
        
        <div className="bg-gray-100 p-4 rounded">
          <h2 className="font-bold mb-2">Profile Query 2 (maybeSingle):</h2>
          <pre className="text-sm overflow-auto">
            {JSON.stringify({ profile: profile2, error: profileError2 }, null, 2)}
          </pre>
        </div>
        
        <div className="bg-gray-100 p-4 rounded">
          <h2 className="font-bold mb-2">Profile Query 3 (limit):</h2>
          <pre className="text-sm overflow-auto">
            {JSON.stringify({ profile: profile3, error: profileError3 }, null, 2)}
          </pre>
        </div>
        
        <div className="bg-blue-100 p-4 rounded">
          <h2 className="font-bold mb-2">Authorization Result:</h2>
          <p>Role from profile1: {profile1?.role || 'NOT FOUND'}</p>
          <p>Is Admin: {profile1?.role === 'admin' ? 'YES' : 'NO'}</p>
          <p>Is Boss: {profile1?.role === 'boss' ? 'YES' : 'NO'}</p>
          <p>Should have access: {(profile1?.role === 'admin' || profile1?.role === 'boss') ? 'YES' : 'NO'}</p>
        </div>
      </div>
      
      <div className="mt-8 space-x-4">
        <a href="/proposals" className="text-blue-600 hover:underline">Go to Proposals</a>
        <a href="/" className="text-blue-600 hover:underline">Go to Dashboard</a>
      </div>
    </div>
  )
}
EOF

# Also check if there's a middleware.ts in the root that might be interfering
echo "📝 Checking for existing middleware.ts file..."
if [ -f "middleware.ts" ]; then
    echo "Found middleware.ts, backing it up..."
    mv middleware.ts middleware.ts.backup
fi

# Create a minimal middleware that logs but doesn't interfere
echo "📝 Creating diagnostic middleware..."
cat > middleware.ts << 'EOF'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

export async function middleware(request: NextRequest) {
  // Log the request
  console.log('[Middleware] Request to:', request.nextUrl.pathname)
  
  // Call the Supabase session update
  const response = await updateSession(request)
  
  // Log if there's a redirect
  if (response.status === 307 || response.status === 302) {
    console.log('[Middleware] Redirecting to:', response.headers.get('location'))
  }
  
  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (public folder)
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
EOF

# Commit the changes
git add .
git commit -m "feat: add auth diagnostic page and logging middleware

- Created /test-auth page to diagnose profile queries
- Added middleware logging to track redirects
- This will help identify why proposals redirects to dashboard"
git push origin main

echo "✅ Diagnostic tools created!"
echo ""
echo "📝 Next steps:"
echo "1. Visit /test-auth to see your auth and profile status"
echo "2. Check the console/logs when clicking on Proposals"
echo "3. Share the results from /test-auth page"
echo ""
echo "This will help us understand:"
echo "- If the profile query is failing"
echo "- What role is actually being returned"
echo "- Where the redirect is happening"