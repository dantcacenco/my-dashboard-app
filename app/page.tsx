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

  // If no profile, assume admin for now (you're the only user)
  if (!profile) {
    redirect('/dashboard')
  }
  
  // Route based on role - handle both 'boss' and 'admin'
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
          <p className="text-sm text-gray-500">User ID: {user.id}</p>
          <p className="text-sm text-gray-500">Please contact support if you need assistance.</p>
        </div>
      </div>
    )
  }
}
