import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function JobsPage() {
  const supabase = await createClient()
  
  const { data: { user }, error } = await supabase.auth.getUser()
  
  if (error || !user) {
    redirect('/sign-in')
  }

  // Get user profile - CORRECT TABLE
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin' && profile?.role !== 'boss' && profile?.role !== 'tech') {
    redirect('/')
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Jobs</h1>
      <p className="text-gray-600">Job management coming soon...</p>
    </div>
  )
}
