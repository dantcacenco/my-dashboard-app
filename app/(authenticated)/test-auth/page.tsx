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
          <p>Is Admin: {profile1?.role === 'boss' ? 'YES' : 'NO'}</p>
          <p>Is Boss: {profile1?.role === 'boss' ? 'YES' : 'NO'}</p>
          <p>Should have access: {(profile1?.role === 'boss') ? 'YES' : 'NO'}</p>
        </div>
      </div>
      
      <div className="mt-8 space-x-4">
        <a href="/proposals" className="text-blue-600 hover:underline">Go to Proposals</a>
        <a href="/" className="text-blue-600 hover:underline">Go to Dashboard</a>
      </div>
    </div>
  )
}
