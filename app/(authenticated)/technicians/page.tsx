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
