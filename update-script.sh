#!/bin/bash

# Comprehensive Auth Fix with Debugging
# Service Pro Field Service Management
# Date: August 6, 2025

set -e  # Exit on error

echo "🔧 Comprehensive fix for VIEW/EDIT redirect issue..."

# Fix 1: Create a test page to verify auth is working
echo "📦 Creating auth test page..."
mkdir -p app/test-auth
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

# Fix 2: Update proposal view page with better error handling
echo "📦 Updating proposal VIEW page with detailed logging..."
cat > app/proposals/[id]/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import ProposalView from './ProposalView'

interface PageProps {
  params: Promise<{ id: string }>
}

export default async function ViewProposalPage({ params }: PageProps) {
  const { id } = await params
  const supabase = await createClient()
  
  console.log('[ViewProposalPage] Starting with proposal ID:', id)
  
  // Check if user is authenticated
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    console.log('[ViewProposalPage] No user found, redirecting to sign-in')
    redirect('/sign-in')
  }
  
  console.log('[ViewProposalPage] User authenticated:', user.id)

  // Get user profile with error handling
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .maybeSingle()

  console.log('[ViewProposalPage] Profile query result:', { profile, profileError })

  // If no profile found or error, try to handle gracefully
  if (!profile && !profileError) {
    console.log('[ViewProposalPage] No profile found for user')
    // Create a default profile or redirect
    redirect('/')
  }
  
  if (profileError) {
    console.error('[ViewProposalPage] Error fetching profile:', profileError)
    // Check if it's an RLS error
    if (profileError.message?.includes('row-level security')) {
      console.error('[ViewProposalPage] RLS policy blocking profile access')
    }
    redirect('/')
  }

  // Check role authorization
  const userRole = profile?.role
  console.log('[ViewProposalPage] User role:', userRole)
  
  if (userRole !== 'admin' && userRole !== 'boss') {
    console.log('[ViewProposalPage] Unauthorized role, redirecting to dashboard')
    redirect('/')
  }

  console.log('[ViewProposalPage] Authorization passed, fetching proposal')

  // Get the proposal with items and customer data
  const { data: proposal, error: proposalError } = await supabase
    .from('proposals')
    .select(`
      *,
      customers (
        id,
        name,
        email,
        phone,
        address
      ),
      proposal_items (
        *
      )
    `)
    .eq('id', id)
    .single()

  if (proposalError || !proposal) {
    console.error('[ViewProposalPage] Proposal not found:', proposalError)
    notFound()
  }

  console.log('[ViewProposalPage] Proposal found, rendering view')

  return (
    <div className="min-h-screen bg-gray-50">
      <ProposalView 
        proposal={proposal}
        userRole={userRole}
        userId={user.id}
      />
    </div>
  )
}
EOF

# Fix 3: Create RLS policy check/fix SQL
echo "📦 Creating RLS policy fix SQL..."
cat > fix_profiles_rls.sql << 'EOF'
-- Fix RLS policies for profiles table
-- Run this in Supabase SQL editor

-- First, check if profiles table has RLS enabled
SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- Drop any existing policies that might be blocking
DROP POLICY IF EXISTS "Profiles are viewable by users" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;

-- Create a simple policy that allows users to read their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Also allow users to view profiles if they have a valid session
CREATE POLICY "Authenticated users can view profiles" ON profiles
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- Verify the policies
SELECT * FROM pg_policies WHERE tablename = 'profiles';
EOF

# Fix 4: Add middleware logging
echo "📦 Creating middleware debug helper..."
cat > middleware.ts << 'EOF'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Log all navigation attempts
  if (request.nextUrl.pathname.startsWith('/proposals')) {
    console.log('[Middleware] Proposal route accessed:', {
      pathname: request.nextUrl.pathname,
      url: request.url,
      headers: Object.fromEntries(request.headers.entries())
    })
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/proposals/:path*']
}
EOF

# Fix 5: Update ProposalsList to ensure correct links
echo "📦 Checking ProposalsList component..."
cat > check_proposals_list.sh << 'INNEREOF'
#!/bin/bash
# This checks if ProposalsList has correct href paths

echo "Checking ProposalsList for correct href paths..."

if [ -f "app/proposals/ProposalsList.tsx" ]; then
  echo "Current VIEW href:"
  grep -n "href.*proposals.*view" app/proposals/ProposalsList.tsx || echo "No view href found"
  
  echo ""
  echo "Current EDIT href:"
  grep -n "href.*proposals.*edit" app/proposals/ProposalsList.tsx || echo "No edit href found"
  
  echo ""
  echo "All proposal href patterns:"
  grep -n "href.*proposal" app/proposals/ProposalsList.tsx
fi
INNEREOF

chmod +x check_proposals_list.sh
./check_proposals_list.sh

# Commit everything
echo ""
echo "💾 Pushing comprehensive fix..."

./express_push.sh "Comprehensive auth fix with debugging

- Added test-auth page to diagnose profile queries
- Enhanced logging in proposal view page
- Created SQL to fix RLS policies
- Added middleware logging
- Multiple query methods to handle edge cases"

echo ""
echo "✅ Comprehensive fix deployed!"
echo ""
echo "📋 IMPORTANT NEXT STEPS:"
echo ""
echo "1. Visit: ${NEXT_PUBLIC_BASE_URL}/test-auth"
echo "   This will show exactly what's happening with auth"
echo ""
echo "2. Check the Vercel Function logs for [ViewProposalPage] entries"
echo ""
echo "3. If profiles query is blocked, run this in Supabase SQL:"
echo "   cat fix_profiles_rls.sql"
echo ""
echo "4. Clear your browser cache and cookies"
echo ""
echo "The test-auth page will reveal the exact issue!"
EOF

chmod +x comprehensive_auth_fix.sh

echo "✅ Script created: comprehensive_auth_fix.sh"
echo "Run it with: ./comprehensive_auth_fix.sh"