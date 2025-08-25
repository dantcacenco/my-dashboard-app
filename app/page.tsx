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

  // Redirect based on role
  if (profile?.role === 'admin') {
    redirect('/dashboard')
  } else if (profile?.role === 'technician') {
    redirect('/technician')
  } else {
    // Default page for users without a role
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Welcome to Service Pro</h1>
          <p className="text-gray-600">Your account is being set up. Please contact support if you need assistance.</p>
        </div>
      </div>
    )
  }
}
