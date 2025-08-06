import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function DebugPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Try both table names to see which one exists
  const { data: profile1 } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('user_id', user.id)
    .single()

  const { data: profile2 } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Debug Information</h1>
      
      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-bold mb-2">User Auth:</h2>
        <pre className="text-sm">{JSON.stringify({ id: user.id, email: user.email }, null, 2)}</pre>
      </div>

      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-bold mb-2">User Profile (user_profiles table):</h2>
        <pre className="text-sm">{JSON.stringify(profile1, null, 2)}</pre>
      </div>

      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-bold mb-2">User Profile (profiles table):</h2>
        <pre className="text-sm">{JSON.stringify(profile2, null, 2)}</pre>
      </div>

      <div className="mt-4">
        <a href="/proposals" className="text-blue-600 hover:underline">Back to Proposals</a>
      </div>
    </div>
  )
}
