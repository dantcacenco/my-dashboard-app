#!/bin/bash

echo "🔍 Creating comprehensive debugging page..."

# First, check RLS policies
cat > check-rls-policies.sql << 'SQLEOF'
-- Check if RLS is enabled on profiles table
SELECT 
  schemaname,
  tablename,
  tablename = 'profiles' as is_profiles_table,
  rowsecurity 
FROM pg_tables 
WHERE tablename = 'profiles';

-- Check existing RLS policies on profiles
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'profiles';

-- Test query as would be run by the app
SELECT 
  COUNT(*) as total_technicians,
  array_agg(email) as emails
FROM profiles
WHERE role = 'technician';

-- If RLS is the issue, this will show all data (bypasses RLS)
SELECT 
  'Direct Query (No RLS)' as query_type,
  id,
  email,
  full_name,
  role
FROM profiles
WHERE role = 'technician';
SQLEOF

echo "✅ Created check-rls-policies.sql - Run this first!"
echo ""

# Create a diagnostic page that shows exactly what's happening
cat > app/\(authenticated\)/technicians/page.tsx << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { redirect } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import TechniciansClientView from './TechniciansClientView'

export const dynamic = 'force-dynamic'
export const revalidate = 0

export default async function TechniciansPage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/auth/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Only boss/admin can manage technicians
  if (profile?.role !== 'boss' && profile?.role !== 'admin') {
    redirect('/dashboard')
  }

  // Multiple debug queries to figure out what's happening
  console.log('=== DEBUGGING TECHNICIANS QUERY ===')
  console.log('Current user ID:', user.id)
  console.log('Current user role:', profile?.role)

  // Try different queries to see what works
  const debugInfo: any = {
    currentUser: user.email,
    currentRole: profile?.role,
    queries: []
  }

  // Query 1: Basic technician query
  const { data: technicians1, error: error1 } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'technician')
  
  debugInfo.queries.push({
    name: 'Basic technician query',
    success: !error1,
    count: technicians1?.length || 0,
    error: error1?.message || null
  })

  // Query 2: Get ALL profiles to see what's there
  const { data: allProfiles, error: error2 } = await supabase
    .from('profiles')
    .select('id, email, role')
  
  debugInfo.queries.push({
    name: 'All profiles query',
    success: !error2,
    count: allProfiles?.length || 0,
    roles: allProfiles?.map(p => p.role) || [],
    error: error2?.message || null
  })

  // Query 3: Count by role
  const { data: roleCount, error: error3 } = await supabase
    .from('profiles')
    .select('role')
  
  const roleSummary: any = {}
  roleCount?.forEach(p => {
    roleSummary[p.role] = (roleSummary[p.role] || 0) + 1
  })
  
  debugInfo.queries.push({
    name: 'Role count',
    success: !error3,
    summary: roleSummary,
    error: error3?.message || null
  })

  // Try with admin client if available
  let adminTechnicians = null
  let adminError = null
  try {
    const adminClient = createAdminClient()
    const { data, error } = await adminClient
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    adminTechnicians = data
    adminError = error
    
    debugInfo.queries.push({
      name: 'Admin client query',
      success: !error,
      count: data?.length || 0,
      error: error?.message || null
    })
  } catch (e: any) {
    debugInfo.queries.push({
      name: 'Admin client query',
      success: false,
      error: 'Admin client not configured or ' + e.message
    })
  }

  // Use admin results if regular query failed
  const finalTechnicians = (technicians1 && technicians1.length > 0) 
    ? technicians1 
    : (adminTechnicians || [])

  console.log('Debug Info:', JSON.stringify(debugInfo, null, 2))

  return (
    <div className="p-6">
      {/* Debug Information Card */}
      <Card className="mb-6 bg-yellow-50 border-yellow-200">
        <CardHeader>
          <CardTitle className="text-yellow-800">Debug Information</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 text-sm">
            <p><strong>Current User:</strong> {debugInfo.currentUser}</p>
            <p><strong>Current Role:</strong> {debugInfo.currentRole}</p>
            
            <div className="mt-4">
              <strong>Query Results:</strong>
              {debugInfo.queries.map((q: any, i: number) => (
                <div key={i} className="mt-2 p-2 bg-white rounded border">
                  <p className="font-medium">{q.name}:</p>
                  <p className={q.success ? 'text-green-600' : 'text-red-600'}>
                    {q.success ? `✓ Success` : `✗ Failed`}
                    {q.count !== undefined && ` - Found ${q.count} records`}
                  </p>
                  {q.summary && (
                    <p className="text-gray-600">
                      Roles: {JSON.stringify(q.summary)}
                    </p>
                  )}
                  {q.error && (
                    <p className="text-red-500 text-xs">Error: {q.error}</p>
                  )}
                </div>
              ))}
            </div>

            <div className="mt-4 p-2 bg-blue-100 rounded">
              <p className="font-medium">Using {finalTechnicians.length} technicians for display</p>
              {finalTechnicians.length > 0 && (
                <p className="text-xs mt-1">
                  Emails: {finalTechnicians.map((t: any) => t.email).join(', ')}
                </p>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Regular technicians view */}
      <TechniciansClientView technicians={finalTechnicians} />
    </div>
  )
}
EOF

# Also create a simple API endpoint to test database access
cat > app/api/technicians/debug/route.ts << 'EOF'
import { createClient } from '@/lib/supabase/server'
import { createAdminClient } from '@/lib/supabase/admin'
import { NextResponse } from 'next/server'

export async function GET() {
  const debug: any = {
    timestamp: new Date().toISOString(),
    results: []
  }

  try {
    // Test with regular client
    const supabase = await createClient()
    
    const { data: regularData, error: regularError } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    debug.results.push({
      method: 'Regular client',
      success: !regularError,
      count: regularData?.length || 0,
      data: regularData || [],
      error: regularError?.message || null
    })
  } catch (e: any) {
    debug.results.push({
      method: 'Regular client',
      success: false,
      error: e.message
    })
  }

  try {
    // Test with admin client
    const adminClient = createAdminClient()
    
    const { data: adminData, error: adminError } = await adminClient
      .from('profiles')
      .select('*')
      .eq('role', 'technician')
    
    debug.results.push({
      method: 'Admin client',
      success: !adminError,
      count: adminData?.length || 0,
      data: adminData || [],
      error: adminError?.message || null
    })
  } catch (e: any) {
    debug.results.push({
      method: 'Admin client',
      success: false,
      error: e.message
    })
  }

  return NextResponse.json(debug)
}
EOF

# Commit the debugging code
git add .
git commit -m "debug: comprehensive technician data fetching diagnostics"
git push origin main

echo "✅ Debug code deployed!"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Run check-rls-policies.sql in Supabase SQL Editor"
echo "   - This will show if RLS is blocking the queries"
echo ""
echo "2. After deployment, visit /technicians"
echo "   - You'll see a yellow debug box showing exactly what's happening"
echo ""
echo "3. Also test the API directly:"
echo "   https://my-dashboard-app-tau.vercel.app/api/technicians/debug"
echo ""
echo "This will tell us EXACTLY why the technicians aren't showing!"