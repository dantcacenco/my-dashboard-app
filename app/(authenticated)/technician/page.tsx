import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function TechnicianPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/signin')
  }

  // Check user role
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  // If admin, redirect to dashboard
  if (profile?.role === 'admin') {
    redirect('/dashboard')
  }

  // If not a technician, redirect to home
  if (profile?.role !== 'technician') {
    redirect('/')
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Technician Dashboard</h1>
      <p className="text-gray-600">Welcome, technician! Your assignments will appear here.</p>
    </div>
  )
}
