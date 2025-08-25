import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function HomePage() {
  const supabase = await createClient()
  
  const { data: { user } } = await supabase.auth.getUser()
  
  if (!user) {
    redirect('/auth/signin')
  }

  // Get user profile to determine where to redirect
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // Redirect based on role
  if (profile?.role === 'admin') {
    redirect('/dashboard')
  } else if (profile?.role === 'technician') {
    redirect('/technician/jobs')
  } else {
    // Default to dashboard for users without a role
    redirect('/dashboard')
  }
}
